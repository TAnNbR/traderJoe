// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.14;

interface IDeployer{
    struct PoolParameters{
        address factory;
        address token0;
        address token1;
        uint256 tickSpacing;
    }

    function parameter() external returns(
        address factory,
        address token0,
        address token1,
        uint256 tickSpacing
    );
}