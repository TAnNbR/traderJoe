// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../new/NewIndexTree.sol";

import "hardhat/console.sol";

contract TestTree{
    NewIndexTree.BigTree bigtree;
    using NewIndexTree for NewIndexTree.BigTree;

    function flipbin(uint32 bin) public{
        bigtree.flipBin(bin);

        uint256 newLevel2 = bigtree.level2[uint16(bin>>8)];
        uint256 newLevel1 = bigtree.level1[uint8(bin>>16)];
        uint256 newLevel0 = bigtree.level0;

        console.log(bin,newLevel0,newLevel1,newLevel2);
    }

    function findsmallbin(uint32 bin) public returns(uint32 nextBin){
        nextBin = bigtree.FindSmallBin(bin);
        console.log("nextBin = ",nextBin);
    }

    function findbigbin(uint32 bin) public returns(uint32 nextBin){
        nextBin = bigtree.FindBigBin(bin);
        console.log("nextBin = ",nextBin);
    }

}