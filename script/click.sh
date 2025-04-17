#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Please create a .env file with required variables"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$PRIVATE_KEY" ] || [ -z "$RPC_URL" ] || [ -z "$RISE_RACERS_ADDRESS" ]
then
    echo "Please set PRIVATE_KEY, RPC_URL, and RISE_RACERS_ADDRESS in your .env file"
    exit 1
fi

# Run the click script
echo "Calling click function on Rise Racers contract..."
forge script script/Click.s.sol:ClickScript \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY

# Check if the transaction was successful
if [ $? -eq 0 ]
then
    echo "Click function called successfully!"
else
    echo "Transaction failed!"
    exit 1
fi 