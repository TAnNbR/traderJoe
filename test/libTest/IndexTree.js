const { BigNumber } = require("ethers");
const {expect}=require("chai");

describe("Test Tree",async function(){
    it("test flipBin",async function(){
        const TestIndexTree = await ethers.getContractFactory("TestIndexTree");
        const testtree = await TestIndexTree.deploy();
        
        let bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(85170).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(8517).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);       
    });

    it("testFindSmallBin : third",async function(){
        const TestIndexTree = await ethers.getContractFactory("TestIndexTree");
        const testtree = await TestIndexTree.deploy();
        
        let bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(85170).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.findsmallbin(bin); // 84991

    });

    it("testFindSmallBin : second",async function(){
        const TestIndexTree = await ethers.getContractFactory("TestIndexTree");
        const testtree = await TestIndexTree.deploy();
        
        let bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(84991).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.findsmallbin(bin); // 84991

    });

    it("testFindSmallBin : first",async function(){
        const TestIndexTree = await ethers.getContractFactory("TestIndexTree");
        const testtree = await TestIndexTree.deploy();
        
        let bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(8517).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.findsmallbin(bin); // 84991

    });

    it("testFindSmallBin : none",async function(){
        const TestIndexTree = await ethers.getContractFactory("TestIndexTree");
        const testtree = await TestIndexTree.deploy();
        
        let bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.findsmallbin(bin); 

    });

    it("testFindBigBin : third",async function(){
        const TestIndexTree = await ethers.getContractFactory("TestIndexTree");
        const testtree = await TestIndexTree.deploy();
        
        let bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(85196).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.findbigbin(bin); 

    });

    it("testFindBigBin : second",async function(){
        const TestIndexTree = await ethers.getContractFactory("TestIndexTree");
        const testtree = await TestIndexTree.deploy();
        
        let bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(85376).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.findbigbin(bin); // 84991

    });

    it("testFindBigBin : first",async function(){
        const TestIndexTree = await ethers.getContractFactory("TestIndexTree");
        const testtree = await TestIndexTree.deploy();
        
        let bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(185176).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.findbigbin(bin); // 84991

    });

    it("testFindBigBin : none",async function(){
        const TestIndexTree = await ethers.getContractFactory("TestIndexTree");
        const testtree = await TestIndexTree.deploy();
        
        let bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.flipbin(bin);

        bin = BigNumber.from(85176).add(BigNumber.from(2).pow(23));
        await testtree.findbigbin(bin); 

    });

})

