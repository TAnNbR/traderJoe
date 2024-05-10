const { BigNumber } = require("ethers");

const exponent = 96;

const one = BigNumber.from(1);
const eleven = BigNumber.from(11);
const ten = BigNumber.from(10).mul(BigNumber.from(2).pow(exponent));
const oneElevenX96 = one.mul(BigNumber.from(2).pow(exponent)).div(eleven);
const x = BigNumber.from(2).pow(128);
const half = BigNumber.from(2).pow(95)
const nineSeven = BigNumber.from(2).pow(97);

console.log("1/11=",oneElevenX96.toString()); // 输出结果
console.log("10=",ten.toString());
console.log("2^128=",x.toString());
console.log("2^97=",nineSeven.toString());