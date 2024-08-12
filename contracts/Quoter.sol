// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./interfaces/IPool.sol";

contract Quoter{
    function quote(
        address pool,
        uint256 expectedAmount,
        uint256 limitPrice,
        bool    zeroforone,
        bytes calldata data
    ) public returns(
        uint256 amountOut,
        uint256 afterPrice,
        uint256 afterBin
    ){
        try
            IPool(pool).swap(
                expectedAmount,
                limitPrice,
                zeroforone,data
            )
        {} catch(bytes memory reasons){
            (amountOut,afterPrice,afterBin) = abi.decode(reasons,(uint256,uint256,uint256));
        }
    }

    function PoolSwapCallback(
        uint256[] memory,
        uint256[] memory amount0,
        uint256[] memory amount1,
        bytes calldata,
        bool  zeroforone
    ) public{
        uint256 amountOut;
        if(zeroforone){
            for( uint256 i = 0 ; i < amount0.length ; i++ ){
                amountOut += amount0[i];
            }
        }else{
            for( uint256 i = 0 ; i < amount0.length ; i++ ){
                amountOut += amount1[i];
            }
        }
        (uint256 afterPrice,uint32 afterBin) = IPool(msg.sender).slot();
        assembly {
            let str := mload(0x40)
            mstore(str,amountOut)
            mstore(add(str,0x20),afterPrice)
            mstore(add(str,0x40),afterBin)
            revert(str,96)
        }
    }

}