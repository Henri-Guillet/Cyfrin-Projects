# Foundry Smart Contract Lottery

This project is based on a section of the [Cyfrin Foundry Solidity Course](https://github.com/Cyfrin/foundry-smart-contract-lottery-cu).

It implements a decentralized lottery system using:

- **Chainlink VRF** (Verifiable Random Function) to select a truly random winner.
- **Chainlink Automation** to automatically trigger the winner selection and prize distribution once the lottery conditions are met.

The contract is written in Solidity and tested using [Foundry](https://book.getfoundry.sh/).


- [Foundry Smart Contract Lottery](#foundry-smart-contract-lottery)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Start a local node](#start-a-local-node)
  - [Deploy](#deploy)
  - [Deploy - Other Network](#deploy---other-network)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
- [Deployment to a testnet or mainnet](#deployment-to-a-testnet-or-mainnet)
  - [1. Setup environment variables](#1-setup-environment-variables)
  - [2. Get testnet ETH](#2-get-testnet-eth)
  - [3. Deploy](#3-deploy)
  - [Interactions](#interactions)
  - [Estimate gas](#estimate-gas)
- [Formatting](#formatting)
- [Thank you!](#thank-you)

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge Version: 1.2.3-stable`

## Quickstart

```
git clone https://github.com/Henri-Guillet/Cyfrin-Projects/tree/main/Foundry/Fundamentals/Lottery
cd Lottery
make install
forge build
```

# Usage

## Start a local node

```
make anvil
```

## Deploy

This will default to your local node. You need to have it running in another terminal in order for it to deploy.

```
make deploy
```

## Deploy - Other Network

[See below](#deployment-to-a-testnet-or-mainnet)

## Testing

```
forge test
```

or

```
forge test --fork-url http://127.0.0.1:8545
```

or

```
forge test --fork-url $SEPOLIA_RPC_URL
```

### Test Coverage

```
forge coverage
```

# Deployment to a testnet or mainnet

## 1. Setup environment variables

You need to set the following environment variables in a `.env` file (you can use `.env.example` as a template):

```env
SEPOLIA_RPC_URL=your_rpc_url
ETHERSCAN_API_KEY=your_etherscan_key
```

Use the following command to securely import your private key into Foundry:

```bash
cast wallet import <keyName> --interactive
```

Then update your Makefile to use the corresponding key name instead of pk_dev1.

Make sure to update the account field in `scripts/HelperConfig.s.sol` to match your actual deployer address.

## 2. Get testnet ETH

Head over to [faucets.chain.link](https://faucets.chain.link/) and get some testnet ETH. You should see the ETH show up in your metamask.

## 3. Deploy

Deploy the contract on Sepolia testnet:

```bash
make deploy ARGS="--network sepolia"
```

## Interactions

You will need to deposit testnet ETH to the [WETH contract](https://sepolia.etherscan.io/address/0xdd13E55209Fd76AfE204dBda4007C227904f0a81)

## Estimate gas

You can estimate how much gas things cost by running:

```bash
forge snapshot
```

And you'll see an output file called `.gas-snapshot`

# Formatting

To run code formatting:

```
forge fmt
```

# Thank you!
