# DeWS Replica

An implementation replica for [DeWS: Decentralized and Byzantine Fault-tolerant Web Services](https://ieeexplore.ieee.org/document/10174949/). The original implementation uses Tendermint, this replica uses the successor of Tendermint, [CometBFT](https://github.com/cometbft/cometbft).

## Setup and Running

### Traditional Setup

The provided script, `setup-network.sh`, will generate configs for 4 nodes, the minimum requirement to **tolerate 1 Byzantine fault**.

The script will generate 4 directories each corresponds as the config for each node. The directories are `node0` to `node3`. Ports for P2P Connection and RPC are configured within these directories.

After running the script, build the go source code using:
```
go build -o ./build
```

then run each node in different terminals using:
```
./build/DeWS-Replica --cmt-home=./node0 --http-port 5001
```
Adjust the `--cmt-home` flag to the node's config and adjust the http ports via the `--http-port` flag.


⚠️ This traditional setup has problems for more than 2 nodes connecting to each other, to avoid this, use the Docker Setup below


### Docker Setup

Alternatively, you can run the network in Docker containers using the provided Docker setup.

#### Prerequisites

- Docker
- Docker Compose

#### Setup Steps

1. Run the Docker setup script to initialize the node configurations:
```
./docker-setup.sh
```

2. Build and start the Docker containers:
```
docker-compose up -d --build
```

This will start 4 nodes in separate containers with the following ports mapped to your host machine:

| Node   | HTTP Port | P2P Port | RPC Port |
|--------|-----------|----------|----------|
| node0  | 5000      | 9000     | 9001     |
| node1  | 5001      | 9002     | 9003     |
| node2  | 5002      | 9004     | 9005     |
| node3  | 5003      | 9006     | 9007     |

#### Accessing the Nodes

You can access the web interface for each node at:
- Node 0: http://localhost:5000
- Node 1: http://localhost:5001
- Node 2: http://localhost:5002
- Node 3: http://localhost:5003

#### Viewing Logs

To view logs for a specific node:
```
docker logs cometbft-node0
```

Replace `cometbft-node0` with the appropriate container name (`cometbft-node1`, `cometbft-node2`, or `cometbft-node3`).

#### Stopping the Network

To stop the network:
```
docker-compose down
```

To completely reset and rebuild:
```
docker-compose down
rm -rf ./node*
./docker-setup.sh
docker-compose up -d --build
```