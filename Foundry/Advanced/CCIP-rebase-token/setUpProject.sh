#!/bin/bash

# Define constants
ACCOUNT_NAME="pk_dev1"
SENDER="0xd20e08766b2ebB24466eFaff47D523264550Ee06" 

ARB_SEPOLIA_REGISTRY_MODULE_OWNER_CUSTOM="0xE625f0b8b0Ac86946035a7729Aba124c8A64cf69"
ARB_SEPOLIA_TOKEN_ADMIN_REGISTRY="0x8126bE56454B628a88C17849B9ED99dd5a11Bd2f"
ARB_SEPOLIA_ROUTER="0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165"
ARB_SEPOLIA_RNM_PROXY_ADDRESS="0x9527E2d01A3064ef6b50c1Da1C0cC523803BCFF2"
ARB_SEPOLIA_CHAIN_SELECTOR="3478487238524512106"
ARB_SEPOLIA_LINK_ADDRESS="0xb1D4538B4571d411F07960EF2838Ce337FE1E80E"

SEPOLIA_REGISTRY_MODULE_OWNER_CUSTOM="0x62e731218d0D47305aba2BE3751E7EE9E5520790"
SEPOLIA_TOKEN_ADMIN_REGISTRY="0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82"
SEPOLIA_ROUTER="0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59"
SEPOLIA_RNM_PROXY_ADDRESS="0xba3f6251de62dED61Ff98590cB2fDf6871FbB991"
SEPOLIA_CHAIN_SELECTOR="16015286601757825753"
SEPOLIA_LINK_ADDRESS="0x779877A7B0D9E8603169DdbD7836e478b4624789"

# 1. On Ethereum Sepolia
source .env

echo "Running the script to deploy the contracts on Sepolia..."
output=$(forge script ./script/Deployers.s.sol:TokenAndPoolDeployer --rpc-url ${SEPOLIA_RPC_URL} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} --account ${ACCOUNT_NAME} --sender ${SENDER}  --broadcast)
echo "Contracts deployed and permission set on Sepolia"

# Extract the addresses from the output
SEPOLIA_REBASE_TOKEN_ADDRESS=$(echo "$output" | grep 'token: contract RebaseToken' | awk '{print $4}')
SEPOLIA_POOL_ADDRESS=$(echo "$output" | grep 'pool: contract RebaseTokenPool' | awk '{print $4}')

echo "Sepolia rebase token address: $SEPOLIA_REBASE_TOKEN_ADDRESS"
echo "Sepolia pool address: $SEPOLIA_POOL_ADDRESS"

# Deploy the vault 
echo "Deploying the vault on Sepolia..."
vault_output=$(forge script ./script/Deployers.s.sol:VaultDeployer --rpc-url ${SEPOLIA_RPC_URL} --account ${ACCOUNT_NAME} --sender ${SENDER} --broadcast --sig "run(address)" ${SEPOLIA_REBASE_TOKEN_ADDRESS})
VAULT_ADDRESS=$(echo "$vault_output" | grep -i 'vault' | awk '{print $4}')
echo "Vault address: $VAULT_ADDRESS"

# 2. On Arbitrum Sepolia


echo "Running the script to deploy the contracts on Arbitrum Sepolia..."
output=$(forge script ./script/Deployers.s.sol:TokenAndPoolDeployer --rpc-url ${ARB_SEPOLIA_RPC_URL} --account ${ACCOUNT_NAME} --sender ${SENDER} --broadcast)
echo "Contracts deployed and permission set on Arbitrum Sepolia"

# Extract the addresses from the output
ARB_SEPOLIA_REBASE_TOKEN_ADDRESS=$(echo "$output" | grep 'token: contract RebaseToken' | awk '{print $4}')
ARB_SEPOLIA_POOL_ADDRESS=$(echo "$output" | grep 'pool: contract RebaseTokenPool' | awk '{print $4}')

echo "Sepolia rebase token address: $ARB_SEPOLIA_REBASE_TOKEN_ADDRESS"
echo "Sepolia pool address: $ARB_SEPOLIA_POOL_ADDRESS"

# Configure the pool on Sepolia
echo "Configuring the pool on Sepolia..."
#         address localPool,
#         uint64 remoteChainSelector,
#         address remotePool,
#         address remoteToken,
#         bool outboundRateLimiterIsEnabled, false 
#         uint128 outboundRateLimiterCapacity, 0
#         uint128 outboundRateLimiterRate, 0
#         bool inboundRateLimiterIsEnabled, false 
#         uint128 inboundRateLimiterCapacity, 0 
#         uint128 inboundRateLimiterRate 0 
forge script ./script/ConfigurePool.s.sol:ConfigurePoolScript --rpc-url ${SEPOLIA_RPC_URL} --account ${ACCOUNT_NAME} --sender ${SENDER} --broadcast --sig "run(address,uint64,address,address,bool,uint128,uint128,bool,uint128,uint128)" ${SEPOLIA_POOL_ADDRESS} ${ARB_SEPOLIA_CHAIN_SELECTOR} ${ARB_SEPOLIA_POOL_ADDRESS} ${ARB_SEPOLIA_REBASE_TOKEN_ADDRESS} false 0 0 false 0 0


# Configure the pool on Arbitrum Sepolia
echo "Configuring the pool on Arbitrum Sepolia..."
#         address localPool,
#         uint64 remoteChainSelector,
#         address remotePool,
#         address remoteToken,
#         bool outboundRateLimiterIsEnabled, false 
#         uint128 outboundRateLimiterCapacity, 0
#         uint128 outboundRateLimiterRate, 0
#         bool inboundRateLimiterIsEnabled, false 
#         uint128 inboundRateLimiterCapacity, 0 
#         uint128 inboundRateLimiterRate 0 
forge script ./script/ConfigurePool.s.sol:ConfigurePoolScript --rpc-url ${ARB_SEPOLIA_RPC_URL} --account ${ACCOUNT_NAME} --sender ${SENDER} --broadcast --sig "run(address,uint64,address,address,bool,uint128,uint128,bool,uint128,uint128)" ${ARB_SEPOLIA_POOL_ADDRESS} ${SEPOLIA_CHAIN_SELECTOR} ${SEPOLIA_POOL_ADDRESS} ${SEPOLIA_REBASE_TOKEN_ADDRESS} false 0 0 false 0 0
