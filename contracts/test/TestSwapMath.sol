// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "../lib/SwapMath.sol";

contract TestSwapMath{

    function computeSwap( 
        uint256 currentPrice,      // X96
        uint128 activeLquidity,
        uint160 activeComposition, // X96
        uint256 nextPrice,         // X96
        bool zeroForOne,
        uint256 amountRemain       // X96
    ) public pure returns(
        uint256 _nextPice,
        uint160 compositionAfter,  // X96
        uint256 amountIn,          // X96
        uint256 amountOut          // X96
    ){

        (
            _nextPice,
            compositionAfter,
            amountIn,
            amountOut
        ) = SwapMath.computeSwap(
            currentPrice,      // X96
            activeLquidity,
            activeComposition, // X96
            nextPrice,         // X96
            zeroForOne,
            amountRemain       // X96
        );

    }

}
    