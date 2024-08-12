const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
const { expect } = require("chai");

/**
 * @dev swap测试逻辑：
 * 先 mint 再 swap
 */

describe("test swap",async function(){
    let token0,token1,admin,manager,pool;

    const X96 = BigNumber.from(2).pow(96);
    const halfX96 = BigNumber.from(2).pow(95);
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

    it("mint",async function(){
        const dataEncoded = ethers.utils.defaultAbiCoder.encode(
            ['address','address','address'],
            [token0.address,token1.address,admin.address]
        );

        let amount0,amount1;

        await manager.connect(admin).mint(
            pool.address,
            bin,
            10000,
            dataEncoded
        );
        amount0 = await token0.balanceOf(pool.address,bin);
        amount1 = await token1.balanceOf(pool.address,bin);
        expect(1).to.equal(BigNumber.from(amount0).div(X96));
        expect(5000).to.equal(BigNumber.from(amount1).div(X96));

        await manager.connect(admin).mint(
            pool.address,
            lowBin,
            10000,
            dataEncoded
        );
        amount0 = await token0.balanceOf(pool.address,lowBin);
        amount1 = await token1.balanceOf(pool.address,lowBin);
        expect(0).to.equal(amount0);
        expect(10000).to.equal(BigNumber.from(amount1).div(X96));

        await manager.connect(admin).mint(
            pool.address,
            highBin,
            10000,
            dataEncoded
        );
        amount0 = await token0.balanceOf(pool.address,highBin);
        amount1 = await token1.balanceOf(pool.address,highBin);
        amount0 = divRoundingUp(amount0);
        expect(2).to.equal(amount0);
        expect(0).to.equal(amount1);
        
    });

    it("swap",async function(){
        const dataEncoded = ethers.utils.defaultAbiCoder.encode(
            ['address','address','address'],
            [token0.address,token1.address,admin.address]
        );
        
        const limitPrice = BigNumber.from("397085082898270348268193359383199"); // 85200

        await manager.swap(
            pool.address,
            halfX96,
            limitPrice,
            true,
            dataEncoded
        );
        //await printBalance();
    });

    it("swap",async function(){
        const dataEncoded = ethers.utils.defaultAbiCoder.encode(
            ['address','address','address'],
            [token0.address,token1.address,admin.address]
        );
        
        const limitPrice = BigNumber.from("397085082898270348268193359383199"); // 85200
        manager.on("CAO",(price)=>{console.log("i am free!!!!!!!!!!!!");});
        await manager.swap(
            pool.address,
            X96,
            limitPrice,
            true,
            dataEncoded
        );
        //await printBalance();
    });

    async function printBalance(){
        console.log("pool's x:",lowBin.toString(),"is",await token0.balanceOf(pool.address,lowBin));
        console.log("pool's x:",bin.toString(),"is",await token0.balanceOf(pool.address,bin));
        console.log("pool's x:",highBin.toString(),"is",await token0.balanceOf(pool.address,highBin));
        console.log("pool's y:",lowBin.toString(),"is",await token1.balanceOf(pool.address,lowBin));
        console.log("pool's y:",bin.toString(),"is",await token1.balanceOf(pool.address,bin));
        console.log("pool's y:",highBin.toString(),"is",await token1.balanceOf(pool.address,highBin));
        console.log("admin's x:",lowBin.toString(),"is",await token0.balanceOf(admin.address,lowBin));
        console.log("admin's x:",bin.toString(),"is",await token0.balanceOf(admin.address,bin));
        console.log("admin's x:",highBin.toString(),"is",await token0.balanceOf(admin.address,highBin));
        console.log("admin's y:",lowBin.toString(),"is",await token1.balanceOf(admin.address,lowBin));
        console.log("admin's y:",bin.toString(),"is",await token1.balanceOf(admin.address,bin));
        console.log("admin's y:",highBin.toString(),"is",await token1.balanceOf(admin.address,highBin));
    }

    function divRoundingUp(x){
        if(x.mod(halfX96)>0){
            x = x.div(X96);
            x ++;
        }
        return x; 
    }

});