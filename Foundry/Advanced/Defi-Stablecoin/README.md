# Foundry Defi Stablecoin

This project is based on a section of the [Cyfrin Foundry Solidity Course](https://github.com/Cyfrin/foundry-defi-stablecoin-cu).


This repository contains a minimal, on-chain stablecoin protocol that continuously targets  
**`1 DSC = 1 USD`**.

## Key Properties

- **Exogenously collateralized** – backed **only** by external assets (WETH & WBTC).  
- **Dollar-pegged** – maintains a 1-to-1 value with the U.S. dollar.  
- **Algorithmically stabilized** – an on-chain mechanism enforces the peg with **no governance and no fees**.

> _Think of it as a stripped-down DAI: no governance tokens, no stability fees, collateral limited to WETH and WBTC._

## Collateral Safety

The system is designed to remain **over-collateralized at all times**:

\[
\text{Total Collateral Value} \;>\; \text{USD Value of All DSC in Circulation}
\]

If the collateral value ever approaches the value of outstanding DSC, automated safeguards restore the required surplus.

The contract is written in Solidity and tested using [Foundry](https://book.getfoundry.sh/).


- [Foundry Defi Stablecoin](#foundry-defi-stablecoin)
  - [Key Properties](#key-properties)
  - [Collateral Safety](#collateral-safety)
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

- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge Version: 1.2.3-stable`

## Quickstart

```
git clone https://github.com/Henri-Guillet/Cyfrin-Projects/blob/main/Foundry/Advanced/Defi-Stablecoin
cd Defi-Stablecoin
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
