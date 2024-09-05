// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./interfaces/IPool.sol";
import "./interfaces/IPoolManager.sol";

import "./lib/FixedPoint96.sol";
import "./lib/Path.sol";
import "./lib/PoolAddress.sol";
import "./Pool.sol";

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "hardhat/console.sol";

// 注意allowance的检查是发生在ui中

contract PoolManager is IPoolManager{
    using Path for bytes;

    address public immutable factory;

    constructor(address _factory){
        factory = _factory;
    }
    
    function mint(
        address pool_address,
        uint32  target_bin,
        uint128 amount,
        bytes   calldata data
    ) public returns(uint256,uint256){
        return IPool(pool_address).mint(
            msg.sender,
            target_bin,
            amount,    
            data
        );
    }

    function swapMultiple(SwapMultipleParameters memory data) public returns(uint256,uint256){
        bytes memory _path = data.path;
        // 一个代币对
        while(){
            
        }

    }

    function _swap(
        uint256 expectedAmount, // X96
        uint256 limitPrice,     // X96
        bool    zeroforone,
        SwapCallBackParams memory data
    ) internal returns(uint256 amountOut){
        SwapCallBackParams memory _data = abi.decode(data,SwapCallBackParams);
        (address token0,address token1,uint256 tickSpacing) = _data.path.decodeFirstPool();
        address pool = PoolAddress.computePoolAddress(
            factory, 
            token0, 
            token1, 
            tickSpacing
        );
        limitPrice = limitPrice==0 ? (zeroforone ? Pool.MAX_PRICE-1 : Pool.MIN_PRICE+1) :limitPrice;
        (uint256 amount0,uint256 amount1) = IPool(pool).swap(
            expectedAmount, 
            limitPrice, 
            zeroforone, 
            data
        );
        amountOut = zeroforone ? amount0 : amount1;
    }
    
    function PoolMintCallback(
        uint32 target_bin,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {

        IPool.CallBackData memory extraData= abi.decode(
            data,
            (IPool.CallBackData)
        );
        
        IERC1155(extraData.token0).safeTransferFrom(
            extraData.payer,
            msg.sender,
            target_bin,
            amount0,
            data
        );
        IERC1155(extraData.token1).safeTransferFrom(
            extraData.payer,
            msg.sender,
            target_bin,
            amount1,
            data
        );

    }

    function PoolSwapCallback(
        uint256[] memory bins,
        uint256[] memory amount0,
        uint256[] memory amount1,
        bytes calldata data,
        bool  zeroforone
    ) public {

        SwapCallBackParams memory extraData= abi.decode(data,SwapCallBackParams);
        (address token0,address token1,) = extraData.path.decodeFirstPool();
        
        // 注意保持ERC1155中的amount精度一致
        if(zeroforone){
            // 流出 x
            IERC1155(token0).safeBatchTransferFrom(
                msg.sender,
                extraData.recepient,
                bins,
                amount0,
                data
            );
            IERC1155(token1).safeBatchTransferFrom(
                extraData.recepient,
                msg.sender,
                bins,
                amount1,
                data
            );
        }else{
            // 流出 y
            IERC1155(token0).safeBatchTransferFrom(
                extraData.recepient,
                msg.sender,
                bins,
                amount0,
                data
            );
            IERC1155(token1).safeBatchTransferFrom(
                msg.sender,
                extraData.recepient,
                bins,
                amount1,
                data
            ); 
        }

    }

}