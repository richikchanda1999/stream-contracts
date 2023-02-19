// require("@nomiclabs/hardhat-ethers")
const hre = require("hardhat");

// goerli addresses - change if using a different network
// const host = "0x22ff293e14F1EC3A09B137e9e06084AFd63adDF9"
// const cfav1 = "0xEd6BcbF6907D4feEEe8a8875543249bEa9D308E8"
// const fDAIx = "0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00"

// mumbai addresses - change if using a different network
const host = "0xEB796bdb90fFA0f28255275e16936D25d3418603"
const cfav1 = "0x49e565Ed1bdc17F3d220f72DF0857C26FA83F873"
const fDAIx = "0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f"

async function main() {
    const TC = await hre.ethers.getContractFactory("NFTCollection1");

    console.log("Deploying now!");
    
    const NFT = await TC.deploy(host, cfav1, fDAIx);
    await NFT.deployed();

    console.log(NFT.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });