#!/bin/bash
set -e

# Environment defaults if not provided
: ${CMT_HOME:="/root/.cometbft"}
: ${NODE_MONIKER:="node"}
: ${HTTP_PORT:="5000"}

echo "Starting DeWS-Replica..."
echo "CMT_HOME: $CMT_HOME"
echo "HTTP_PORT: $HTTP_PORT"
echo "NODE_MONIKER: $NODE_MONIKER"

cd /app

# If we have a custom binary, run it
if [ -f "/app/DeWS-Replica" ]; then
    echo "Using DeWS-Replica binary with templates in current directory..."
    exec /app/DeWS-Replica --cmt-home="$CMT_HOME" --http-port="$HTTP_PORT"
else
    # Fallback to PATH binary
    echo "Using system DeWS-Replica binary..."
    exec DeWS-Replica --cmt-home="$CMT_HOME" --http-port="$HTTP_PORT"
fi