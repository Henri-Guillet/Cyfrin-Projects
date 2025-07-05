# Foundry CCIP rebase token

This project is based on a section of the [Cyfrin Foundry Solidity Course](https://github.com/Cyfrin/foundry-cross-chain-rebase-token-cu).

A minimal **cross-chain rebase token** that communicates through **Chainlink CCIP** and rewards users who deposit into an on-chain vault.

## Key Features

- **Chainlink CCIP Powered**  
  Seamless rebase and state synchronisation between supported chains via Chainlink’s Cross-Chain Interoperability Protocol.

- **Vault-Based Yield**  
  Users earn rewards by depositing their tokens into the protocol’s vault; the token supply rebases to reflect accrued interest.

- **Monotonic Interest Rate**  
   The global interest rate is **non-increasing**—it can only move downward over time, never up.

The contract is written in Solidity and tested using [Foundry](https://book.getfoundry.sh/).


- [Foundry CCIP rebase token](#foundry-ccip-rebase-token)
  - [Key Features](#key-features)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
- [Deployment to a testnet or mainnet](#deployment-to-a-testnet-or-mainnet)
  - [1. Setup environment variables](#1-setup-environment-variables)
  - [2. Get testnet ETH](#2-get-testnet-eth)
  - [3. Deploy](#3-deploy)
  - [Interacting with the Protocol](#interacting-with-the-protocol)
    - [Interactions.s.sol](#interactionsssol)
    - [BridgeTokens.s.sol](#bridgetokensssol)
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
git clone https://github.com/Henri-Guillet/Cyfrin-Projects/blob/main/Foundry/Advanced/CCIP-rebase-token
cd CCIP-rebase-token
make install
forge build
```

## Testing

```
forge test
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
ARB_SEPOLIA_RPC_URL=your_arbitrum_sepolia_rpc_url
ETHERSCAN_API_KEY=your_etherscan_key
```

Use the following command to securely import your private key into Foundry:

```bash
cast wallet import <keyName> --interactive
```

## 2. Get testnet ETH

Head over to [faucets.chain.link](https://faucets.chain.link/) and get some testnet ETH on EThereum Sepolia and ARbitrum Sepolia. You should see the ETH show up in your metamask.

## 3. Deploy

1. **Configure your account**  
   Open `setUpProject.sh` and replace the placeholders for the account name and sender address with your own Foundry account details.

2. **Run the deployment script**  
   The script will:  
   - Deploy the Rebase Token on *Ethereum Sepolia* and *Arbitrum Sepolia*.  
   - Deploy the Vault.  
   - Configure the CCIP pools that connect the two chains.

```bash
bash setUpProject.sh
```

## Interacting with the Protocol

You can interact with the protocol through the following scripts:

### Interactions.s.sol
- **DepositScript**: Deposits funds (0.01 ETH) into the vault to earn rewards
- **RedeemScript**: Redeems all available funds from the vault

### BridgeTokens.s.sol
- **BridgeTokensScript**: Bridges tokens between chains using Chainlink CCIP

Example usage:
```bash
# Deposit funds to vault
forge script script/Interactions.s.sol:DepositScript --rpc-url $SEPOLIA_RPC_URL --account <keyName> --sender <your_address> --broadcast --sig "run(address)" <vault_address>

# Redeem funds from vault
forge script script/Interactions.s.sol:RedeemScript --rpc-url $SEPOLIA_RPC_URL --account <keyName> --sender <your_address> --broadcast --sig "run(address)" <vault_address>

# Bridge tokens between chains
forge script script/BridgeTokens.s.sol:BridgeTokensScript --rpc-url $SEPOLIA_RPC_URL --account <keyName> --sender <your_address> --broadcast --sig "run(address,uint64,address,uint256,address,address)" <receiver_address> <destination_chain_selector> <token_address> <amount> <link_token_address> <router_address>
```

**Parameters:**
- `vault_address`: Address of the deployed vault contract
- `receiver_address`: Address to receive tokens on the destination chain
- `destination_chain_selector`: CCIP chain selector for the target chain
- `token_address`: Address of the token to bridge
- `amount`: Amount of tokens to bridge
- `link_token_address`: Address of the LINK token for paying CCIP fees
- `router_address`: Address of the CCIP router contract

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
