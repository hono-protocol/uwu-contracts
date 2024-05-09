import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import '@openzeppelin/hardhat-upgrades';
import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
    overrides: {
      "contracts/ccip.sol": {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      }
    }
  },
  networks: {
    arbitrumSepolia:{
      url: `https://sepolia-rollup.arbitrum.io/rpc`,
      accounts: [process.env.PRIVATE_KEY || ""],
    },
    basesepolia: {
      url: `https://sepolia.base.org`,
      accounts: [process.env.PRIVATE_KEY || ""],
    },
    sepolia: {
      url: `https://patient-fluent-spree.ethereum-sepolia.quiknode.pro/a71374e98add8eb88f55be6dc2fa039b34ed0abf/`,
      accounts: [process.env.PRIVATE_KEY || ""],
    },
    blast_sepolia: {
      url: "https://sepolia.blast.io",
      accounts: [process.env.PRIVATE_KEY || ""],
    },
    blast: {
      url: "https://rpc.blast.io",
      accounts: [process.env.PRIVATE_KEY || ""],
    },
  },
  etherscan: {
    apiKey: {
      blast_sepolia: "blast_sepolia", // apiKey is not required, just set a placeholder
      blast: "blast", // apiKey is not required, just set a placeholder
      basesepolia:"V6RE99UGKFGQCEGZ67XDPRWXYXGXUY583P",
      arbitrumSepolia: "UEZH33MMNHMBMNRK3RCXQH6IQBRCMX7H7Z",

    },
    customChains: [
      {
        network: "arbitrumSepolia",
        chainId: 421614,
        urls: {
            apiURL: "https://api-sepolia.arbiscan.io/api",
            browserURL: "https://sepolia.arbiscan.io/",
        },
      },
      {
        network: "basesepolia",
        chainId: 84532,
        urls: {
          apiURL:
            "https://api-sepolia.basescan.org/api",
          browserURL: "https://sepolia.basescan.org/",
        },
      },
      {
        network: "blast_sepolia",
        chainId: 168587773,
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/testnet/evm/168587773/etherscan",
          browserURL: "https://testnet.blastscan.io",
        },
      },
      {
        network: "blast_sepolia",
        chainId: 168587773,
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/testnet/evm/168587773/etherscan",
          browserURL: "https://testnet.blastscan.io",
        },
      },
      {
        network: "blast",
        chainId: 81457,
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/mainnet/evm/81457/etherscan",
          browserURL: "https://blastscan.io",
        },
      },
    ],
  },
  mocha: {
    timeout: 100000,
  },
};

export default config;
