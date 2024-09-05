// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./lib/Bins.sol";
import "./lib/Position.sol";
import "./lib/IndexTree.sol";
import "./lib/FixedPoint96.sol";
import "./lib/BinMath.sol";
import "./lib/Math.sol";
import "./lib/SwapMath.sol";

import "./interfaces/IPoolMintCallback.sol";
import "./interfaces/IPoolSwapCallback.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IFlashCallback.sol";
import "./interfaces/IDeployer.sol";

import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "hardhat/console.sol";

contract Pool is IPool,ERC1155Holder {
    event Swap(
        uint256 amount0,
        uint256 amount1
    );

    error InvalidLimitPrice();
    error LiquidityNotEnough();
    error Invalidbinposition();
    error ZeroLiquidity();
    error FlashToken0BalanceNotEnough(uint256 id);
    error FlashToken1BalanceNotEnough(uint256 id);

    using Bins for mapping(uint32=>Bins.Info) ;
    using Position for mapping(bytes32=>Position.Info);
    using Position for Position.Info;
    using IndexTree for IndexTree.BigTree;

    struct SwapState{
        uint32  bin;
        uint256 pi;
        uint128 active_liquidity;
        uint256 amountBeenOut;
        uint256 amountBeenIn;
    }

    struct Stepstate{
        uint256 startPrice;
        uint32  nextBin;
        uint256 nextPrice;
        bool    forSure;
        uint256 amountIn;
        uint256 amountOut;
    }

    /**
     * @notice mint不会改变slot，swap可能会改变slot
     * @param pi 实时价格
     * @param bin 实时区间
     */
    struct Slot {
        uint256 pi;
        uint32  bin;
    }

    // bins上下界 [ -2^19 + 2^23 , 2^19 + 2^23 ]
    uint32 internal constant MAX_BIN=9275880;
    uint32 internal constant MIN_BIN=7501336;

    uint256 internal constant MIN_PRICE = 4295128739;
    uint256 internal constant MAX_PRICE = 1461446703485210103287273052203988822378723970342;
    
    address public immutable factory;
    address public immutable token0;
    address public immutable token1;
    uint256 public immutable tickSpacing;

    mapping (uint32=>Bins.Info) bins;
    mapping (bytes32=>Position.Info) positions;
    IndexTree.BigTree indextree;
    
    /**
     * @param liquidity   活跃流动性，数量级是uint128，L的数量级不需要很大，因为现实中不会有太大数量级的流动性
     * @param composition 当前容量，初始值为`0`
     */
    uint128 public liquidity;
    uint160 public composition;
    
    Slot public slot;

    // 辅助批量转账数组
    uint256[] tempIds;
    uint256[] tempAmountsOfToken0;
    uint256[] tempAmountsOfToken1;

    constructor(){  
        (factory,token0,token1,tickSpacing) = IDeployer(msg.sender).parameter();
    }

    function initialize(
        uint256 _price,
        uint32  _bin
    ) public{
        slot = Slot({
            pi  : _price,
            bin : _bin
        });
    }

    function mint(
        address owner,
        uint32  target_bin,
        uint128 amount,
        bytes   calldata data
    )external returns (
        uint256 amount0,
        uint256 amount1
    ){

        // 检查参数
        if(target_bin>MAX_BIN || target_bin<MIN_BIN) revert Invalidbinposition();
        if(amount == 0) revert ZeroLiquidity();   
        
        // 注意更新bins要在获取composition之后
        uint160 _composition;
        uint32  current_bin = slot.bin;
        
        // 根据目标区间位置计算数量
        uint256 target_price = BinMath.getPriceAtBin(target_bin);
        if(target_bin == current_bin){

            if(bins[target_bin].initialized){
                _composition = composition;
            }else{
                // 如果这个池子未被初始化，那么 _c = 0.5
                _composition = uint160(1<<(FixedPoint96.RESOLUTION-1));

                // 初始化池子的 c = 0.5
                composition = _composition;
            }

            amount0 = Math.calcAmount0Active(
                amount,
                _composition, // X96
                target_price  // X96
            );
            amount1 = Math.calcAmount1Active(
                amount,
                _composition  // X96
            );

            // 增加活跃流动性
            liquidity += amount;

        }else if(target_bin > current_bin){
            _composition = 0;
            amount0 = Math.calcAmount0Inactive(
                amount,
                target_price // X96
            );
            
        }else{
            _composition = uint160(1<<FixedPoint96.RESOLUTION); 
            amount1 = Math.calcAmount1Inactive(
                amount
            );
        }// end if

        // 修改bins
        bool flippedbin=bins.update(target_bin,amount);

        // 修改indextree
        if(flippedbin) indextree.flipBin(target_bin);

        // 修改position
        Position.Info storage pos = positions.get(owner,target_bin);
        pos.update(amount);
        
        // 执行转账
        IPoolMintCallback(msg.sender).PoolMintCallback(
            target_bin,
            amount0,
            amount1,
            data
        );

    }

    function swap(
        uint256 expectedAmount, // X96
        uint256 limitPrice,     // X96
        bool    zeroforone,
        bytes   calldata data
    ) external returns( 
        uint256 amount0,        // X96
        uint256 amount1         // X96
    ){ 
        // 清空辅助数组
        delete tempIds;
        delete tempAmountsOfToken0;
        delete tempAmountsOfToken1;
        
        // 记录状态变量，节约gas
        Slot memory _slot  = slot;
        uint128 _liquidity = liquidity;
        
        // 检验输入的限价是否有效
        bool validLimitPrice = zeroforone ? (limitPrice > _slot.pi && limitPrice <= MAX_PRICE) : (limitPrice < _slot.pi && limitPrice >= MIN_PRICE);                                     
        if(!validLimitPrice) revert InvalidLimitPrice();
        
        // 初始化state
        SwapState memory state=SwapState({
            bin: _slot.bin,
            pi: _slot.pi,
            active_liquidity:_liquidity,
            amountBeenOut: 0,
            amountBeenIn: 0
        });

        //====================================  one step  =======================================//
        while (expectedAmount>0 && ( zeroforone ?  state.pi<=limitPrice : state.pi>=limitPrice )) {
            console.log("bin =",state.bin);
            
            // 初始化step
            Stepstate memory step;
            step.startPrice = state.pi;

            // 仅用于获取下一个有流动性的bin的指针
            uint32  binPoint   = state.bin;
            uint256 pricePoint = state.pi;
            
            // 获取下一个有流动性的bin
            if(zeroforone){
                // 流出x
                uint32 _nextBin = indextree.FindBigBin(binPoint);
                    
                // 存在下一个有流动性的bin
                if(_nextBin != type(uint32).max){
                    uint256 nextPricePoint = BinMath.getPriceAtBin(_nextBin);
                    // 下个bin的价格在范围之内时，更新指针
                    if(nextPricePoint <= limitPrice){
                        binPoint   = _nextBin;
                        pricePoint = nextPricePoint;
                    }
                }
            }else{
                // 流出y
                uint32 _nextBin = indextree.FindSmallBin(binPoint);

                // 存在下一个有流动性的bin
                if(_nextBin != type(uint32).max){
                    uint256 nextPricePoint = BinMath.getPriceAtBin(_nextBin);
                    // 下个bin的价格在范围之内时，更新指针
                    if(nextPricePoint >= limitPrice){
                        binPoint   = _nextBin;
                        pricePoint = nextPricePoint;
                    }
                }
            }
            

            /**
             * @dev 上一步中没有直接获取 nextPricePoint 的原因：
             * 1. getPriceAtBin() 如果传入 type(uint32).max 会 revert
             * 2. 同时为了接下来更新 step 的逻辑更加清晰
             */


            // 更新 step：下个bin、下个price
            if(binPoint != state.bin){
                // 存在下一个有流动性的bin
                step.nextBin   = binPoint;
                step.nextPrice = pricePoint;
            }else{
                // 不存在
                step.nextBin   = type(uint32).max;
                step.nextPrice = type(uint256).max;
            }
            
            // 执行 SwapMath
            uint256 _nextPrice;
            ( 
                _nextPrice,
                composition, 
                step.amountIn, 
                step.amountOut 
            ) = SwapMath.computeSwap(
                step.startPrice,        // X96
                state.active_liquidity,
                composition,            // X96
                step.nextPrice,         // X96
                zeroforone,
                expectedAmount          // X96
            );
            
            // 更新已转入转出数量
            expectedAmount      -= step.amountOut;
            state.amountBeenOut += step.amountOut;
            state.amountBeenIn  += step.amountIn;
            
            // 记录批量转账信息
            tempIds.push(uint256(state.bin));
            uint256 nowAmount0;
            uint256 nowAmount1;
            (nowAmount0,nowAmount1) = zeroforone ? ( step.amountOut , step.amountIn ) : ( step.amountIn  , step.amountOut );
            tempAmountsOfToken0.push(nowAmount0);
            tempAmountsOfToken1.push(nowAmount1);
            
            // 没有下一个可用的 bin ，部分成交
            if(step.nextBin == type(uint32).max){
                console.log("Done Partly: no more bin");
                break;
            }

            // 越过限价，部分成交
            if( zeroforone ? step.nextPrice>limitPrice : step.nextPrice<limitPrice ){
                console.log("Done Partly: out of limitprice");
                break;
            }
            
            // 数量已满足，成交
            if(expectedAmount==0){
                console.log("Done: full of expected amount");
                break;
            }

            // 更新 state
            state.bin = step.nextBin;
            state.pi  = _nextPrice;
            state.active_liquidity = bins[state.bin].liquidity;

        }
        //====================================  step end  =======================================//


        // 初始化转账数组
        uint256[] memory ids = new uint256[](tempIds.length);
        uint256[] memory amountsOfToken0 = new uint256[](tempIds.length);
        uint256[] memory amountsOfToken1 = new uint256[](tempIds.length);

        // 将辅助数组信息复制进转账数组内
        for(uint i = 0; i < tempIds.length; i++){
            console.log("tempIds[i] | tempAmountsOfToken0[i] | tempAmountsOfToken1[i] = ",tempIds[i],tempAmountsOfToken0[i],tempAmountsOfToken1[i]); // debug
            ids[i] = tempIds[i];
            amountsOfToken0[i] = tempAmountsOfToken0[i];
            amountsOfToken1[i] = tempAmountsOfToken1[i];
        }

        // 更新合约状态
        liquidity = state.active_liquidity;    
        slot.bin  = state.bin;
        slot.pi   = state.pi;

        // 执行转账
        CallBackData memory extraData = abi.decode(data,(IPool.CallBackData));
        IERC1155(extraData.token0).setApprovalForAll(msg.sender,true);
        IERC1155(extraData.token1).setApprovalForAll(msg.sender,true);
        IPoolSwapCallback(msg.sender).PoolSwapCallback(
            ids,
            amountsOfToken0,
            amountsOfToken1,
            data,
            zeroforone
        );
        
        // 返回值
        (amount0,amount1) = zeroforone ? (state.amountBeenOut,state.amountBeenIn) : (state.amountBeenIn,state.amountBeenOut);

        emit Swap(
            amount0,
            amount1
        );
        
    }
    
    function flash(
        uint256[] memory amount0,
        uint256[] memory amount1,
        uint256[] memory ids
    ) public{
        require( amount0.length == amount1.length ,"amount length mismatch!");
        require( amount0.length == ids.length ,"amount and ids length mismatch!");

        uint256 id;
        uint256[] memory balance0 = new uint256[](ids.length);
        uint256[] memory balance1 = new uint256[](ids.length);
        for( uint256 i=0 ; i<ids.length ; i++ ){
            id = ids[i]; 
            balance0[i] = IERC1155(token0).balanceOf(address(this),id);
            if( amount0[i] > balance0[i] ) revert FlashToken0BalanceNotEnough(id);
            balance1[i] = IERC1155(token1).balanceOf(address(this),id);
            if( amount1[i] > balance1[i] ) revert FlashToken1BalanceNotEnough(id);
        }
        
        bytes memory data;
        IERC1155(token0).safeBatchTransferFrom(
            address(this),
            msg.sender,
            ids,
            amount0,
            data
        );
        IERC1155(token1).safeBatchTransferFrom(
            address(this),
            msg.sender,
            ids,
            amount1,
            data
        );

        IFlashCallback(msg.sender).flashCallback(
            amount0,
            amount1,
            ids
        );

        for( uint256 i=0 ; i<ids.length ; i++ ){
            id = ids[i]; 
            require(IERC1155(token0).balanceOf(address(this),id) >= balance0[i]);
            require(IERC1155(token1).balanceOf(address(this),id) >= balance1[i]);
        }
    }
}
