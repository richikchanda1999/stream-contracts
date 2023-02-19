const hre = require("hardhat");
const { Framework } = require("@superfluid-finance/sdk-core");
const { ethers, providers } = require("ethers");
require("dotenv");

async function main() {

  // const customHttpProvider = new ethers.providers.JsonRpcProvider(process.env.GOERLI_URL);
  // const customHttpProvider = new ethers.providers.AlchemyProvider('goerli', process.env.GOERLI_URL);
  const customHttpProvider = new ethers.providers.InfuraProvider('goerli', process.env.GOERLI_INFURA);

  const wallet = new ethers.Wallet(
    process.env.PRIVATE_KEY,
    customHttpProvider
  );

  const sf = await Framework.create({
    chainId: 5,
    networkName: "goerli",
    provider: customHttpProvider
  });

  // console.log(sf.settings.config);
  // console.log(resolver.get('supertokens.v1.DAIx'));

  const signer = sf.createSigner({ signer: wallet });
  // const signer = customHttpProvider.getSigner();

  // console.log(signer);

  const daix = await sf.loadSuperToken("fDAIx");

  console.log("Test print")

  const createFlowOperation = await daix.createFlow({
      sender: "0x039b882C4aF8Dc66c906dA6a44c6e2A561BB5223",
      receiver: "0xD6Bbee7c3318F51FEd7FfFc6b271DF13de76eF47", //tradeable cashflow address
      flowRate: "20000000000",
      userData: "0x01"
  });

  console.log("Test 2")

  const txn = await createFlowOperation.exec(signer);

  console.log("Test 3")

  const receipt = await txn.wait();

  console.log("Test 4")

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
