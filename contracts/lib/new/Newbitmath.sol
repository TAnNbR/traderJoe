// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "hardhat/console.sol";

library Newbitmath{
    function mostSignificantBit(uint256 value) internal returns(uint256 res){
        if((value>>127)!=0){
            value>>=128;
            res+=128;
        }
        if((value>>63)!=0){
            value>>=64;
            res+=64;
        }
        if((value>>31)!=0){
            value>>=32;
            res+=32;
        }
        if((value>>15)!=0){
            value>>=16;
            res+=16;
        }
        if((value>>7)!=0){
            value>>=8;
            res+=8;
        }
        if((value>>3)!=0){
            value>>=4;
            res+=4;
        }
        if((value>>1)!=0){
            value>>=2;
            res+=2;
        }
        if(value!=0){
            value>>=1;
            res+=1;
        }
        //console.log("mostSignificant = ",res);
    }

    function leastSignificantBit(uint256 value) internal returns(uint256 res){
        uint256 temp;
        
        if((value&type(uint128).max)>0){
            temp+=128; 
        }else{
            value>>=128;
        }

        if((value&type(uint64).max)>0){
            temp+=64; 
        }else{
            value>>=64;
        }

        if((value&type(uint32).max)>0){
            temp+=32; 
        }else{
            value>>=32;
        }

        if((value&type(uint16).max)>0){
            temp+=16; 
        }else{
            value>>=16;
        }

        if((value&type(uint8).max)>0){
            temp+=8; 
        }else{
            value>>=8;
        }

        if((value&0xf)>0){
            temp+=4; 
        }else{
            value>>=4;
        }

        if((value&3)>0){
            temp+=2; 
        }else{
            value>>=2;
        }

        if((value&1)>0){
            temp+=1; 
        }else{
            value>>=1;
        }

        res = 256 - temp;       
    }
}