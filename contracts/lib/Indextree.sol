// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./BitMath.sol";

library Indextree{
    
    /**
     * @notice 不读不写状态变量
     */
    function position(int32 bin) private pure returns(int32 wordPos,uint8 bitPos){
        wordPos=int32(bin>>8);
        bitPos=uint8(int8(bin%256));       
    }
    
    /**
     * @notice 修改状态变量
     */
    function flipBin(
        mapping (int32 => uint256) storage self,
        int32 bin,
        int32 binSpacing
    ) internal {
        require(bin%binSpacing==0);
        (int32 wordPos,uint8 bitPos)=position(bin);
        uint256 mask=1 << bitPos;
        self[wordPos] ^=mask;
    }
    
    /**
     * @notice 只读状态变量
     */
    function nextInitializedBinWithinOneWord(
        mapping (int32 => uint256) storage self,
        int32 bin,
        int32 binSpacing,
        bool lte
    ) internal view returns(int32 next,bool initialized){
        int32 compressed =bin/binSpacing;

        if(lte){
            (int32 wordPos,uint8 bitPos)=position(compressed);

            // 这里可能存在bug，注释掉
            uint256 mask=(1<<bitPos)-1; // +(1<<bitPos);
            uint256 masked =self[wordPos]&mask;
            
            initialized=(masked!=0);

            next= initialized
                ? (compressed-int32(uint32(bitPos-BitMath.mostSignificantBit(masked))))*binSpacing
                : (compressed-int32(uint32(bitPos)))*binSpacing;       
        }
        else{
            (int32 wordPos,uint8 bitPos)=position(compressed+1);
            uint256 mask= ~((1<<bitPos)-1);
            uint256 masked=self[wordPos]&mask;

            initialized=(masked!=0);

            next=initialized
                ? (compressed + 1 + int32(uint32((BitMath.leastSignificantBit(masked) - bitPos)))) * binSpacing
                : (compressed + 1 + int32(uint32((type(uint8).max - bitPos)))) * binSpacing; 
        }
    }

}