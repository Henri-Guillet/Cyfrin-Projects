-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install smartcontractkit/chainlink-evm@contracts-v1.4.0 && forge install smartcontractkit/chainlink-ccip@contracts-ccip-v1.6.0 && forge install openzeppelin/openzeppelin-contracts@v5.3.0 && forge install smartcontractkit/chainlink-local@v0.2.5-beta.0

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test






