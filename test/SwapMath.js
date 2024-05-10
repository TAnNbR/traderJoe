const {expect}=require("chai");
const {BigNumber}=require("ethers");

//测试前要改成public
describe("test SwapMath",function(){
    let swapMath;
    let nextPrice,compositionAfter,amount0,amount1;
    let composition;
    let amountRemain;

    const exponent = 96;
    const one = BigNumber.from(1);
    const eleven = BigNumber.from(11);
    const oneElevenX96 = one.mul(BigNumber.from(2).pow(exponent)).div(eleven);
    
    const oneX96 = BigNumber.from(1).mul(BigNumber.from(2).pow(exponent));
    const fiveX96 = BigNumber.from(5).mul(BigNumber.from(2).pow(exponent));
    const tenX96 = BigNumber.from(10).mul(BigNumber.from(2).pow(exponent));
    const fiftyX96 = BigNumber.from(50).mul(BigNumber.from(2).pow(exponent));
    const oneHundredX96 = BigNumber.from(100).mul(BigNumber.from(2).pow(exponent));
    const fiveHundredX96 = BigNumber.from(500).mul(BigNumber.from(2).pow(exponent));
    const tenThousandX96 = BigNumber.from(10000).mul(BigNumber.from(2).pow(exponent));

    beforeEach(async function () {
        const SwapMath = await ethers.getContractFactory("SwapMath");
        swapMath = await SwapMath.deploy();
    });

    it("test in the middle,composition between 0 and 1",async function(){
        console.log("---------------------------------------------");
        console.log("price = 10 | composition = 1 / 11 or 0 | L = 110");
        console.log("---------------------------------------------");
        console.log(); 
        console.log("流出x，全部");
        //ethers.BigNumber.from()放在函数里用会报错

        composition=oneElevenX96;
        amountRemain=oneHundredX96;
        [nextPrice,compositionAfter,amount0,amount1] = await swapMath.computeSwap(
            10,
            110,
            composition,
            15,
            false,
            amountRemain
        );
        amount0 = amount0.div(ethers.BigNumber.from(2).pow(exponent));
        amount1 = amount1.div(ethers.BigNumber.from(2).pow(exponent));
        console.log("nextPrice=",nextPrice.toString());
        console.log("compositionAfter=",compositionAfter.toString());
        console.log("amountIn=",amount0.toString());
        console.log("amountOut=",amount1.toString());
       
        /*
        composition=oneElevenX96;
        amountRemain=tenX96;
        [nextPrice,compositionAfter,amount0,amount1] = await swapMath.computeSwap(
            10,
            110,
            composition,
            15,
            false,
            amountRemain
        );
        amount0 = amount0.div(ethers.BigNumber.from(2).pow(exponent));
        amount1 = amount1.div(ethers.BigNumber.from(2).pow(exponent));
        console.log("nextPrice=",nextPrice);
        console.log("compositionAfter=",compositionAfter);
        console.log("amountIn=",amount0);
        console.log("amountOut=",amount1);
        console.log();
        */
        /*
        console.log("流出y");
        composition=oneElevenX96;
        amountRemain=oneHundredX96;
        [nextPrice,compositionAfter,amount0,amount1] = await swapMath.computeSwap(
            10,
            110,
            composition,
            5,
            true,
            amountRemain
        );
        amount0 = amount0.div(ethers.BigNumber.from(2).pow(exponent));
        amount1 = amount1.div(ethers.BigNumber.from(2).pow(exponent));
        console.log("nextPrice=",nextPrice);
        console.log("compositionAfter=",compositionAfter);
        console.log("amountIn=",amount0);
        console.log("amountOut=",amount1);
        console.log();
        */
    });

    it("test in the edge,composition = 0",async function(){
        console.log();
        console.log("流出x，全部");
        composition=0;
        amountRemain=oneHundredX96;
        [nextPrice,compositionAfter,amount0,amount1] = await swapMath.computeSwap(
            10,
            110,
            composition,
            15,
            false,
            amountRemain
        );
        amount0 = amount0.div(ethers.BigNumber.from(2).pow(exponent));
        amount1 = amount1.div(ethers.BigNumber.from(2).pow(exponent));
        console.log("nextPrice=",nextPrice.toString());
        console.log("compositionAfter=",compositionAfter.toString());
        console.log("amountIn=",amount0.toString());
        console.log("amountOut=",amount1.toString());
    });

    it("test in the middle,composition between 0 and 1",async function(){
        console.log();
        console.log("流出x，部分");
        composition=oneElevenX96;
        amountRemain=fiveX96;
        [nextPrice,compositionAfter,amount0,amount1] = await swapMath.computeSwap(
            10,
            110,
            composition,
            15,
            false,
            amountRemain
        );
        amount0 = amount0.div(ethers.BigNumber.from(2).pow(exponent));
        amount1 = amount1.div(ethers.BigNumber.from(2).pow(exponent));
        console.log("nextPrice=",nextPrice.toString());
        console.log("compositionAfter=",compositionAfter.toString());
        console.log("amountIn=",amount0.toString());
        console.log("amountOut=",amount1.toString());
    });

    it("test in the edge,composition = 0",async function(){
        console.log();
        console.log("流出x，部分");
        composition=0;
        amountRemain=fiveX96;
        [nextPrice,compositionAfter,amount0,amount1] = await swapMath.computeSwap(
            10,
            110,
            composition,
            15,
            false,
            amountRemain
        );
        amount0 = amount0.div(ethers.BigNumber.from(2).pow(exponent));
        amount1 = amount1.div(ethers.BigNumber.from(2).pow(exponent));
        console.log("nextPrice=",nextPrice.toString());
        console.log("compositionAfter=",compositionAfter.toString());
        console.log("amountIn=",amount0.toString());
        console.log("amountOut=",amount1.toString());
    });

    it("test in the middle,composition between 0 and 1",async function(){
        console.log();
        console.log("---------------------------------------------");
        console.log("price = 10 | composition = 1 / 11 or 1 | L = 1100");
        console.log("(这里存在精度损失，所以L放大10倍)");
        console.log("---------------------------------------------");

        console.log();
        console.log("流出y，全部");
        composition=oneElevenX96;
        amountRemain=tenThousandX96;
        [nextPrice,compositionAfter,amount0,amount1] = await swapMath.computeSwap(
            10,
            1100,
            composition,
            5,
            true,
            amountRemain
        );
        amount0 = amount0.div(ethers.BigNumber.from(2).pow(exponent));
        amount1 = amount1.div(ethers.BigNumber.from(2).pow(exponent));
        console.log("nextPrice=",nextPrice.toString());
        console.log("compositionAfter=",compositionAfter.toString());
        console.log("amountIn=",amount0.toString());
        console.log("amountOut=",amount1.toString());
    });

    it("test in the edge,composition = 1",async function(){
        console.log();
        console.log("流出y，全部");
        composition=oneX96;
        amountRemain=tenThousandX96;
        [nextPrice,compositionAfter,amount0,amount1] = await swapMath.computeSwap(
            10,
            1100,
            composition,
            5,
            true,
            amountRemain
        );
        amount0 = amount0.div(ethers.BigNumber.from(2).pow(exponent));
        amount1 = amount1.div(ethers.BigNumber.from(2).pow(exponent));
        console.log("nextPrice=",nextPrice.toString());
        console.log("compositionAfter=",compositionAfter.toString());
        console.log("amountIn=",amount0.toString());
        console.log("amountOut=",amount1.toString());
    });

    it("test in the middle,composition between 0 and 1",async function(){
        console.log();
        console.log("流出y，部分");
        composition=oneElevenX96;
        amountRemain=fiftyX96;
        [nextPrice,compositionAfter,amount0,amount1] = await swapMath.computeSwap(
            10,
            1100,
            composition,
            5,
            true,
            amountRemain
        );
        amount0 = amount0.div(ethers.BigNumber.from(2).pow(exponent));
        amount1 = amount1.div(ethers.BigNumber.from(2).pow(exponent));
        console.log("nextPrice=",nextPrice.toString());
        console.log("compositionAfter=",compositionAfter.toString());
        console.log("amountIn=",amount0.toString());
        console.log("amountOut=",amount1.toString());
    });

    it("test in the edge,composition = 1",async function(){
        console.log();
        console.log("流出y，部分");
        composition=oneX96;
        amountRemain=fiveHundredX96;
        [nextPrice,compositionAfter,amount0,amount1] = await swapMath.computeSwap(
            10,
            1100,
            composition,
            5,
            true,
            amountRemain
        );
        amount0 = amount0.div(ethers.BigNumber.from(2).pow(exponent));
        amount1 = amount1.div(ethers.BigNumber.from(2).pow(exponent));
        console.log("nextPrice=",nextPrice.toString());
        console.log("compositionAfter=",compositionAfter.toString());
        console.log("amountIn=",amount0.toString());
        console.log("amountOut=",amount1.toString());
    });

});