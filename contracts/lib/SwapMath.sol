// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Math.sol";

library SwapMath {

    struct ComputeSwapParams {
        uint256 currentPrice;
        uint128 activeLquidity;
        uint160 activeComposition; // X96
        uint256 nextPrice;
        bool zeroForOne;
        uint256 amountRemain; // X96       
    }

    function computeSwap( 
        uint256 currentPrice,
        uint128 activeLquidity,
        uint160 activeComposition, // X96
        uint256 nextPrice,
        bool zeroForOne,
        uint256 amountRemain // X96
    ) internal pure returns(
        uint256 _nextPice,
        uint160 compositionAfter, // X96
        uint256 amountIn, // X96
        uint256 amountOut // X96
    ){
        
        // 计算出当前区间能提供的最大流动性
        if(zeroForOne){

            // 流出y
            amountOut=Math.calcAmount1CurrentDelta(
                activeLquidity,
                activeComposition
            );
        }else{

            // 流出x
            amountOut=Math.calcAmount0CurrentDelta(
                activeLquidity,
                activeComposition,
                currentPrice
            );
        }
        

        // 富余，在当前pi内跳转，更新composition
        // 刚好或不足，跳边界
        if(amountOut > amountRemain){
            amountOut=amountRemain;
            uint160 deltaComposition;
            if(zeroForOne){

                // 流出y
                deltaComposition = Math.calcCompositionAtAmount1(
                    activeLquidity,
                    amountOut
                );
                uint160 OneX96=uint160(1<<FixedPoint96.RESOLUTION);
                amountIn = Math.calcAmount0CurrentDelta(
                    activeLquidity,
                    (OneX96-deltaComposition),
                    currentPrice
                );

                // 更新composion
                compositionAfter = activeComposition - deltaComposition;
                
            }else{

                // 流出x
                deltaComposition = Math.calcCompositionAtAmount0(
                    currentPrice,
                    activeLquidity,
                    amountOut
                );
                amountIn= Math.calcAmount1CurrentDelta(
                    activeLquidity,
                    deltaComposition
                );

                // 更新composion
                compositionAfter = activeComposition + deltaComposition; 
            }
            
            // 价格不变
            _nextPice=currentPrice;

        }else{
            if(zeroForOne){

                // 流出y
                uint160 OneX96=uint160(1<<96);
                amountIn=Math.calcAmount0CurrentDelta(
                    activeLquidity,
                    (OneX96-activeComposition),
                    currentPrice
                );
                amountOut=Math.calcAmount1CurrentDelta(
                    activeLquidity,
                    activeComposition
                );

                // 更新composion
                compositionAfter=1;

            }else{

                // 流出x
                uint160 OneX96=uint160(1<<FixedPoint96.RESOLUTION);
                amountIn=Math.calcAmount1CurrentDelta(
                    activeLquidity,
                    (OneX96-activeComposition)
                );
                amountOut=Math.calcAmount0CurrentDelta(
                    activeLquidity,
                    activeComposition,
                    currentPrice
                );

                // 更新composion
                compositionAfter=0;
            }

            // 现价改变为下一个价格
            _nextPice=nextPrice;
        }


    }
}