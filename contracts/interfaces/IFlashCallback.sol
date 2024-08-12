// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.14;

interface IFlashCallback {
    function flashCallback(
        uint256[] memory amount0,
        uint256[] memory amount1,
        uint256[] memory ids
    ) external;
}
