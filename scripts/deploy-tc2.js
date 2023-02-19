// require("@nomiclabs/hardhat-ethers")
const hre = require("hardhat");

async function main() {

    const TC = await hre.ethers.getContractFactory("NFTCollection2");
    const NFT = await TC.deploy();
    await NFT.deployed();

    console.log(NFT.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });