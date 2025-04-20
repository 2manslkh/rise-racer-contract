#!/bin/bash

# Check if network is provided
if [ -z "$1" ]
then
    echo "Please provide a network name (e.g. riselabs, sepolia, etc.)"
    exit 1
fi

NETWORK=$1

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Please create a .env file with required variables"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$PRIVATE_KEY" ] || [ -z "$RPC_URL" ] || [ -z "$EXPLORER_API_URL" ]
then
    echo "Please set PRIVATE_KEY, RPC_URL, and EXPLORER_API_URL in your .env file"
    exit 1
fi

# Build contracts
echo "Building contracts..."
forge build --sizes

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Run deployment script
echo "Deploying to $NETWORK..."
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify \
    --verifier blockscout \
    --verifier-url $EXPLORER_API_URL \
    --skip-simulation \
    -vvvv

DEPLOY_STATUS=$?

# Check if deployment was successful
if [ $DEPLOY_STATUS -eq 0 ]
then
    echo "Deployment successful!"
    
    # Extract contract addresses from the broadcast output
    BROADCAST_FILE=$(ls -t broadcast/Deploy.s.sol/**/run-latest.json | head -n 1)
    
    if [ -f "$BROADCAST_FILE" ]; then
        echo "Deployed contract addresses:"
        jq -r '.transactions[] | select(.transactionType == "CREATE") | "\(.contractName): \(.contractAddress)"' "$BROADCAST_FILE"
        
        # Save addresses to a file for future reference
        echo "# Deployed on $(date)" > deployed-addresses.txt
        jq -r '.transactions[] | select(.transactionType == "CREATE") | "\(.contractName)=\(.contractAddress)"' "$BROADCAST_FILE" >> deployed-addresses.txt
        
        echo "Contract addresses saved to deployed-addresses.txt"
    else
        echo "Warning: Could not find broadcast file for address extraction"
    fi
else
    echo "Deployment failed!"
    exit 1
fi