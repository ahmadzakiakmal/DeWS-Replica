#!/bin/bash

# Clear existing configuration
rm -rf ./node*

# Create directories for each node
mkdir -p node0 node1 node2 node3

echo "Created directories for the nodes"

# Initialize nodes using cometbft locally
cometbft init --home=./node0
sed -i.bak 's/^moniker = ".*"/moniker = "node0"/' node0/config/config.toml
echo "Node 0 initialized with moniker 'node0'"

cometbft init --home=./node1
sed -i.bak 's/^moniker = ".*"/moniker = "node1"/' node1/config/config.toml
echo "Node 1 initialized with moniker 'node1'"

cometbft init --home=./node2
sed -i.bak 's/^moniker = ".*"/moniker = "node2"/' node2/config/config.toml
echo "Node 2 initialized with moniker 'node2'"

cometbft init --home=./node3
sed -i.bak 's/^moniker = ".*"/moniker = "node3"/' node3/config/config.toml
echo "Node 3 initialized with moniker 'node3'"

# Configure ports for each node
sed -i.bak 's/^laddr = "tcp:\/\/0.0.0.0:26656"/laddr = "tcp:\/\/0.0.0.0:9000"/' node0/config/config.toml
sed -i.bak 's/^laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:9001"/' node0/config/config.toml
echo "Node 0 configured to use P2P port 9000 and RPC port 9001"

sed -i.bak 's/^laddr = "tcp:\/\/0.0.0.0:26656"/laddr = "tcp:\/\/0.0.0.0:9002"/' node1/config/config.toml
sed -i.bak 's/^laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:9003"/' node1/config/config.toml
echo "Node 1 configured to use P2P port 9002 and RPC port 9003"

sed -i.bak 's/^laddr = "tcp:\/\/0.0.0.0:26656"/laddr = "tcp:\/\/0.0.0.0:9004"/' node2/config/config.toml
sed -i.bak 's/^laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:9005"/' node2/config/config.toml
echo "Node 2 configured to use P2P port 9004 and RPC port 9005"

sed -i.bak 's/^laddr = "tcp:\/\/0.0.0.0:26656"/laddr = "tcp:\/\/0.0.0.0:9006"/' node3/config/config.toml
sed -i.bak 's/^laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:9007"/' node3/config/config.toml
echo "Node 3 configured to use P2P port 9006 and RPC port 9007"

# Get validator info from node0 and node1
echo "Extracting validator info from node0 and node1"
NODE0_VALIDATOR=$(cat node0/config/genesis.json | jq '.validators[0]')
NODE1_PUBKEY=$(cat node1/config/priv_validator_key.json | jq -r '.pub_key.value')

# Create updated genesis with both validators
echo "Adding node1 as a validator to genesis file"
cat node0/config/genesis.json | jq --arg pubkey "$NODE1_PUBKEY" '.validators += [{"address":"","pub_key":{"type":"tendermint/PubKeyEd25519","value":$pubkey},"power":"10","name":"node1"}]' > updated_genesis.json

# Copy updated genesis to all nodes
echo "Sharing updated genesis file to all nodes"
cp updated_genesis.json node0/config/genesis.json
cp updated_genesis.json node1/config/genesis.json
cp updated_genesis.json node2/config/genesis.json
cp updated_genesis.json node3/config/genesis.json
echo "Updated genesis file with two validators successfully shared to all nodes"

# Get node IDs
echo "Getting node IDs"
NODE0_ID=$(cometbft show-node-id --home=./node0)
NODE1_ID=$(cometbft show-node-id --home=./node1)
NODE2_ID=$(cometbft show-node-id --home=./node2)
NODE3_ID=$(cometbft show-node-id --home=./node3)

echo "Node0 ID: $NODE0_ID"
echo "Node1 ID: $NODE1_ID"
echo "Node2 ID: $NODE2_ID"
echo "Node3 ID: $NODE3_ID"

# Configure persistent peers - use docker container names for networking
echo "Configuring full mesh peer connections for Docker environment..."

# Using container names for networking
sed -i.bak "s/^persistent_peers = \"\"/persistent_peers = \"$NODE1_ID@cometbft-node1:9002,$NODE2_ID@cometbft-node2:9004,$NODE3_ID@cometbft-node3:9006\"/" node0/config/config.toml
sed -i.bak "s/^persistent_peers = \"\"/persistent_peers = \"$NODE0_ID@cometbft-node0:9000,$NODE2_ID@cometbft-node2:9004,$NODE3_ID@cometbft-node3:9006\"/" node1/config/config.toml
sed -i.bak "s/^persistent_peers = \"\"/persistent_peers = \"$NODE0_ID@cometbft-node0:9000,$NODE1_ID@cometbft-node1:9002,$NODE3_ID@cometbft-node3:9006\"/" node2/config/config.toml
sed -i.bak "s/^persistent_peers = \"\"/persistent_peers = \"$NODE0_ID@cometbft-node0:9000,$NODE1_ID@cometbft-node1:9002,$NODE2_ID@cometbft-node2:9004\"/" node3/config/config.toml

echo "Full mesh peer connections configured for all nodes in Docker environment"

# Configure each node for local development
for node in node0 node1 node2 node3; do
  # Allow non-safe connections (for development only)
  sed -i.bak 's/^addr_book_strict = true/addr_book_strict = false/' $node/config/config.toml
  
  # Allow CORS for web server access
  sed -i.bak 's/^cors_allowed_origins = \[\]/cors_allowed_origins = ["*"]/' $node/config/config.toml
  
  # Set database backend to goleveldb
  if grep -q "db_backend" $node/config/config.toml; then
    sed -i.bak 's/^db_backend = ".*"/db_backend = "goleveldb"/' $node/config/config.toml
  else
    echo 'db_backend = "goleveldb"' >> $node/config/config.toml
  fi
  
  echo "Local development settings configured for $node"
done

echo ""
echo "==== Docker Setup Complete ===="
echo ""
echo "Run the following commands to start the network:"
echo "1. docker-compose up -d"
echo ""
echo "To check logs:"
echo "docker logs cometbft-node0"
echo "docker logs cometbft-node1"
echo "docker logs cometbft-node2"
echo "docker logs cometbft-node3"
echo ""
echo "To access the nodes:"
echo "Node 0: http://localhost:5000"
echo "Node 1: http://localhost:5001"
echo "Node 2: http://localhost:5002"
echo "Node 3: http://localhost:5003"