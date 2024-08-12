// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "../lib/BinMath.sol";

contract TestBinMath{
    function getPriceAtBin(uint32 bin) public pure returns (uint256 priceX96) {
        priceX96 = BinMath.getPriceAtBin(bin);
    }
}