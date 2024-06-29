const { BigNumber } = require("ethers");

describe("test BitMath",async function(){
    it("test mostBit",async function(){
        const Func = await ethers.getContractFactory("Newbitmath");
        const func = await Func.deploy();

        const p1 = BigNumber.from(2).pow(226);
        const p2 = BigNumber.from(2).pow(157);
        const p3 = BigNumber.from(2).pow(66);
        //const p4 = BigNumber.from(1);
        const p = p1.add(p2).add(p3);
        //await func.mostSignificantBit(p4);
        
        await func.leastSignificantBit(p);
 
    });
})

