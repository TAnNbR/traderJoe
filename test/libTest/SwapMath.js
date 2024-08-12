const { BigNumber } = require("ethers");
const { assert } = require("chai");

describe("test SwapMath",async function(){

    const X96 = BigNumber.from(2).pow(96);
    const one = BigNumber.from(1);
    const ten = BigNumber.from(10);
    const eleven = BigNumber.from(11);
    const oneElevenX96 = one.mul(X96).div(eleven);
    const tenElevenX96 = X96.sub(oneElevenX96);


    const pX96 = BigNumber.from(5000).mul(X96);
    const L = BigNumber.from(10000);
    const cX96 = oneElevenX96;
    
    let deltaC = oneElevenX96;
    const deltaXFalse = L.mul(X96).mul(deltaC).div(pX96);
    const deltaYFalse = L.mul(X96).mul(deltaC).div(X96);

    deltaC = tenElevenX96;
    const deltaXTrue = L.mul(X96).mul(deltaC).div(pX96);
    const deltaYTrue = L.mul(X96).mul(deltaC).div(X96);

    describe("中间流出",async function(){

        beforeEach(async function(){
            // 注意作用域
            SwapMath = await ethers.getContractFactory("TestSwapMath");
            swapMath = await SwapMath.deploy();
        })
        

        //////////// 流出X ///////////////////

        let _nextP = 5500;

        it("流出x：全部（不足）",async function(){
            const amountRemain = BigNumber.from(10000).mul(X96);
            [
                nextP,
                cAfer,
                amountIn,
                amountOut
             ] = await swapMath.computeSwap(
                pX96,
                L,
                cX96,
                _nextP,
                true,
                amountRemain
            );
        
            assert.strictEqual(nextP, _nextP, 'nextP');
            assert.strictEqual(cAfer, 0, 'cAfter');
            assert.strictEqual(amountIn, deltaYTrue, 'amountIn');
            assert.strictEqual(amountOut, deltaXTrue, 'amountOut');
        
        });

        it("流出x：全部（刚好）",async function(){
            const amountRemain = deltaXTrue;
            [
                nextP,
                cAfer,
                amountIn,
                amountOut
             ] = await swapMath.computeSwap(
                pX96,
                L,
                cX96,
                _nextP,
                true,
                amountRemain
            );
            
            assert.strictEqual(nextP, _nextP, 'nextP');
            assert.strictEqual(cAfer, 0, 'cAfter');
            assert.strictEqual(amountIn, deltaYTrue, 'amountIn');
            assert.strictEqual(amountOut, deltaXTrue, 'amountOut');
        
        });

        it("流出x：部分",async function(){
            const amountRemain = tenElevenX96;
            [
                nextP,
                cAfer,
                amountIn,
                amountOut
             ] = await swapMath.computeSwap(
                pX96,
                L,
                cX96,
                _nextP,
                true,
                amountRemain
            );

            const DELTAC = amountRemain.mul(pX96).div(L.mul(X96)); // 10/11 * 5000/10000
            const CAFTER = cX96.add(DELTAC);
            const AmountIn = DELTAC.mul(L);
            
            assert.strictEqual(nextP, pX96, 'nextP');
            assert.strictEqual(cAfer, CAFTER, 'cAfter');
            assert.strictEqual(amountIn, AmountIn, 'amountIn');
            assert.strictEqual(amountOut, amountRemain, 'amountOut');
        
        });
        
        //////////// 流出Y ///////////////////

        _nextP = BigNumber.from(4500).mul(X96);

        it("流出y：全部（不足）",async function(){
            const amountRemain = BigNumber.from(1000).mul(X96);
            [
                nextP,
                cAfer,
                amountIn,
                amountOut
             ] = await swapMath.computeSwap(
                pX96,
                L,
                cX96,
                _nextP,
                false,
                amountRemain
            );
            
            assert.strictEqual(nextP, _nextP, 'nextP');
            assert.strictEqual(cAfer, X96, 'cAfter');
            assert.strictEqual(amountIn, deltaXFalse, 'amountIn');
            assert.strictEqual(amountOut, deltaYFalse, 'amountOut');
        });

        it("流出y：全部（刚好）",async function(){
            const amountRemain = deltaYFalse;
            [
                nextP,
                cAfer,
                amountIn,
                amountOut
             ] = await swapMath.computeSwap(
                pX96,
                L,
                cX96,
                _nextP,
                false,
                amountRemain
            );
            
            assert.strictEqual(nextP, _nextP, 'nextP');
            assert.strictEqual(cAfer, X96, 'cAfter');
            assert.strictEqual(amountIn, deltaXFalse, 'amountIn');
            assert.strictEqual(amountOut, deltaYFalse, 'amountOut');
            
        
        });

        it("流出y：部分",async function(){
            const amountRemain = BigNumber.from(500).mul(X96);
            [
                nextP,
                cAfer,
                amountIn,
                amountOut
             ] = await swapMath.computeSwap(
                pX96,
                L,
                cX96,
                _nextP,
                false,
                amountRemain
            );
            
            const fiveHundredOneThousand = BigNumber.from(500).mul(X96).div(10000); // 500/10000 X96
            const DELTAC = fiveHundredOneThousand;
            const CAFTER = cX96.sub(DELTAC); // 1/11 - 1/20
            const AmountIn = DELTAC.mul(L).mul(X96).div(pX96);

            assert.strictEqual(nextP, pX96, 'nextP');
            assert.strictEqual(cAfer, CAFTER, 'cAfter');
            assert.strictEqual(amountIn, AmountIn, 'amountIn');
            assert.strictEqual(amountOut, amountRemain, 'amountOut');
            
        
        });
    
    })

    describe("边缘流出",async function(){

        //////////// 流出X ///////////////////

        const pEdgeX = BigNumber.from(5500).mul(X96);
        const cEdgeX = 0;
        _nextP = BigNumber.from(6000).mul(X96);
        const deltaXEdge = L.mul(X96).div(5500);

        it("流出x：全部（刚好）",async function(){
            const amountRemain = deltaXEdge;
            [
                nextP,
                cAfer,
                amountIn,
                amountOut
             ] = await swapMath.computeSwap(
                pEdgeX,
                L,
                cEdgeX,
                _nextP,
                true,
                amountRemain
            );
            
            const AmountIn = L.mul(X96);

            assert.strictEqual(nextP, _nextP, 'nextP');
            assert.strictEqual(cAfer, 0, 'cAfter');
            assert.strictEqual(amountIn, AmountIn, 'amountIn');
            assert.strictEqual(amountOut, amountRemain, 'amountOut');
        
        });

        it("流出x：全部（不足）",async function(){
            const amountRemain = BigNumber.from(10000).mul(X96);
            [
                nextP,
                cAfer,
                amountIn,
                amountOut
             ] = await swapMath.computeSwap(
                pEdgeX,
                L,
                cEdgeX,
                _nextP,
                true,
                amountRemain
            );
            
            const AmountIn = L.mul(X96);

            assert.strictEqual(nextP, _nextP, 'nextP');
            assert.strictEqual(cAfer, 0, 'cAfter');
            assert.strictEqual(amountIn, AmountIn, 'amountIn');
            assert.strictEqual(amountOut, deltaXEdge, 'amountOut');
        
        });

        it("流出x：部分",async function(){
            const amountRemain = X96;
            [
                nextP,
                cAfer,
                amountIn,
                amountOut
             ] = await swapMath.computeSwap(
                pEdgeX,
                L,
                cEdgeX,
                _nextP,
                true,
                amountRemain
            );
            
            const CAFTER = pEdgeX.div(L);
            const AmountIn = CAFTER.mul(L);

            assert.strictEqual(nextP, pEdgeX, 'nextP');
            assert.strictEqual(cAfer, CAFTER, 'cAfter');
            assert.strictEqual(amountIn, AmountIn, 'amountIn');
            assert.strictEqual(amountOut, amountRemain, 'amountOut');
        
        });
        
        //////////// 流出Y ///////////////////

        const pEdgeY = BigNumber.from(4500).mul(X96);
        const cEdgeY = X96;
        _nextP = BigNumber.from(4300).mul(X96);

        it("流出y：全部（刚好）",async function(){
            const amountRemain = BigNumber.from(10000).mul(X96);
            [
                nextP,
                cAfer,
                amountIn,
                amountOut
             ] = await swapMath.computeSwap(
                pEdgeY,
                L,
                cEdgeY,
                _nextP,
                false,
                amountRemain
            );
            
            const AmountIn = cEdgeY.mul(L).mul(X96).div(pEdgeY);

            assert.strictEqual(nextP, _nextP, 'nextP');
            assert.strictEqual(cAfer, X96, 'cAfter');
            assert.strictEqual(amountIn, AmountIn, 'amountIn');
            assert.strictEqual(amountOut, amountRemain, 'amountOut');
        
        });

        it("流出y：全部（不足）",async function(){
            const amountRemain = BigNumber.from(11000).mul(X96);
            [
                nextP,
                cAfer,
                amountIn,
                amountOut
             ] = await swapMath.computeSwap(
                pEdgeY,
                L,
                cEdgeY,
                _nextP,
                false,
                amountRemain
            );
            
            const AmountIn = cEdgeY.mul(L).mul(X96).div(pEdgeY);

            assert.strictEqual(nextP, _nextP, 'nextP');
            assert.strictEqual(cAfer, X96, 'cAfter');
            assert.strictEqual(amountIn, AmountIn, 'amountIn');
            assert.strictEqual(amountOut, L.mul(X96), 'amountOut');
        
        });

        it("流出y：部分",async function(){
            const amountRemain = BigNumber.from(5000).mul(X96);
            [
                nextP,
                cAfer,
                amountIn,
                amountOut
             ] = await swapMath.computeSwap(
                pEdgeY,
                L,
                cEdgeY,
                _nextP,
                false,
                amountRemain
            );
            
            const CAFTER = X96.div(2);
            const AmountIn = CAFTER.mul(L).mul(X96).div(pEdgeY);

            assert.strictEqual(nextP, pEdgeY, 'nextP');
            assert.strictEqual(cAfer, CAFTER, 'cAfter');
            assert.strictEqual(amountIn, AmountIn, 'amountIn');
            assert.strictEqual(amountOut, amountRemain, 'amountOut');
        
        });
    
    })
    
})