// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./BytesLib.sol";

library Path{
    using BytesLib for bytes;

    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant TS_SIZE = 32;

    uint256 private constant NEXT_OFFSET = ADDR_SIZE + TS_SIZE;
    uint256 private constant POP_SIZE = NEXT_OFFSET + ADDR_SIZE;
    uint256 private constant MULTIPLE_POOL = POP_SIZE + NEXT_OFFSET;

    function hasMultiPool(bytes memory path) internal pure returns(bool){
        return path.length >= MULTIPLE_POOL;
    }

    function poolNum(bytes memory path) internal pure returns(uint256){
        return (path.length - ADDR_SIZE) / NEXT_OFFSET;
    }

    function getFirstPool(bytes memory path) internal pure returns(bytes memory){
        return path.slice(0,POP_SIZE);
    }

    function skipToken(bytes memory path) internal pure returns(bytes memory){
        return path.slice(NEXT_OFFSET,path.length-NEXT_OFFSET);
    }

    function decodeFirstPool(bytes memory path) internal pure returns(
        address token0,
        address token1,
        uint256 tickSpacing
    ){
        token0 = path.toAddress(0);
        token1 = path.toAddress(NEXT_OFFSET);
        tickSpacing = path.toUint256(ADDR_SIZE);
    }
}