const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
const { expect } = require("chai");

/**
 * @dev mint时各个合约间的逻辑：
 * 1.admin充值ERC155代币
 * 2.admin =>[setApproved]=> manager
 * 3.manager.Mint()
 */

describe("test mint",async function(){
    let token0,token1,admin,manager,pool;

    const X96 = BigNumber.from(2).pow(96);
    const half = BigNumber.from(2).pow(95);
    const tenThousandX96 = BigNumber.from(10000).mul(X96);
    const fiveThousandX96 = BigNumber.from(5000).mul(X96);
    
    const pX96 = BigNumber.from(5000).mul(X96);
    const bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
    const lowBin = bin.sub(10);
    const highBin = bin.add(10);

    const uri_0 = "xxx/xxx/xxx.json";
    const uri_1 = "yyy/yyy/yyy.json";
    const data = "0x123456";

    it("deploy",async function(){
        const Token0  = await ethers.getContractFactory("Token");
        const Token1  = await ethers.getContractFactory("Token");
        const Manager = await ethers.getContractFactory("PoolManager");
        const Pool    = await ethers.getContractFactory("Pool");

        [admin] = await ethers.getSigners();
        token0  = await Token0.deploy(uri_0);
        token1  = await Token1.deploy(uri_1);
        manager = await Manager.deploy();
        pool    = await Pool.deploy(token0.address,token1.address,pX96,bin);
    });

    it("prepare",async function(){
        const bins = [lowBin,bin,highBin];
        const amounts = [
            tenThousandX96,
            tenThousandX96,
            tenThousandX96
        ];
        
        // 充币
        await token0.connect(admin).rechargeBatch(bins,amounts,data);
        await token1.connect(admin).rechargeBatch(bins,amounts,data);
        expect(tenThousandX96).to.equal(await token0.balanceOf(admin.address,lowBin));
        expect(tenThousandX96).to.equal(await token0.balanceOf(admin.address,bin));
        expect(tenThousandX96).to.equal(await token0.balanceOf(admin.address,highBin));
        expect(tenThousandX96).to.equal(await token1.balanceOf(admin.address,lowBin));
        expect(tenThousandX96).to.equal(await token1.balanceOf(admin.address,bin));
        expect(tenThousandX96).to.equal(await token1.balanceOf(admin.address,highBin));

        // 批准
        await token0.connect(admin).setApprovalForAll(manager.address,true);
        await token1.connect(admin).setApprovalForAll(manager.address,true);
        expect(true).to.equal(await token0.isApprovedForAll(admin.address,manager.address));
        expect(true).to.equal(await token1.isApprovedForAll(admin.address,manager.address));

    });

    it("mint currentBin",async function(){
        const dataEncoded = ethers.utils.defaultAbiCoder.encode(
            ['address','address','address'],
            [token0.address,token1.address,admin.address]
        );

        await manager.connect(admin).mint(
            pool.address,
            bin,
            10000,
            dataEncoded
        );
        
        // 这里的 priceX96 是有精度差距的，因为mint里使用了内嵌的 getPriceAtBin
        const amount0 = await token0.balanceOf(pool.address,bin);
        const amount1 = await token1.balanceOf(pool.address,bin);

        expect(1).to.equal(BigNumber.from(amount0).div(X96));
        expect(5000).to.equal(BigNumber.from(amount1).div(X96));
        

    });

    it("mint lowBin",async function(){
        const dataEncoded = ethers.utils.defaultAbiCoder.encode(
            ['address','address','address'],
            [token0.address,token1.address,admin.address]
        );

        await manager.connect(admin).mint(
            pool.address,
            lowBin,
            10000,
            dataEncoded
        );
        
        // 这里的 priceX96 是有精度差距的，因为mint里使用了内嵌的 getPriceAtBin
        const amount0 = await token0.balanceOf(pool.address,lowBin);
        const amount1 = await token1.balanceOf(pool.address,lowBin);

        expect(0).to.equal(amount0);
        expect(10000).to.equal(BigNumber.from(amount1).div(X96));
        

    });

    it("mint highBin",async function(){
        const dataEncoded = ethers.utils.defaultAbiCoder.encode(
            ['address','address','address'],
            [token0.address,token1.address,admin.address]
        );

        await manager.connect(admin).mint(
            pool.address,
            highBin,
            10000,
            dataEncoded
        );
        
        // 这里的 priceX96 是有精度差距的，因为mint里使用了内嵌的 getPriceAtBin
        const amount0 = await token0.balanceOf(pool.address,highBin);
        const amount1 = await token1.balanceOf(pool.address,highBin);
        let res0 = BigNumber.from(amount0).div(X96);
        console.log(amount0);

        const x = Math.pow(1.0001,8888888);
        expect(0).to.equal(amount1);
        
    });


});