// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./JoeSwapPool.sol";
import "./interfaces/IERC1155.sol";

//注意allowance的检查是发生在ui中
//mint操作只是transfer
//Swap跨区间transfer是执行多次transfer吗？
//ERC20是同质化的，只有总量，是不是计算出转移总和，转一次即可？
//ERC1155含有多种（多个bin），是不是要转多次？

contract JoeSwapManager{
    
    //这里为什么要return amount？
    //这里的data只在Manager里用过，为什么要传给Pool？
    //data中的token0和token1在Pool里也有，为什么不只传个payer就好了？
    function mint(
        address pool_address,
        int32 target_bin,
        uint128 amount,
        bytes calldata data
    ) public returns(uint256 amount0,uint256 amount1){
        return JoeSwapPool(pool_address).mint(
            msg.sender,
            target_bin,
            amount,    
            data
        );
    }

    function swap(
        address pool_address,
        uint256 expectedAmount, // X96
        uint256 limitPrice, // X96
        bool zeroforone,
        bytes calldata data
    ) public returns(uint256 amount0,uint256 amount1){
        return JoeSwapPool(pool_address).swap(
            expectedAmount, // X96
            limitPrice, // X96
            zeroforone,    
            data
        );
    }

    function JoeSwapMintCallback(
        int32 target_bin,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
        //!加个return测试一下
    ) public {
        //有没有可能是data出了问题!
        //data解码没问题
        //地址是不区分大小写的
        JoeSwapPool.CallBackData memory extra= abi.decode(
            data,
            (JoeSwapPool.CallBackData)
        );

        amount0=amount0>>FixedPoint96.RESOLUTION;
        amount1=amount1>>FixedPoint96.RESOLUTION;

        //amount没问题
        //要么是extra.payer的问题 没问题
        //要么是target_bin的问题 没问题
        //!又是X96的问题 在ERC1155中_mint时没用X96导致余额不够
        IERC1155(extra.token0).safeTransferFrom(
            extra.payer,
            msg.sender,
            uint256(int256(target_bin)),
            amount0,
            data
        );
        IERC1155(extra.token1).safeTransferFrom(
            extra.payer,
            msg.sender,
            uint256(int256(target_bin)),
            amount1,
            data
        );
    }

    function JoeSwapCallBack(
        uint256[] memory ids,
        uint256[] memory amountsOfToken0,
        uint256[] memory amountsOfToken1,
        bytes memory data,
        bool zeroForOne
    ) public {
        JoeSwapPool.CallBackData memory extra= abi.decode(
            data,
            (JoeSwapPool.CallBackData)
        );
        
        // 流出 y 或 流出 x
        if(zeroForOne){
            // x : payer => pool
            IERC1155(extra.token0).safeBatchTransferFrom(
                extra.payer,
                msg.sender,
                ids,
                amountsOfToken0,
                data
            );
            // y : pool => payer
            IERC1155(extra.token1).safeBatchTransferFrom(
                msg.sender,
                extra.payer,
                ids,
                amountsOfToken1,
                data
            );
        }else{
            // x : pool => payer
            IERC1155(extra.token0).safeBatchTransferFrom(
                msg.sender,
                extra.payer,
                ids,
                amountsOfToken0,
                data
            );
            // y : payer => pool
            IERC1155(extra.token1).safeBatchTransferFrom(
                extra.payer,
                msg.sender,
                ids,
                amountsOfToken1,
                data
            );
        }

    }


}