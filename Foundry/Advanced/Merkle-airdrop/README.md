# Foundry Airdrop claiming project

This project is based on a section of the [Cyfrin Foundry Solidity Course](https://github.com/Cyfrin/foundry-merkle-airdrop-cu).

This Foundry project lets whitelisted users redeem their share of a Bagel-token ERC-20 airdrop.
Eligibility is verified on-chain via a Merkle tree, and each claim is authorized by an EIP-191 / EIP-712 signature.

The contract is written in Solidity and tested using [Foundry](https://book.getfoundry.sh/).


- [Foundry Airdrop claiming project](#foundry-airdrop-claiming-project)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Generate merkle proofs](#generate-merkle-proofs)
  - [Deploy to Anvil](#deploy-to-anvil)
  - [Interacting - Local anvil network](#interacting---local-anvil-network)
    - [Sign your airdrop claim](#sign-your-airdrop-claim)
    - [Claim your airdrop](#claim-your-airdrop)
    - [Check claim amount](#check-claim-amount)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
  - [Estimate gas](#estimate-gas)
- [Formatting](#formatting)
- [Thank you!](#thank-you)

# Getting Started

## Requirements

- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge Version: 1.2.3-stable`

## Quickstart

```
git clone https://github.com/Henri-Guillet/Cyfrin-Projects/blob/main/Foundry/Advanced/Merkle-airdrop
cd Merkle-airdrop
forge install
forge build
```

# Usage

## Generate merkle proofs

We are going to generate merkle proofs for an array of addresses to airdrop funds to. If you'd like to work with the default addresses and proofs already created in this repo, skip to deploy

If you'd like to work with a different array of addresses (the whitelist list in GenerateInput.s.sol), you will need to follow the following:

First, the array of addresses to airdrop to needs to be updated in `GenerateInput.s.sol. To generate the input file and then the merkle root and proofs, run the following:

Using make:

```
make merkle
```

Then, retrieve the root (there may be more than 1, but they will all be the same) from script/target/output.json and update ROOT in DeployMerkleAirdrop.s.sol.

## Deploy to Anvil

This will default to your local node. You need to have it running in another terminal in order for it to deploy.

```
# Run a local anvil node
make anvil
# Then, in a second terminal
make deploy
```

## Interacting - Local anvil network

Copy the Bagel Token and Aidrop contract addresses and paste them into the AIRDROP_ADDRESS and TOKEN_ADDRESS variables in the MakeFile

The following steps allow the second default anvil address (0x70997970C51812dc3A010C7d01b50e0d17dc79C8) to call claim and pay for the gas on behalf of the first default anvil address (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266) which will recieve the airdrop.

### Sign your airdrop claim

```
# in another terminal
make sign
```

Retrieve the (v, r, s) outputted to the terminal and add them to Interact.s.sol.

Additionally, if you have modified the claiming addresses in the merkle tree, you will need to update the proofs in this file too (which you can get from output.json)

### Claim your airdrop

Then run the following command:

```
make claim
```

### Check claim amount

Then, check the claiming address balance has increased by running

```
make balance
```

NOTE: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 is the default anvil address which has recieved the airdropped tokens.

## Testing

```
forge test
```

### Test Coverage

```
forge coverage
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
