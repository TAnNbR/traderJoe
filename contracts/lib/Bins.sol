// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

library Bins {

    /**
     * @param initialized 一个bin在有流动性时为true，否则为false 
     * @param liquidity  一个bin含有的流动性数量，mint时可以改变
     */
    struct Info{
        bool initialized;      
        uint128 liquidity;
    }
    
    /**
     * @notice 只在mint时使用
     * @param self 定义类型方法
     * @param bin 操作bin
     * @param liquiditydelta 增加或减少的流动性数量 
     */
    function update(
        mapping (int32 => Bins.Info) storage self,
        int32 bin,
        uint128 liquiditydelta
    ) internal returns(bool flipped){

        Bins.Info storage target_bin=self[bin];

        if(target_bin.liquidity==0) target_bin.initialized=true;

        uint128 liquiditybefore=target_bin.liquidity;
        uint128 liquidityafter=liquiditybefore+liquiditydelta;
        
        // 当流动性添加到一个空bin或者一个bin被耗尽时，翻转
        // flipped是给Indextree用的，根据这个bin是否有流动性，决定是否要将这个位置翻转
        flipped = (liquidityafter == 0) != (liquiditybefore == 0);

        target_bin.liquidity=liquidityafter;

    }
    
}

