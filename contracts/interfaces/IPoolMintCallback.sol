// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.14;

interface IPoolMintCallback {
    function PoolMintCallback(
        uint32 target_bin,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}
