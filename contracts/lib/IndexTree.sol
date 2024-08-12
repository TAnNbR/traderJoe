// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./BitMath.sol";
import "hardhat/console.sol";

library IndexTree{
    struct BigTree{
        uint256 level0;
        mapping(uint8 => uint256) level1;
        mapping(uint16 => uint256) level2;
    }

    function flipBin(
        BigTree storage self,
        uint32 bin
    ) internal {
        uint16 key2 = uint16(bin >> 8);
        uint8 bitpos2 = uint8(bin);

        uint256 leaves = self.level2[key2];
        uint256 newLeaves = leaves | (1<<bitpos2);
        self.level2[key2] = newLeaves;

        uint8 key1 = uint8(key2>>8);
        uint8 bitpos1 = uint8(key2);

        leaves = self.level1[key1];
        newLeaves = leaves | (1<<bitpos1);
        self.level1[key1] = newLeaves;

        self.level0 |= (1<<key1);
    }

    function FindSmallBin(
        BigTree storage self,
        uint32 bin
    ) internal view returns(uint32){

        uint256 res;

        // 第三层
        uint16 key2 = uint16(bin >> 8); // start at 0
        uint8 bitpos2 = uint8(bin);     // mod 2^8

        uint256 leaves = self.level2[key2];
        uint256 masked = leaves&((1<<bitpos2)-1);
        if(masked>0){
            // debug
            // console.log("           <third>");
            
            res = BitMath.mostSignificantBit(masked);
            uint32 delta0 = uint32(bitpos2+1-uint8(res));
            return bin - delta0;

        }else{
            // 第二层
            uint8 key1 = uint8(key2>>8);
            uint8 bitpos1 = uint8(key2&(type(uint8).max));

            leaves = self.level1[key1];
            masked = leaves&((1<<bitpos1)-1);

            if(masked>0){
                // debug
                // console.log("           <second>");

                res = BitMath.mostSignificantBit(masked);
                uint16 delta1 = uint16(bitpos1+1-uint8(res));
                key2 -= delta1;
                
                leaves = self.level2[key2];
                res = BitMath.mostSignificantBit(leaves);

                return (uint32(key2)<<8) + uint32(res) - 1;

            }else{
                // 第一层
                masked = self.level0&((1<<key1)-1);

                if(masked>0){
                    // debug
                    // console.log("           <first>");

                    res = BitMath.mostSignificantBit(masked);
                    key1 = uint8(res);
                    
                    leaves = self.level1[key1-1];
                    res = BitMath.mostSignificantBit(leaves);
                    key2 = (uint16(key1-1)<<8) + uint16(res);

                    leaves = self.level2[key2-1];
                    res = BitMath.mostSignificantBit(leaves);

                    return (uint32(key2-1)<<8) + uint32(res) - 1;

                }else{
                    // debug
                    // console.log("           <null>");

                    return type(uint32).max;

                }// third if

            }// second if

        }// first if
    }

    function FindBigBin(
        BigTree storage self,
        uint32 bin
    ) internal view returns(uint32){

        uint256 res;

        // 第三层
        uint16 key2 = uint16(bin >> 8); // start at 0
        uint8 bitpos2 = uint8(bin);     // mod 2^8

        uint256 leaves = self.level2[key2];
        uint256 masked = leaves&(~((1<<(bitpos2+1))-1));
        
        /** debug
         ** console.log("bin = ",bin);
         ** console.log("leaves = ",leaves);
         ** console.log("~ = ",(~((1<<(bitpos2+1))-1)));
         ** console.log("masked = ",masked);
         */

        if(masked>0){
            // debug
            // console.log("           <third>");

            res = BitMath.leastSignificantBit(masked);
            uint32 delta0 = uint32(uint8(res)-1-bitpos2);
            return bin + delta0;

        }else{
            // 第二层
            uint8 key1 = uint8(key2>>8);
            uint8 bitpos1 = uint8(key2&(type(uint8).max));

            leaves = self.level1[key1];
            masked = leaves&(~((1<<(bitpos1+1))-1));
            if(masked>0){
                // debug
                // console.log("           <second>");

                res = BitMath.leastSignificantBit(masked);
                uint16 delta1 = uint16(uint8(res)-1-bitpos1);
                key2 += delta1;
                
                leaves = self.level2[key2];
                res = BitMath.leastSignificantBit(leaves);

                return (uint32(key2)<<8) + uint32(res) - 1;

            }else{
                // 第一层
                masked = self.level0&(~((1<<(key1+1))-1));

                if(masked>0){
                    // debug
                    // console.log("           <first>");

                    res = BitMath.leastSignificantBit(masked);
                    key1 = uint8(res);
                    
                    leaves = self.level1[key1-1];
                    res = BitMath.leastSignificantBit(leaves);
                    key2 = (uint16(key1-1)<<8) + uint16(res);

                    leaves = self.level2[key2-1];
                    res = BitMath.leastSignificantBit(leaves);

                    return (uint32(key2-1)<<8) + uint32(res) - 1;

                }else{
                    // debug
                    // console.log("           <null>");

                    return type(uint32).max;

                }// third if

            }// second if

        }// first if
    }

    

}