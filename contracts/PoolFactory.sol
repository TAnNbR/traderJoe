// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Pool.sol";

import "./interfaces/IDeployer.sol";

contract PoolFactory is IDeployer{
    error InValidTickSpacing(uint256);
    error PoolAlreadyExisted();
    error TokenMustDifferent();
    error InValidToken(address);

    event PoolCreate(
        address factory,
        address token0,
        address token1,
        uint256 tickSpacing,
        address pool
    );

    mapping(uint256 => bool) tickSpacings;
    mapping(address => mapping(address => mapping(uint256 => bool))) poolExisted;

    PoolParameters public parameter;

    constructor(){
        tickSpacings[60] = true;
        tickSpacings[100] = true;
    }

    function createPool(
        address token0,
        address token1,
        uint256 tickSpacing
    ) external returns(address pool){
        if(!tickSpacings[tickSpacing]) revert InValidTickSpacing(tickSpacing);
        if(poolExisted[token0][token1][tickSpacing]) revert PoolAlreadyExisted();
        if(token0 == token1) revert TokenMustDifferent();

        (token0,token1) = token0>token1 ? (token1,token0) : (token0,token1);

        if(token0 == address(0)) revert InValidToken(token0);

        parameter = PoolParameters({
            factory : address(this),
            token0  : token0,
            token1  : token1,
            tickSpacing : tickSpacing
        });

        pool = new Pool{
            salt : keccak256(abi.encodePacked(token0,token1,tickSpacing))
        }();

        delete parameter;

        poolExisted[token0][token1][tickSpacing] = true;
        poolExisted[token1][token0][tickSpacing] = true;

        emit PoolCreate(address(this), token0, token1, tickSpacing, pool);
    }
}