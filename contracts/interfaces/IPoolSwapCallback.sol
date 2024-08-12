// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.14;

interface IPoolSwapCallback {
    function PoolSwapCallback(
        uint256[] memory bins,
        uint256[] memory amount0,
        uint256[] memory amount1,
        bytes calldata data,
        bool  zeroforone
    ) external;
}