#!/bin/bash

# Check if required arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <contract-address> <contract-name> [constructor-args]"
    exit 1
fi

CONTRACT_ADDRESS=$1
CONTRACT_NAME=$2
CONSTRUCTOR_ARGS=${3:-""}  # Optional constructor arguments

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Please create a .env file with BLOCKSCOUT_API_KEY and BLOCKSCOUT_URL variables"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$BLOCKSCOUT_API_KEY" ] || [ -z "$BLOCKSCOUT_URL" ]
then
    echo "Please set BLOCKSCOUT_API_KEY and BLOCKSCOUT_URL in your .env file"
    exit 1
fi

echo "Verifying $CONTRACT_NAME at $CONTRACT_ADDRESS..."

# Flatten the contract
echo "Flattening contract..."
forge flatten src/$CONTRACT_NAME.sol > flattened.sol

# Standard JSON input
echo "Creating Standard JSON input..."
cat > standard-input.json << EOF
{
  "language": "Solidity",
  "sources": {
    "flattened.sol": {
      "content": $(cat flattened.sol | jq -Rs .)
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    }
  }
}
EOF

# Compile the flattened contract
echo "Compiling contract..."
solc --standard-json standard-input.json > compiled.json

# Extract bytecode and metadata
BYTECODE=$(jq -r '.contracts."flattened.sol"."'"$CONTRACT_NAME"'".evm.bytecode.object' compiled.json)
DEPLOYED_BYTECODE=$(jq -r '.contracts."flattened.sol"."'"$CONTRACT_NAME"'".evm.deployedBytecode.object' compiled.json)
ABI=$(jq -r '.contracts."flattened.sol"."'"$CONTRACT_NAME"'".abi' compiled.json)

# Prepare verification request
echo "Submitting verification request..."
curl -X POST "$BLOCKSCOUT_URL/api/v1/verify" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $BLOCKSCOUT_API_KEY" \
    -d '{
        "address": "'"$CONTRACT_ADDRESS"'",
        "name": "'"$CONTRACT_NAME"'",
        "compiler_version": "v0.8.20+commit.a1b79de6",
        "optimization": true,
        "optimization_runs": 200,
        "constructor_arguments": "'"$CONSTRUCTOR_ARGS"'",
        "source_code": '"$(cat flattened.sol | jq -Rs .)"',
        "contract_libraries": {},
        "evm_version": "paris"
    }'

# Cleanup
rm flattened.sol standard-input.json compiled.json

echo "Verification request submitted. Check the Blockscout explorer for status."