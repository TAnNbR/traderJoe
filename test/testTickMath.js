const { BigNumber } = require("ethers");

describe("test TickMath",async function(){
    it("test getSqrtRatioAtTick",async function(){
        const Func = await ethers.getContractFactory("testTickMath");
        const func = await Func.deploy();

        const p1 = BigNumber.from("5602223370000000000000000000000");
        await func.getTickAtSqrtRatio(p1);
        
        
 
    });
})

