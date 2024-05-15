// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./lib/Bins.sol";
import "./lib/Position.sol";
import "./lib/Indextree.sol";
import "./lib/FixedPoint96.sol";
import "./lib/TickMath.sol";
import "./lib/Math.sol";
import "./lib/SwapMath.sol";

import "./interfaces/IJoeSwapMintCallback.sol";
import "./interfaces/IERC1155Receiver.sol";

import "hardhat/console.sol";

contract JoeSwapPool {
    error LiquidityNotEnough();

    using Bins for mapping(int32=>Bins.Info) ;
    using Position for mapping(bytes32=>Position.Info);
    using Position for Position.Info;
    using Indextree for mapping (int32 => uint256);

    error Invalidbinposition();
    error ZeroLiquidity();

    // bins上下界 = tick + 2^23
    int32 internal constant MAX_BIN=9275880;
    int32 internal constant MIN_BIN=7501336;

    uint256 internal constant MIN_PRICE = 4295128739;
    uint256 internal constant MAX_PRICE = 1461446703485210103287273052203988822378723970342;

    // 资产对的地址
    address public immutable token0;
    address public immutable token1;

    /**
     * @notice mint不会改变slot，swap有可能会改变slot
     * @param pi 实时价格
     * @param bin 实时区间
     */
    struct Slot {
        uint256 pi;
        int32 bin;
    }
    Slot public slot;

    struct CallBackData{
        address token0;
        address token1;
        address payer;
    }

    struct SwapState{
        int32 bin;
        uint256 pi;
        uint128 active_liquidity;
        uint256 amountBeenOut;
        uint256 amountBeenIn;
    }

    struct Stepstate{
        uint256 startPrice;
        int32 nextBin;
        uint256 nextPrice;
        bool forSure;
        uint256 amountIn;
        uint256 amountOut;
    }

    // 每个bin有多少L
    mapping (int32=>Bins.Info) bins;

    // 每个LP在每个bin有多少L
    mapping (bytes32=>Position.Info) positions;

    mapping (int32 => uint256) indextree;

    // 活跃流动性
    // L是uint128，L不用很大，因为不会有人花那么多钱
    uint128 public liquidity;

    uint160 public composition;

    /**
     * @notice 初始化
     * @param token0_ 资产对地址
     * @param token1_ 资产对地址
     * @param _pi 实时价格
     * @param _bin 实时区间
     */
    constructor(
        address token0_,
        address token1_,
        uint256 _pi,
        int32 _bin
    ){  
        token0=token0_; 
        token1=token1_;
        slot=Slot({pi:_pi,bin:_bin});
    }

    function mint(
        address owner,
        int32 target_bin,
        uint128 amount,
        bytes calldata data
    )external returns (uint256 amount0,uint256 amount1){

        // 检查参数
        if(target_bin>MAX_BIN || target_bin<MIN_BIN) revert Invalidbinposition();
        if(amount == 0) revert ZeroLiquidity();

        /**
         * 
         * 获取c的逻辑：
         * 是否是current_bin?{ 
         *  是：{
         *    是否初始化？{
         *        是：c=bins[target_bin].c;
         *        否：c=0.5;(引入浮点数)
         *    }
         *  }
         *  否：{
         *    大于还是小于？=>各自赋值
         *  }
         * }
         * 
         */      
        
        // 注意更新bins要在获取composition之后
        uint160 _composition;
        int32 current_bin = slot.bin;

        // 这里传参的精度存在问题，传入的target_bin是Nb，没换算，应当传入(target_bin-2^23)
        uint256 target_price=TickMath.getSqrtRatioAtTick(
            int24(target_bin-(1<<23)) // BIN - ( 2 ^ 23 )
        );
        if(target_bin == current_bin){

            if(bins[target_bin].initialized){
                _composition=composition;
            }else{
                // 如果这个池子未被初始化，那么 _c = 0.5
                _composition=uint160(1<<(FixedPoint96.RESOLUTION-1));

                // 初始化池子的 c = 0.5
                composition=_composition;
            }
            amount0=Math.calcAmount0CurrentDeltaMint(
              amount,
              _composition, // X96
              target_price // X96
            );
            amount1=Math.calcAmount1CurrentDelta(
              amount,
              _composition // X96
            );

            // 增加活跃流动性
            liquidity+=amount;
        }else if(target_bin > current_bin){
            _composition=0;
            amount0=Math.calcAmount0Inactive(
                amount,
                target_price // X96
            );
        }else{
            _composition=uint160(1<<FixedPoint96.RESOLUTION); 
            amount1=Math.calcAmount1Inactive(amount);
        }

        // 修改bins
        bool flippedbin=bins.update(target_bin,amount);
        
        // 修改indextree
        if(flippedbin) indextree.flipBin(target_bin,1);

        // 修改position
        Position.Info storage pos=positions.get(owner,target_bin);
        pos.update(amount);
        
        // 执行转账
        IJoeSwapMintCallback(msg.sender).JoeSwapMintCallback(
            target_bin,
            amount0,
            amount1,
            data
        );

    }
    
    function swap(
        address recipient,
        uint256 expectedAmount, // X96
        uint256 limitPrice, // X96
        bool zeroforone,
        bytes calldata data
    ) external returns( 
        uint256 amount0,
        uint256 amount1
    ){
        Slot memory _slot=slot;
        uint128 _liquidity=liquidity;

        bool validLimitPrice = zeroforone ? (limitPrice < _slot.pi && limitPrice >= MIN_PRICE)
                                            : (limitPrice > _slot.pi && limitPrice <= MAX_PRICE);                                     
        
        require(validLimitPrice,"Invalid LimitPrice!");

        SwapState memory state=SwapState({
            bin: _slot.bin,
            pi: _slot.pi,
            active_liquidity:_liquidity,
            amountBeenOut: 0,
            amountBeenIn: 0
        });
        
        /////////////////
        //    while    //
        /////////////////
        while (expectedAmount>0 && ( zeroforone ? state.pi>=limitPrice : state.pi<=limitPrice )) {
            console.log(); // debug
            console.log("           [DEBUG]: ************* round ***********"); // debug

            bool theEdgeBin = bins[state.bin].initialized;
            if(!theEdgeBin){
                break;
            }

            Stepstate memory step;
            step.startPrice=state.pi;

            uint256 pricePoint=step.startPrice;
            int32 binPoint=state.bin;
 
            // 寻找下一个Initialized的bin
            int32 _nextBin;
            bool _forSure;
            
            if(zeroforone){
            /////////////////////////
            //    while : 流出 y   //
            ////////////////////////
                while (pricePoint>=limitPrice) {
                    console.log("           [DEBUG]: ******** search execute *******"); // debug
                    console.log("           [DEBUG]:",uint256(int256(binPoint))); // debug
                    console.log("           [DEBUG]:",pricePoint); // debug

                    (_nextBin,_forSure)=indextree.nextInitializedBinWithinOneWord(binPoint,1,zeroforone);
                    uint256 nextPricePoint=TickMath.getSqrtRatioAtTick(int24(_nextBin-(1<<23)));
                    
                    console.log("           [DEBUG]: nextBin = ",uint256(int256(_nextBin))); // debug
                    console.log("           [DEBUG]: nextPricePoint = ",nextPricePoint); // debug

                    // require(_nextBin==8397125,"!=8397125"); 

                    // 分两种情况、三种位置讨论
                    if(_forSure){
                        if(nextPricePoint<limitPrice){
                            console.log("           [DEBUG]: Sure: pricePoint<limitPrice"); // debug
                            break;
                        }else if(nextPricePoint==limitPrice){
                            console.log("           [DEBUG]: Sure: pricePoint==limitPrice"); // debug
                            binPoint=_nextBin;
                            pricePoint=nextPricePoint;
                            break;
                        }else{
                            binPoint=_nextBin;
                            pricePoint=nextPricePoint;
                        }
                    }else {
                        if(nextPricePoint>=limitPrice){
                            // 来到一个 Not Sure 的 bin : Initialized / Uninitialized
                            binPoint=_nextBin;
                            bool haveLiquidity = bins[binPoint].initialized;
                            if(haveLiquidity){
                                pricePoint=TickMath.getSqrtRatioAtTick(int24(binPoint-(1<<23)));
                                break;

                            }else {
                                binPoint=_nextBin-1;
                                pricePoint=TickMath.getSqrtRatioAtTick(int24(binPoint-(1<<23)));
                            }
                        }else{
                            console.log("           [DEBUG]: Not Sure: pricePoint<limitPrice"); // debug
                            // 这里不能直接 revert 打破整个循环，因为当前 bin 还可以在限价之内部分成交
                            break;
                        }
                    }
                }
            ////////////////////////////
            //    end while : SMALL   //
            ////////////////////////////

            }else{
            /////////////////////////
            //    while : 流出 x   //
            ////////////////////////
                while (pricePoint<=limitPrice) {
                    console.log("           [DEBUG]: ******** search execute *******"); // debug
                    // console.log(uint256 p0); 需要转换成uint256来打印
                    console.log("           [DEBUG]:",uint256(int256(binPoint))); // debug
                    console.log("           [DEBUG]:",pricePoint); // debug

                    (_nextBin,_forSure)=indextree.nextInitializedBinWithinOneWord(binPoint,1,zeroforone);
                    uint256 nextPricePoint=TickMath.getSqrtRatioAtTick(int24(_nextBin-(1<<23)));
                
                    // console.log("           [DEBUG]:",_forSure); // debug
                    // 分两种情况、三种位置讨论
                    if(_forSure){
                        if(nextPricePoint>limitPrice){
                            console.log("           [DEBUG]: Sure: pricePoint>limitPrice"); // debug
                            break;
                        }else if(nextPricePoint==limitPrice){
                            console.log("           [DEBUG]: Sure: pricePoint==limitPrice"); // debug
                            binPoint=_nextBin;
                            pricePoint=nextPricePoint;
                            break;
                        }else{
                            binPoint=_nextBin;
                            pricePoint=nextPricePoint;
                        }
                    }else {
                        if(nextPricePoint<limitPrice){
                            binPoint=_nextBin;
                            pricePoint=nextPricePoint;
                        }else{
                            console.log("           [DEBUG]: Not Sure: pricePoint>=limitPrice"); // debug
                            break;
                        }
                    }

                }
            /////////////////////////////
            //    end while : SMALL    //
            /////////////////////////////
            }

            console.log("           [DEBUG]: ********* out of search ********"); // debug
            // if(!_forSure) revert("nextStep not sure!");

            step.nextBin=binPoint;
            step.nextPrice=pricePoint;
            step.forSure=_forSure;

            


            // (step.nextBin,step.forSure)=indextree.nextInitializedBinWithinOneWord(binPoint,1,zeroforone);

            // 遇到编译器堆栈深度超出时，可以使用结构体传参
            /**
             * SwapMath.ComputeSwapParams memory computeSwapParams = SwapMath.ComputeSwapParams ({
             *    currentPrice: step.startPrice,
             *    activeLquidity: state.active_liquidity,
             *    activeComposition: composition,
             *    nextPrice: step.nextPrice,
             *    zeroForOne: zeroforone,
             *    amountRemain: expectedAmount 
             * });
             * ( state.pi , composition , step.amountIn , step.amountOut ) = SwapMath.computeSwap(computeSwapParams);
             */

           ( 
                state.pi, // 这个返回值其实多余了
                composition, 
                step.amountIn, 
                step.amountOut 
            ) = SwapMath.computeSwap(
                (step.startPrice>>FixedPoint96.RESOLUTION),
                state.active_liquidity,
                composition, // X96
                (step.nextPrice>>FixedPoint96.RESOLUTION),
                zeroforone,
                expectedAmount // X96
            );

            // 是否要更新流动性
            // 因为上面返回的state.pi不是X96，所以需要转化
            // 但是如果直接转换会有精度损失，所以直接用精确的step.price赋值
            if(state.pi == (step.nextPrice>>FixedPoint96.RESOLUTION) ){
                state.pi=step.nextPrice;
                state.bin=step.nextBin;
                state.active_liquidity=bins[state.bin].liquidity;
            }else {
                state.pi=step.startPrice;
            }

            expectedAmount-=step.amountOut;
            state.amountBeenOut+=step.amountOut;
            state.amountBeenIn+=step.amountIn;
            
            console.log(
                "           [DEBUG]: expectedAmount | state.amountBeenOut | state.amountBeenIn ",
                expectedAmount,
                state.amountBeenOut,
                state.amountBeenIn
            ); // debug
            
            console.log(
                "           [DEBUG]: state.pi = ",   
                state.pi,
                "composition = ",
                composition
            ); // debug

        }
        //////////////////////////
        //    end while : BIG   //
        //////////////////////////
        
        console.log(); // debug
        console.log("           [DEBUG]: ********* out of round ********"); // debug
        console.log(
            "           [DEBUG]: state.pi = ",   
            state.pi,
            "composition = ",
            composition
        ); // debug

        liquidity=state.active_liquidity;    
        slot.bin=state.bin;
        slot.pi=state.pi;
        (amount0,amount1) = zeroforone ? (state.amountBeenIn,state.amountBeenOut) : (state.amountBeenOut,state.amountBeenIn);

        console.log(
            "           [DEBUG]: amount0 = ",
            amount0,
            "amount1 = ",
            amount1
        ); // debug

    }
    
    
   
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4){
        bytes4 response = bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
        return response;
    }

    /**
     * @dev 接受ERC1155批量安全转账`safeBatchTransferFrom` 
     *      需要返回 0xbc197c81 或 `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4){
        bytes4 response = bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
        return response;
    }

    ////////////////////
    //    For Test    //
    ////////////////////

     
}
