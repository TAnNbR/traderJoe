// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Token is ERC1155{
    constructor(string memory uri) ERC1155(uri){}
    
    // 给用户冲币
    function recharge(
        uint256 bin,
        uint256 amount,    // X96
        bytes memory data
    ) public{
        _mint(msg.sender,bin,amount,data);
    }
    
    // 给用户多区间冲币
    function rechargeBatch(
        uint256[] memory bin,
        uint256[] memory amount,  // X96
        bytes memory data
    ) public{
        _mintBatch(msg.sender,bin,amount,data);
    }

}