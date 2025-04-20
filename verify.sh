#!/bin/bash

SCRIPT_NAME="Deploy.s.sol" # Change if your script name is different
CHAIN_ID="11155931"
BROADCAST_FILE="broadcast/$SCRIPT_NAME/$CHAIN_ID/run-latest.json"

# Check if broadcast file exists
if [ ! -f "$BROADCAST_FILE" ]; then
    echo "Error: Broadcast file not found at $BROADCAST_FILE" >&2
    echo "Please run your deployment script with --broadcast first." >&2
    exit 1
fi

# No arguments needed anymore, we verify all contracts in the broadcast file

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Please create a .env file with BLOCKSCOUT_API_KEY and BLOCKSCOUT_URL variables" >&2
    exit 1
fi

source .env

# Define compiler version and optimizer runs (match your foundry.toml or deployment settings)
# TODO: Consider fetching these from foundry.toml if they vary
COMPILER_VERSION="0.8.20"
OPTIMIZER_RUNS=200

# --- Process all deployed contracts --- 

# Use jq to extract address and full contract path:name for all CREATE transactions
# Output is lines of JSON like: {"address":"0x...","name":"src/Contract.sol:Contract"}
CONTRACT_INFO=$(jq -c '.transactions[] | select(.transactionType == "CREATE") | {address: .contractAddress, name: .contractName}' "$BROADCAST_FILE")

if [ -z "$CONTRACT_INFO" ]; then
    echo "No contracts found in broadcast file: $BROADCAST_FILE" >&2
    exit 0 # Not an error, just nothing to verify
fi

echo "Found contracts in broadcast file. Attempting verification..."
echo "---------------------------------------------------------"

OVERALL_EXIT_CODE=0

while IFS= read -r line; do
    CONTRACT_ADDRESS=$(echo "$line" | jq -r '.address')
    FULL_CONTRACT_NAME=$(echo "$line" | jq -r '.name') # e.g., src/Contract.sol:Contract

    # Extract simple contract name for user messages (optional)
    SIMPLE_CONTRACT_NAME=$(basename "$FULL_CONTRACT_NAME" | sed 's/.*://') 
    
    # Construct the path needed by forge verify-contract
    CONTRACT_PATH_NAME=$FULL_CONTRACT_NAME

    echo "Verifying $SIMPLE_CONTRACT_NAME ($CONTRACT_PATH_NAME) at $CONTRACT_ADDRESS..."
    echo "(Note: Constructor arguments are NOT automatically detected and passed)"

    echo "DEBUG: Using contract path: $CONTRACT_PATH_NAME"

    # Execute forge verify-contract for this specific contract
    # IMPORTANT: We are NOT passing --constructor-args here. Verification will
    # fail if the contract requires them.
    forge verify-contract \
        "$CONTRACT_ADDRESS" \
        "$CONTRACT_PATH_NAME" \
        --chain-id "$CHAIN_ID" \
        --verifier blockscout \
        --verifier-url "$EXPLORER_API_URL"
        # --etherscan-api-key "$BLOCKSCOUT_API_KEY"
        # Add --constructor-args manually here if needed for specific contracts
        # Example: if [ "$SIMPLE_CONTRACT_NAME" == "Staking" ]; then ARGS="--constructor-args 0xRegistryAddress"; else ARGS=""; fi
        # forge verify-contract ... $ARGS

    CONTRACT_EXIT_CODE=$?

    if [ $CONTRACT_EXIT_CODE -eq 0 ]; then
        echo "---> Verification SUCCESS for $SIMPLE_CONTRACT_NAME."
    else
        echo "---> Verification FAILED for $SIMPLE_CONTRACT_NAME with exit code $CONTRACT_EXIT_CODE." >&2
        OVERALL_EXIT_CODE=1 # Mark overall failure if any contract fails
    fi
    echo "---------------------------------------------------------"

done <<< "$CONTRACT_INFO"

echo "Verification process finished."

if [ $OVERALL_EXIT_CODE -eq 0 ]; then
    echo "All attempted verifications submitted successfully (though some might fail on Blockscout if constructor args were needed)."
else
    echo "One or more verification attempts failed."
fi

exit $OVERALL_EXIT_CODE