// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../Pool.sol";

library PoolAddress{
    function computePoolAddress(
        address factory,
        address token0,
        address token1,
        uint256 tickSpacing
    ) public pure returns(address pool){
        require(token0 < token1);

        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(
                                token0,
                                token1,
                                tickSpacing
                            )),
                            keccak256(type(Pool).creationCode)
                        )
                    )
                )
            )
        );
    }
}