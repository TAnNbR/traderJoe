require("@nomiclabs/hardhat-waffle");
require("@nomicfoundation/hardhat-foundry");

// set proxy
const { ProxyAgent, setGlobalDispatcher } = require("undici");
const proxyAgent = new ProxyAgent('http://172.31.160.1:1080'); // change to yours
setGlobalDispatcher(proxyAgent);

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
