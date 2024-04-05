import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const { API_KEY, MAINNET_RPC_URL, SEPOLIA_RPC_URL, PRIVATE_KEY } = process.env;

const config: HardhatUserConfig = {
  solidity: "0.8.24",

  etherscan: {
    apiKey: API_KEY,
  },
  networks: {
    hardhat: {
      forking: {
        url: MAINNET_RPC_URL !== undefined ? MAINNET_RPC_URL : "",
        enabled: false, // changes to true if you want to run a hardhat in the fork network
      },
    },
    sepolia: {
      url: SEPOLIA_RPC_URL !== undefined ? SEPOLIA_RPC_URL : "",
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      chainId: 11155111,
    },
  },
  sourcify: {
    enabled: true,
  },
};

export default config;
