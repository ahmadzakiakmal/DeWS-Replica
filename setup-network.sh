#!/bin/bash

# Create directory for each node
mkdir -p node0 node1 node2 node3

echo "Created directory for the nodes"

# Initialize nodes
echo "Initializing nodes..."

cometbft init --home=./node0
echo "Node 0 initialized"

cometbft init --home=./node1
echo "Node 1 initialized"

cometbft init --home=./node2
echo "Node 2 initialized"

cometbft init --home=./node3
echo "Node 3 initialized"

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

# Copy genesis from node0 to the others
echo "Sharing genesis file from node0 to the others"
cp node0/config/genesis.json node1/config/genesis.json
cp node0/config/genesis.json node2/config/genesis.json
cp node0/config/genesis.json node3/config/genesis.json
echo "Genesis file successfully shared to all nodes"

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

# Configure persistent peers for each node
echo "Configuring peer connections..."

# Node 0 connects to Nodes 1, 2, and 3
sed -i.bak "s/^persistent_peers = \"\"/persistent_peers = \"$NODE1_ID@127.0.0.1:9002,$NODE2_ID@127.0.0.1:9004,$NODE3_ID@127.0.0.1:9006\"/" node0/config/config.toml
# Node 1 connects to Nodes 0, 2, and 3
sed -i.bak "s/^persistent_peers = \"\"/persistent_peers = \"$NODE0_ID@127.0.0.1:9000,$NODE2_ID@127.0.0.1:9004,$NODE3_ID@127.0.0.1:9006\"/" node1/config/config.toml
# Node 2 connects to Nodes 0, 1, and 3
sed -i.bak "s/^persistent_peers = \"\"/persistent_peers = \"$NODE0_ID@127.0.0.1:9000,$NODE1_ID@127.0.0.1:9002,$NODE3_ID@127.0.0.1:9006\"/" node2/config/config.toml
# Node 3 connects to Nodes 0, 1, and 2
sed -i.bak "s/^persistent_peers = \"\"/persistent_peers = \"$NODE0_ID@127.0.0.1:9000,$NODE1_ID@127.0.0.1:9002,$NODE2_ID@127.0.0.1:9004\"/" node3/config/config.toml

echo "Peer connections configured for all nodes"

# Configure each node for local development
for node in node0 node1 node2 node3; do
  # Allow non-safe connections (for development only)
  sed -i.bak 's/^addr_book_strict = true/addr_book_strict = false/' $node/config/config.toml
  
  # Allow CORS for web server access
  sed -i.bak 's/^cors_allowed_origins = \[\]/cors_allowed_origins = ["*"]/' $node/config/config.toml
  
  echo "Local development settings configured for $node"
done

# Display startup instructions
echo ""
echo "==== Network Setup Complete ===="
echo ""
echo "To start the nodes with web servers, run these commands in separate terminals:"
echo "Node 0: go build -o ./build && ./build/DeWS-Replica --cmt-home=./node0 --http-port 5000"
echo "Node 1: go build -o ./build && ./build/DeWS-Replica --cmt-home=./node1 --http-port 5001"
echo "Node 2: go build -o ./build && ./build/DeWS-Replica --cmt-home=./node2 --http-port 5002"
echo "Node 3: go build -o ./build && ./build/DeWS-Replica --cmt-home=./node3 --http-port 5003"
echo ""
echo "To check if nodes are connected:"
echo "Node 0: http://localhost:5000"
echo "Node 1: http://localhost:5001"
echo "Node 2: http://localhost:5002"
echo "Node 3: http://localhost:5003"