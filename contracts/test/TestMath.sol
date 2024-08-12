// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "../lib/Math.sol";

contract TestMath {
    // (1)
    function calcAmount0Active(
        uint128 deltaL,
        uint160 C, // X96
        uint256 P  // X96
    ) public pure returns (
        uint256 deltaX // X96
    ) {
        deltaX = Math.calcAmount0Active(deltaL,C,P);
    }

    // (2)
    function calcAmount1Active(
        uint128 deltaL,
        uint160 C // X96
    ) public pure returns(
        uint256 deltaY // X96
    ){
        deltaY = Math.calcAmount1Active(deltaL,C);
    }

    // (3) 
    function calcAmount0Inactive(
        uint128 deltaL,
        uint256 P // X96
    ) public pure returns(
        uint256 deltaX // X96
    ){
        deltaX = Math.calcAmount0Inactive(deltaL,P);
    }
    
    // (4) 
    function calcAmount1Inactive(
        uint128 deltaL
    ) public pure returns(
        uint256 deltaY // X96
    ){
        deltaY = Math.calcAmount1Inactive(deltaL);
    }


    //////////
    // Swap //
    //////////    
    
    // (5)
    function calcCompositionAtAmount0(
        uint256 price, // X96
        uint128 liquidity,
        uint256 deltaAmount0 // X96
    ) public pure returns(
        uint160 deltaComposition // X96
    ){
        deltaComposition = Math.calcCompositionAtAmount0(price,liquidity,deltaAmount0);
    }

    // (6)
    function calcCompositionAtAmount1(
        uint128 liquidity,
        uint256 deltaAmount1 // X96
    ) public pure returns(
        uint160 deltaComposition // X96
    ){
        deltaComposition = Math.calcCompositionAtAmount1(liquidity,deltaAmount1);
    }

    // (7) 
    function calcAmount0(
        uint128 L,
        uint160 deltaC, // X96
        uint256 P // X96
    ) public pure returns (
        uint256 deltaX // X96
    ) {
        deltaX = Math.calcAmount0(L,deltaC,P);   
    }
    
    // (8) 
    function calcAmount1(
        uint128 L,
        uint160 deltaC // X96
    ) public pure returns(
        uint256 deltaY // X96
    ){
        deltaY = Math.calcAmount1(L,deltaC);
    }
    
}