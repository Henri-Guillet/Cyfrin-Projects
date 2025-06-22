# Foundry Fund Me

This contract is based on the Cyfrin Solidity Course (https://github.com/Cyfrin/foundry-fund-me-cu)

# About

This is a minimal project allowing users to fund the contract owner with donations. The smart contract accepts ETH as donations, denominated in USD. Donations have a minimal USD value, otherwise they are rejected. The value is priced using a Chainlink price feed, and the smart contract keeps track of doners in case they are to be rewarded in the future.

- [Foundry Fund Me](#foundry-fund-me)
- [About](#about)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Deploy](#deploy)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
- [Deployment to a testnet or mainnet](#deployment-to-a-testnet-or-mainnet)
  - [Scripts](#scripts)
    - [Fund](#fund)
- [Thank you!](#thank-you)


# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`


## Quickstart

```
git clone https://github.com/Henri-Guillet/Cyfrin-Projects/tree/main/Foundry/Fundamentals/Funding
cd Funding
make install
forge build
```

# Usage

## Deploy

```
forge script script/DeployFundMe.s.sol
```

## Testing


```
forge test
```

or 

```
// Only run test functions matching the specified regex pattern.

forge test --match-test testFunctionName
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

1. Setup environment variables

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

1. Get testnet ETH

Head over to [faucets.chain.link](https://faucets.chain.link/) and get some testnet ETH. You should see the ETH show up in your metamask.

3. Deploy

On Sepolia

```
make deploy ARGS="--network sepolia"
```

or on Anvil

```
make deploy
```

## Scripts

After deploying to a testnet or local net, you can run the scripts. 

### Fund

```
make fund ARGS="--network sepolia" SENDER_ADDRESS=0xYourAddress
```

# Thank you!
