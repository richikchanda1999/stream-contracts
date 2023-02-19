const hre = require("hardhat");
const { Framework } = require("@superfluid-finance/sdk-core");
const { ethers, providers } = require("ethers");
require("dotenv");

async function main() {

  const customHttpProvider = new ethers.providers.InfuraProvider('goerli', process.env.GOERLI_INFURA);

  const wallet = new ethers.Wallet(
    process.env.PRIVATE_KEY_OLD,
    customHttpProvider
  );

  const sf = await Framework.create({
    chainId: 5,
    networkName: "goerli",
    provider: customHttpProvider
  });

  const signer = sf.createSigner({ signer: wallet });

  const daix = await sf.loadSuperToken("fDAIx");

  const updateFlowOperation = daix.updateFlow({
    sender: "0x631088Af5A770Bee50FFA7dd5DC18994616DC1fF",
    receiver: "0xD6Bbee7c3318F51FEd7FfFc6b271DF13de76eF47", //tradeable cashflow address
    flowRate: "700000000000",
    userData: "0x04"
  });

  const txn = await updateFlowOperation.exec(signer);

  const receipt = await txn.wait();

  console.log(receipt);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });