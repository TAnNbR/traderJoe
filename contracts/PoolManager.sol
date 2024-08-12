// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./interfaces/IPool.sol";
import "./lib/FixedPoint96.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "hardhat/console.sol";

// 注意allowance的检查是发生在ui中

contract PoolManager{
    
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

    function swap(
        address pool_address,
        uint256 expectedAmount, // X96
        uint256 limitPrice,     // X96
        bool    zeroforone,
        bytes   calldata data
    ) public returns(uint256,uint256){
        return IPool(pool_address).swap(
            expectedAmount,
            limitPrice,
            zeroforone,
            data
        );
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

        IPool.CallBackData memory extraData= abi.decode(
            data,
            (IPool.CallBackData)
        );
        
        // 注意保持ERC1155中的amount精度一致
        if(zeroforone){
            // 流出 x
            IERC1155(extraData.token0).safeBatchTransferFrom(
                msg.sender,
                extraData.payer,
                bins,
                amount0,
                data
            );
            IERC1155(extraData.token1).safeBatchTransferFrom(
                extraData.payer,
                msg.sender,
                bins,
                amount1,
                data
            );
        }else{
            // 流出 y
            IERC1155(extraData.token0).safeBatchTransferFrom(
                extraData.payer,
                msg.sender,
                bins,
                amount0,
                data
            );
            IERC1155(extraData.token1).safeBatchTransferFrom(
                msg.sender,
                extraData.payer,
                bins,
                amount1,
                data
            ); 
        }

    }

}