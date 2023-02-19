import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "hardhat-deploy";
import "solidity-coverage";

dotenv.config();
const GAS_LIMIT = 10000000;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
        optimizer: {
            enabled: true
        }
    }
  },
  networks: {
    goerli: {
      url: process.env.GOERLI_URL,
      accounts: [process.env.PRIVATE_KEY],
      gas: GAS_LIMIT,
      gasPrice: 11e9, // 10 GWEI
    },
    hardhat: {
      gas: 50000000000
    },
    mantle_testnet: {
      url: process.env.MANTLE_RPC,
      accounts: [process.env.PRIVATE_KEY],
      gas: GAS_LIMIT,
      gasPrice: 11e9, // 10 GWEI
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  namedAccounts: {
    deployer: 0
  },
};

export default config;
