// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "prb-math/PRBMath.sol";
import "./FixedPoint96.sol";

/**
 * @title Math
 * @author Tam
 * @notice 实现mint和swap中获取 deltaAmount0 ，deltaAmount1 ，deltaComposition 的函数
 */
library Math{
    
    /**
     * @notice target_bin = current_bin
     * @dev mint和swap都会用到
     */
    function calcAmount0CurrentDeltaMint(
        uint128 liquidity,
        uint160 composition, // X96
        uint256 target_price
    ) internal pure returns (
        uint256 amount0 // X96
    ) {

        // 涉及到浮点数的计算，要把所有浮点数转换成Q64.96来计算
        // 这里存在微小的精度损失
        uint160 OneX96=uint160(1<<96);
        amount0 = mulDivRoundingUp(
            (uint256(liquidity) << FixedPoint96.RESOLUTION),
            (OneX96-composition),
            target_price // << FixedPoint96.RESOLUTION
        );    
    }

    /**
     * @notice target_bin = current_bin
     * @dev mint和swap都会用到
     */
    function calcAmount0CurrentDelta(
        uint128 liquidity,
        uint160 composition, // X96
        uint256 target_price
    ) internal pure returns (
        uint256 amount0 // X96
    ) {

        // 涉及到浮点数的计算，要把所有浮点数转换成Q64.96来计算
        // 这里存在微小的精度损失
        uint160 OneX96=uint160(1<<96);
        amount0 = mulDivRoundingUp(
            (uint256(liquidity) << FixedPoint96.RESOLUTION),
            (OneX96-composition),
            target_price << FixedPoint96.RESOLUTION
        );    
    }
    
    /**
     * @notice target_bin = current_bin
     * @dev mint和swap都会用到
     */
    function calcAmount1CurrentDelta(
        uint128 liquidity,
        uint160 composition // X96
    ) internal pure returns(
        uint256 amount1 // X96
    ){
        amount1=PRBMath.mulDiv(
            (uint256(liquidity) << FixedPoint96.RESOLUTION),
            composition,
            1<< FixedPoint96.RESOLUTION
        );
  
    }


    /**
     * @notice target_bin > current_bin
     * @dev mint会用到
     */
    function calcAmount0Inactive(
        uint128 liquidity,
        uint256 target_price
    ) internal pure returns(
        uint256 amount0 // X96
    ){
        amount0=PRBMath.mulDiv(
            (uint256(liquidity) << FixedPoint96.RESOLUTION),
            (1<< FixedPoint96.RESOLUTION),
            target_price
        );
    }
    
    /**
     * @notice target_bin < current_bin
     * @dev mint会用到
     */
    function calcAmount1Inactive(
        uint128 liquidity
    ) internal pure returns(
        uint256 amount1 // X96
    ){
        amount1=(uint256(liquidity) << FixedPoint96.RESOLUTION);
    }
    

    function calcCompositionAtAmount0(
        uint256 price,
        uint128 liquidity,
        uint256 deltaAmount0 // X96
    ) internal pure returns(
        uint160 deltaComposition // X96
    ){
        deltaComposition = uint160(mulDivRoundingUp(
            (price<<FixedPoint96.RESOLUTION),
            deltaAmount0,
            (liquidity<<FixedPoint96.RESOLUTION)
        ));
    }

    function calcCompositionAtAmount1(
        uint128 liquidity,
        uint256 deltaAmount1 // X96
    ) internal pure returns(
        uint160 deltaComposition // X96
    ){
        deltaComposition = uint160(mulDivRoundingUp(
            deltaAmount1,
            (1<< FixedPoint96.RESOLUTION),
            (liquidity<<FixedPoint96.RESOLUTION)
        ));
    }


    function mulDivRoundingUp(
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

}