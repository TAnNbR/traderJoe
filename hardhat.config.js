require("@nomiclabs/hardhat-waffle");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      viaIR: true,
      optimizer: {
       enabled: true,
       runs: 200,
       details: {
        yulDetails: {
           optimizerSteps: "u",
        },
       },
      },
     },
    }
};
