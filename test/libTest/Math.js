const { BigNumber } = require("ethers");
const { expect } = require("chai");

describe("test Math",async function(){

    const exponent = 96;
    const X96 = BigNumber.from(2).pow(exponent);
    const halfX96 = X96.div(2);

    const one = BigNumber.from(1);
    const eleven = BigNumber.from(11);
    const oneElevenX96 = one.mul(X96).div(eleven);
    
    beforeEach(async function(){
        const Testmath = await ethers.getContractFactory("TestMath");
        testmath = await Testmath.deploy();
    });
    
    ///////////////////////////////////////
    // Mint : deltaL=10000 P=5000 C=1/11 //
    ///////////////////////////////////////
    
    it("test calcAmount0Active",async function(){
        const deltaL = 10000;
        const composition = oneElevenX96;
        const price = BigNumber.from("396133268922838611395008645278033"); // tick = 85176
        const res = await testmath.calcAmount0Active(
            deltaL,
            composition,// X96
            price       // X96
        );
        const RES = BigNumber.from(deltaL).mul(X96).mul(X96.sub(composition)).div(price);
        expect(res).to.equal(RES);
    });

    it("test calcAmount1Active",async function(){
        const deltaL = 10000;
        const composition = oneElevenX96;
        const res = await testmath.calcAmount1Active(
            deltaL,
            composition,// X96
        );
        const RES = BigNumber.from(deltaL).mul(composition);
        expect(res).to.equal(RES);
    });

    it("test calcAmount0Inactive",async function(){
        const deltaL = 10000;
        const price = BigNumber.from("396133268922838611395008645278033"); // tick = 85176
        const res = await testmath.calcAmount0Inactive(
            deltaL,
            price,// X96
        );
        const RES = BigNumber.from(deltaL).mul(X96).mul(X96).div(price);
        expect(res).to.equal(RES);
    });

    it("test calcAmount1Inactive",async function(){
        const deltaL = 10000;
        const res = await testmath.calcAmount1Inactive(
            deltaL,
        );
        const RES = BigNumber.from(deltaL).mul(X96);
        expect(res).to.equal(RES);
    });

    ///////////////////////////////////////////////////////////
    // Swap : P=5000 L=10000 deltaX=1 deltaY=5000 deltaC=0.5 //
    ///////////////////////////////////////////////////////////
    
    // L = p*x + y => 10000 = 5000*1 + 5000
    it("test calcCompositionAtAmount0",async function(){
        const price = BigNumber.from("396133268922838611395008645278033"); // tick = 85176
        const L = 10000;
        const deltaX = X96;
        const res = await testmath.calcCompositionAtAmount0(
            price,// X96
            L,    // X96
            deltaX
        );
        const RES = price.mul(deltaX).div(BigNumber.from(L).mul(X96));
        expect(res).to.equal(RES);
    });

    it("test calcCompositionAtAmount1",async function(){
        const L = 10000;
        const deltaY = BigNumber.from(5000).mul(X96);
        const res = await testmath.calcCompositionAtAmount1(
            L,    
            deltaY // X96
        );
        const RES = deltaY.mul(X96).div(BigNumber.from(L).mul(X96));
        expect(res).to.equal(RES);
    });

    it("test calcAmount0",async function(){
        const L = 10000;
        const deltaC = halfX96;
        const price = BigNumber.from("396133268922838611395008645278033"); // tick = 85176
        const res = await testmath.calcAmount0(
            L,    
            deltaC, // X96
            price   // X96
        );
        const RES = BigNumber.from(L).mul(X96).mul(deltaC).div(price);
        expect(res).to.equal(RES);
    });

    it("test calcAmount1",async function(){
        const L = 10000;
        const deltaC = halfX96;
        const res = await testmath.calcAmount1(
            L,    
            deltaC, // X96
        );
        const RES = BigNumber.from(L).mul(X96).mul(deltaC).div(X96);
        expect(res).to.equal(RES);
    });


})

