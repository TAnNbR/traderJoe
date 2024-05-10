const { BigNumber } = require("ethers");

describe("test TickMath",async function(){
    it("test getSqrtRatioAtTick",async function(){
        const Func = await ethers.getContractFactory("TickMath");
        const func = await Func.deploy();
        
        const p0 = await func.getSqrtRatioAtTick(8517);
        const p1 = BigNumber.from(p0).div(BigNumber.from(2).pow(96));
        //const p2 = BigNumber.from(p1).div(BigNumber.from(2).pow(96));
        console.log(p1.toString());
 
    });
})

