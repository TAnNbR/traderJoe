// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "../lib/IndexTree.sol";
import "hardhat/console.sol";

contract TestIndexTree{
    IndexTree.BigTree bigtree;
    using IndexTree for IndexTree.BigTree;

    function flipbin(uint32 bin) public{
        bigtree.flipBin(bin);

        uint256 newLevel2 = bigtree.level2[uint16(bin>>8)];
        uint256 newLevel1 = bigtree.level1[uint8(bin>>16)];
        uint256 newLevel0 = bigtree.level0;

        console.log(bin,newLevel0,newLevel1,newLevel2);
    }

    function findsmallbin(uint32 bin) public view returns(uint32 nextBin){
        nextBin = bigtree.FindSmallBin(bin);
        console.log("nextBin = ",nextBin);
    }

    function findbigbin(uint32 bin) public view returns(uint32 nextBin){
        nextBin = bigtree.FindBigBin(bin);
        console.log("nextBin = ",nextBin);
    }

}