const { expect } = require("chai");
const { BigNumber } = require("ethers");

describe("test Swap", function () {
    let token0;
    let token1;
    let pool;
    let manager;
    let smx;
    
    /**
     * 在ethers.js中处理大数字，特别是那些超出JavaScript安全整数范围的数字时，
     * 应该使用BigNumber库。这是因为在以太坊中，许多操作都涉及到超出JavaScript安全值范围的数字。
     * BigNumber是一个可以安全地对任意大小的数字进行数学运算的对象。
     */

    // 使用BigNumber.from来创建BigNumber对象
    const currentSqrtPrice = ethers.BigNumber.from("158456325028528675187087900672");
    const lowerSqrtPrice = ethers.BigNumber.from("5314786713428871004159001755648");
    const upperSqrtPrice = ethers.BigNumber.from("5875717789736564987741329162240");
    const currentBin = 8397125;
    const negtiveBin = 7801336;

    async function getAmount(bin){
        balance0 = await token0.balanceOf(pool.address,bin);
        balance1 = await token1.balanceOf(pool.address,bin);
        console.log();
        console.log("           bin=",bin);
        console.log("           balance0=",balance0.toString());
        console.log("           balance1=",balance1.toString());
    }
    
    it("token deploy", async function () {
        [smx] = await ethers.getSigners();
        const Token0 = await ethers.getContractFactory("ERC1155");
        token0 = await Token0.deploy("usdt","USDT");
        const Token1 = await ethers.getContractFactory("ERC1155");
        token1 = await Token1.deploy("eth","ETH");
        
        await token0.deployed();
        await token1.deployed();
        
        //console.log();
        //console.log("smx address:",smx.address);
        //console.log("token0 address:",token0.address);
        //console.log("token1 address:",token1.address);
    });

    it("pool deploy", async function () {
        // 如果库合约设置为 public ，那么需要先部署再链接
        /*
        const TickMath = await ethers.getContractFactory("TickMath");
        const tickMath = await TickMath.deploy();
        await tickMath.deployed();

        const SwapMath = await ethers.getContractFactory("SwapMath");
        const swapMath = await SwapMath.deploy();
        await swapMath.deployed();

        const Math = await ethers.getContractFactory("Math");
        const math = await Math.deploy();
        await math.deployed();
        

        // 链接TickMath库到JoeSwapPool合约
        const Pool = await ethers.getContractFactory("JoeSwapPool", {
            libraries: {
                TickMath: tickMath.address,
                SwapMath: swapMath.address,
                Math: math.address
            },
        });
        */
        
        const Pool = await ethers.getContractFactory("JoeSwapPool");
        pool = await Pool.deploy(
            token0.address,
            token1.address,
            currentSqrtPrice,
            currentBin
            );
        await pool.deployed();
        
        // const slot = await pool.slot();

    });

    it("manager deploy", async function () {
        const Manager = await ethers.getContractFactory("JoeSwapManager");
        manager = await Manager.deploy();

        await manager.deployed();
        
    });
    
    it("smx set approval for manager",async function () {
        await token0.setApprovalForAll(manager.address,true);
        await token1.setApprovalForAll(manager.address,true);
    });

    it("mint 1000000000 to smx",async function(){
        const callBackData = {
            address: token0.address,
            address: token1.address,
            address: smx.address
        }
        const encodedCallbackData = ethers.utils.defaultAbiCoder.encode(
            ['address', 'address', 'address'],
            [token0.address, token1.address, smx.address]
        );
        
        // = currentBin
        await token0._mint(
            smx.address,
            currentBin,
            1000000000,
            encodedCallbackData
        );    
        await token1._mint(
            smx.address,
            currentBin,
            1000000000,
            encodedCallbackData
        ); 
        
        // < currentBin
        await token0._mint(
            smx.address,
            currentBin-100,
            1000000000,
            encodedCallbackData
        );     
        await token1._mint(
            smx.address,
            currentBin-100,
            1000000000,
            encodedCallbackData
        );
        
        // > currentBin
        await token0._mint(
            smx.address,
            currentBin+100,
            1000000000,
            encodedCallbackData
        );     
        await token1._mint(
            smx.address,
            currentBin+100,
            1000000000,
            encodedCallbackData
        );

        // negativeBin
        await token0._mint(
            smx.address,
            negtiveBin,
            1000000000,
            encodedCallbackData
        );     
        await token1._mint(
            smx.address,
            negtiveBin,
            1000000000,
            encodedCallbackData
        );

    })
    
    it("mint to bin",async function(){
        const callBackData = {
            address: token0.address,
            address: token1.address,
            address: smx.address
        }
        const encodedCallbackData = ethers.utils.defaultAbiCoder.encode(
            ['address', 'address', 'address'],
            [token0.address, token1.address, smx.address]
        );
        
        let balance0
        let balance1
        
        //currentBin
        await manager.mint(
            pool.address,
            currentBin,
            1000000,
            encodedCallbackData
        );
        await getAmount(currentBin);
        
        // < currentBin
        await manager.mint(
            pool.address,
            currentBin-100,
            1000000,
            encodedCallbackData
        );
        await getAmount(currentBin-100);
        
        // > currentBin
        await manager.mint(
            pool.address,
            currentBin+100,
            1000000,
            encodedCallbackData
        );
        await getAmount(currentBin+100);

        // > currentBin
        await manager.mint(
            pool.address,
            negtiveBin,
            1000000,
            encodedCallbackData
        );
        await getAmount(negtiveBin);
    });
    
    
    it("test swap",async function(){
        // 挂限价单部分成交
        // const sqrtPriceLimitX96 = BigNumber.from(5).mul(BigNumber.from(2).pow(96));
        const sqrtPriceLimitX96 = BigNumber.from("189156513964411864089943343104");
        console.log("           limitPrice= ",sqrtPriceLimitX96.toString());
        // console.log("           slot= ",await pool.slot());

        // 注意到 swap 的参数是 => bytes calldata data 是字节类型，而前面的mint里是结构体类型
        const callbackData = {
            token0: token0.address,
            token1: token1.address,
            payer: smx.address
        }

        const encodedCallbackData = ethers.utils.defaultAbiCoder.encode(
            ['address', 'address', 'address'],
            [token0.address, token1.address, smx.address]
        );
    
        const amount = await pool.swap(
            pool.address,
            313355,
            sqrtPriceLimitX96,
            false,
            encodedCallbackData
        );
        console.log("           amount=",amount.value.toString());
        // console.log("           amount0=",amount0.toString());
        // console.log("           amount1=",amount1.toString());
        console.log("           slot= ",(await pool.slot()).toString());
        
    });
    
    
    
});