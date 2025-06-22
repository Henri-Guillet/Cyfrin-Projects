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
  - [4. Register a Chainlink Automation Upkeep](#4-register-a-chainlink-automation-upkeep)
  - [Scripts](#scripts)
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

First, create a Chainlink VRF subscription:

```bash
make createSubscription ARGS="--network sepolia"
```

This will setup a Chainlink VRF Subscription for you. If you already have one, update it in the `scripts/HelperConfig.s.sol` file. It will also automatically add your contract as a consumer.

Then deploy the contract:

```bash
make deploy ARGS="--network sepolia"
```

## 4. Register a Chainlink Automation Upkeep

[You can follow the documentation if you get lost.](https://docs.chain.link/chainlink-automation/compatible-contracts)

Go to [automation.chain.link](https://automation.chain.link/new) and register a new upkeep. Choose `Custom logic` as your trigger mechanism for automation. Your UI will look something like this once completed:

![Automation](./img/automation.png)

## Scripts

You can run the scripts to create a subscription, fund a subscription or add a consumer.

```bash
make createSubscription ARGS="--network sepolia"
```

```bash
make fundSubscription ARGS="--network sepolia"
```

```bash
make addConsumer ARGS="--network sepolia"
```

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
