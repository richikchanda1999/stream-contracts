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

  console.log(sf.settings.config);
  console.log(resolver.get('supertokens.v1.DAIx'));

  const signer = sf.createSigner({ signer: wallet });

  const daix = await sf.loadSuperToken("fUSDCx");

  const createFlowOperation = await daix.createFlow({
      receiver: "0xCE15F6450f122210efA2f8c9370DFF30C7016C52", //tradeable cashflow address
      flowRate: "100000000000"
  });

  const txn = await createFlowOperation.exec(signer);

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
