// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Math.sol";

library SwapMath {

    function computeSwap( 
        uint256 currentPrice,      // X96
        uint128 activeLquidity,
        uint160 activeComposition, // X96
        uint256 nextPrice,         // X96
        bool zeroForOne,
        uint256 amountRemain       // X96
    ) internal pure returns(
        uint256 _nextPice,
        uint160 compositionAfter,  // X96
        uint256 amountIn,          // X96
        uint256 amountOut          // X96
    ){
        
        // 计算出当前区间能提供的最大流动性
        if(zeroForOne){

            // 流出x
            uint160 deltaComposition = uint160(1<<96) - activeComposition;
            amountOut = Math.calcAmount0(
                activeLquidity,
                deltaComposition,
                currentPrice
            );

        }else{

            // 流出y
            uint160 deltaComposition = activeComposition;
            amountOut = Math.calcAmount1(
                activeLquidity,
                deltaComposition
            );

        }

        // 富余，跳转区间内，更新composition
        if(amountOut > amountRemain){

            uint160 deltaComposition;

            if(zeroForOne){

                // 流出x
                amountOut = amountRemain;
                deltaComposition = Math.calcCompositionAtAmount0(
                    currentPrice,
                    activeLquidity,
                    amountOut
                );
                amountIn = Math.calcAmount1(
                    activeLquidity,
                    deltaComposition
                );

                // 更新composion
                compositionAfter = activeComposition + deltaComposition;
                
            }else{

                // 流出y
                amountOut = amountRemain;
                deltaComposition = Math.calcCompositionAtAmount1(
                    activeLquidity,
                    amountOut
                );
                amountIn = Math.calcAmount0(
                    activeLquidity,
                    deltaComposition,
                    currentPrice
                );

                // 更新composion
                compositionAfter = activeComposition - deltaComposition; 
            }
            
            // 价格不变
            _nextPice = currentPrice;
        
        
        }

        // 刚好或不足，跳转下个区间
        else{

            uint160 deltaComposition;

            if(zeroForOne){

                // 流出x
                deltaComposition = uint160(1<<96) - activeComposition;
                amountOut = Math.calcAmount0(
                    activeLquidity,
                    deltaComposition,
                    currentPrice
                );
                amountIn = Math.calcAmount1(
                    activeLquidity,
                    deltaComposition
                );

                // 更新composion
                compositionAfter = 0;

            }else{

                // 流出y
                deltaComposition = activeComposition;
                amountOut = Math.calcAmount1(
                    activeLquidity,
                    deltaComposition
                );
                amountIn = Math.calcAmount0(
                    activeLquidity,
                    deltaComposition,
                    currentPrice
                );

                // 更新composion
                compositionAfter = uint160(1<<96);
            }

            // 现价改变为下一个价格
            _nextPice = nextPrice;

        }
    }
    
}