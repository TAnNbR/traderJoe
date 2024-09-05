// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface IPoolManager{
    struct SwapCallBackParams{
        bytes path;
        address recepient;
    }

    struct SwapMultipleParameters{
        uint256 expectedAmount; // X96
        uint256 minAmount;
        bool    zeroforone;
        bytes   path;
        address recepient;
    }
}