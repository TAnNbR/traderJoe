// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.14;

library BinMath {

    // tick = [ -2^19 , 2^19 ] = [-524288,524288]
    // b = 2^23 = 8388608
    
    int32 internal constant b = 8388608;
    int24 internal constant MAX_TICK = 524288;

    function getPriceAtBin(uint32 bin) internal pure returns (uint256 priceX96) {

        int24 tick = int24(int32(bin)-b);
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(uint24(MAX_TICK)), 'bin is out of range !');

        // 0x1(2^0) ~ 0x80000(2^19)
        uint256 ratio = absTick & 0x1 != 0 ? 0xfff97272373d40000000000000000000 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff2e50f5f6570000000000000000000) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xffe5caca7e10f0000000000000000000) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffcb9843d60f68000000000000000000) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xff973b41fa98d8000000000000000000) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff2ea16466c980000000000000000000) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xfe5dee046a99d8000000000000000000) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfcbe86c7900ae8000000000000000000) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xf987a7253ac4d8000000000000000000) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf3392b0822b880000000000000000000) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xe7159475a2c578000000000000000000) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xd097f3bdfd2550000000000000000000) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xa9f746462d8f78000000000000000000) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0x70d869a156ddd4000000000000000000) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x31be135f97da6e000000000000000000) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x9aa508b5b7e5a800000000000000000) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x5d6af8dedbcb380000000000000000) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x2216e584f6303800000000000000) >> 128;

        if (absTick & 0x40000 != 0) ratio = (ratio * 0x48a1703920644c000000000) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x149b34ee7b4533) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;
        
        // 上舍入
        priceX96 = uint256((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

}