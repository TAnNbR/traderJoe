// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.14;

interface IJoeSwapCallBack {
    function JoeSwapCallBack(
        uint256[] memory ids,
        uint256[] memory amountsOfToken0, // X96
        uint256[] memory amountsOfToken1, // X96
        bytes memory data,
        bool zeroForOne
    ) external;
}
