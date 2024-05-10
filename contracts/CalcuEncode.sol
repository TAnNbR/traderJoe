// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

contract CalcuEncode {

    struct CallBackData{
        address token0;
        address token1;
        address payer;
    }

    address token0=0xd9145CCE52D386f254917e481eB44e9943F39138;
    address token1=0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8;
    address payer=0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    int32 bin=8473784;

    function intChange() external returns (uint256 res){
        res=uint256(int256(bin));
    }
    
    function before() external returns (bytes memory){
        bytes memory extra = abi.encode(token0,token1,payer);
        return extra;
    }

    function res(bytes memory extra) external returns (CallBackData memory){
        CallBackData memory res=abi.decode(extra,(CallBackData));
        return res;
    }


// 定义数据结构
    struct MintParams {
        address poolAddress;
        int24 lowerTick;
        int24 upperTick;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
    }


    address poolAddress=0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47;
    int24 lowerTick=84222;
    int24 upperTick=86129;
    uint256 amount0Desired=100;
    uint256 amount1Desired=100;
    uint256 amount0Min=0;
    uint256 amount1Min=0;

    function before1() external returns (bytes memory){
        bytes memory extra = abi.encode(
            poolAddress,
            lowerTick,
            upperTick,
            amount0Desired,
            amount1Desired,
            amount0Min,
            amount1Min
        );
        return extra;
    }



} 