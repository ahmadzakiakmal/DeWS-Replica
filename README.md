# DeWS Replica

An implementation replica for [DeWS: Decentralized and Byzantine Fault-tolerant Web Services](https://ieeexplore.ieee.org/document/10174949/). The original implementation uses Tendermint, this replica uses the successor of Tendermint, [CometBFT](https://github.com/cometbft/cometbft).

# Setup and Running

The provided script, `setup-network.sh`, will generate configs for 4 nodes, the minimum requirement to **tolerate 1 Byzantine fault**.

The script will generate 4 directories each corresponds as the config for each node. The directories are `node0` to `node3`. Ports for P2P Connection and RPC is configured within this directories.

After running the script, build the go source code using
```
go build -o ./build
```

then run each node in different terminals using
```
./build/DeWS-Replica --cmt-home=./node0 --http-port 5001
```
adjust the `--cmt-home` flag to the node's config and adjust the http ports.