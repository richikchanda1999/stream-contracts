// require("@nomiclabs/hardhat-ethers")
const hre = require("hardhat");

//goerli addresses - change if using a different network
const host = "0x22ff293e14F1EC3A09B137e9e06084AFd63adDF9"
const cfav1 = "0xEd6BcbF6907D4feEEe8a8875543249bEa9D308E8"
const fDAIx = "0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00"
const owner = "0x631088Af5A770Bee50FFA7dd5DC18994616DC1fF"

//to deploy, run yarn hardhat deploy --network goerli

async function main() {
    const deployer = 0;
    const TC = await hre.ethers.getContractFactory("TradeableCashflow1");

    const NFT = await TC.deploy(host, cfav1, fDAIx)

    await NFT.deployed();

    console.log(NFT.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });