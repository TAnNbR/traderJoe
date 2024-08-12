// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "prb-math/PRBMath.sol";
import "./FixedPoint96.sol";

library Math{

    //////////
    // Mint //
    //////////

    // (1)
    function calcAmount0Active(
        uint128 deltaL,
        uint160 C, // X96
        uint256 P  // X96
    ) internal pure returns (
        uint256 deltaX // X96
    ) {

        // 这里存在微小的精度损失
        uint160 OneX96=uint160(1<<96);
        deltaX = PRBMath.mulDiv(
            (uint256(deltaL) << FixedPoint96.RESOLUTION),
            (OneX96-C),
            P
        );    
    }

    // (2)
    function calcAmount1Active(
        uint128 deltaL,
        uint160 C // X96
    ) internal pure returns(
        uint256 deltaY // X96
    ){
        deltaY=PRBMath.mulDiv(
            (uint256(deltaL) << FixedPoint96.RESOLUTION),
            C,
            1<< FixedPoint96.RESOLUTION
        );
  
    }

    // (3) 
    function calcAmount0Inactive(
        uint128 deltaL,
        uint256 P // X96
    ) internal pure returns(
        uint256 deltaX // X96
    ){
        deltaX=PRBMath.mulDiv(
            (uint256(deltaL) << FixedPoint96.RESOLUTION),
            (1<< FixedPoint96.RESOLUTION),
            P
        );
    }
    
    // (4) 
    function calcAmount1Inactive(
        uint128 deltaL
    ) internal pure returns(
        uint256 deltaY // X96
    ){
        deltaY=(uint256(deltaL) << FixedPoint96.RESOLUTION);
    }


    //////////
    // Swap //
    //////////    
    
    // (5)
    function calcCompositionAtAmount0(
        uint256 price, // X96
        uint128 liquidity,
        uint256 deltaAmount0 // X96
    ) internal pure returns(
        uint160 deltaComposition // X96
    ){
        deltaComposition = uint160(PRBMath.mulDiv(
            price,
            deltaAmount0,
            (liquidity<<FixedPoint96.RESOLUTION)
        ));
    }

    // (6)
    function calcCompositionAtAmount1(
        uint128 liquidity,
        uint256 deltaAmount1 // X96
    ) internal pure returns(
        uint160 deltaComposition // X96
    ){
        deltaComposition = uint160(PRBMath.mulDiv(
            deltaAmount1,
            (1<< FixedPoint96.RESOLUTION),
            (liquidity<<FixedPoint96.RESOLUTION)
        ));
    }

    // (7) 
    function calcAmount0(
        uint128 L,
        uint160 deltaC, // X96
        uint256 P // X96
    ) internal pure returns (
        uint256 deltaX // X96
    ) {
        deltaX = PRBMath.mulDiv(
            (uint256(L) << FixedPoint96.RESOLUTION),
            deltaC,
            P
        );    
    }
    
    // (8) 
    function calcAmount1(
        uint128 L,
        uint160 deltaC // X96
    ) internal pure returns(
        uint256 deltaY // X96
    ){
        deltaY=PRBMath.mulDiv(
            (uint256(L) << FixedPoint96.RESOLUTION),
            deltaC,
            1 << FixedPoint96.RESOLUTION
        );
  
    }

    /*上舍入
    function PRBMath.mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
    */

}