const { assert } = require("chai");
const { BigNumber } = require("ethers");


describe("test BinMath",async function(){
    const base = 1.0001;
    const oneMillionth = BigNumber.from(2).pow(96).div(1000000);

    it("test getPriceAtBin",async function(){
        const BinMath = await ethers.getContractFactory("TestBinMath");
        const binMath = await BinMath.deploy();

        for( let i = 0 ; i <= 524288 ; i++ ){
            const bin = BigNumber.from(i).add(8388608);
            const price = await binMath.getPriceAtBin(bin);
            const Price = Math.pow(base,i)*Math.pow(2,96);
            console.log(price);
            console.log(Price);
            const measuremenError = BigNumber.from(Price.toString()).sub(price).abs();
            console.log(measuremenError);
            console.log(oneMillionth);
            let isClosed = measuremenError < oneMillionth;
            assert.isTrue(isClosed);
        }
    });
    
})