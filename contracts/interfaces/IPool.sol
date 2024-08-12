// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface IPool {

    struct CallBackData{
        address token0;
        address token1;
        address payer;
    }
    
    function mint(
        address owner,
        uint32  target_bin,
        uint128 amount,
        bytes   calldata data
    ) external returns (
        uint256 amount0,
        uint256 amount1
    );

    function swap(
        uint256 expectedAmount, // X96
        uint256 limitPrice,     // X96
        bool    zeroforone,
        bytes   calldata data
    ) external returns( 
        uint256 amount0,        // X96
        uint256 amount1         // X96
    );
    
    function slot() external returns(
        uint256 pi,
        uint32  bin
    );
}