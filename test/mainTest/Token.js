const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

describe("test Token",async function(){
    const bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
    const uri = "xxx/xxx/xxx.json";
    const data = "0x123456";
    let token;
    let admin;

    // 这里不能使用异步操作

    beforeEach(async function(){
        // 注意作用域
        [admin] = await ethers.getSigners();
        const Token = await ethers.getContractFactory("Token");
        token = await Token.deploy(uri);
    });

    it("test recharge",async function(){
        await token.connect(admin).recharge(bin,10000,data);
        const amount0 = await token.balanceOf(admin.address,bin);
        expect(amount0).to.equal(10000);
    });

    it("test rechargeBatch",async function(){  
        const bins = [bin,bin.add(10)];
        const amounts = [10000,20000];
        await token.connect(admin).rechargeBatch(bins,amounts,data);
        const amount0 = await token.balanceOf(admin.address,bin);
        const amount1 = await token.balanceOf(admin.address,bin.add(10));
        expect(amount0).to.equal(10000);
        expect(amount1).to.equal(20000);

    });

    
})