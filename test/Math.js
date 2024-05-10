const { BigNumber } = require("ethers");

describe("test Math",async function(){
    it("test calcAmount0CurrentDelta",async function(){
        const Math = await ethers.getContractFactory("Math");
        const math = await Math.deploy();
        const half = BigNumber.from(2).pow(95);
        const two = BigNumber.from(2).pow(96);
        const amount0 = await math.calcAmount0CurrentDelta(
            10000,
            half,
            two
        );

        console.log(amount0.toString());
 
    });
})

