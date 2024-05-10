// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/// @notice bins数据结构库合约

library Position{
    struct Info{
        uint128 liquidity;
    }
    
    //获取Info
    function get(
        mapping(bytes32=>Position.Info) storage self,
        address owner,
        int32 bin
    ) internal returns(Position.Info storage position){
        position=self[keccak256(abi.encodePacked(owner,bin))];
    }

    function update(
        Info storage self,
        uint128 liquiditydelta
        ) internal{
        uint128 liquiditybefore=self.liquidity;
        uint128 liquidityafter=liquiditybefore+liquiditydelta;
        self.liquidity=liquidityafter;
    }
}