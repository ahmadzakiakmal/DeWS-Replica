FROM golang:1.24-alpine AS builder

# Install required packages
RUN apk add --no-cache git bash make gcc libc-dev jq

# Set working directory
WORKDIR /app

COPY . .

# Build your application
# If the git clone fails (placeholder repo), create a simple main.go as fallback
RUN if [ -f "main.go" ]; then \
        go build -o ./build/DeWS-Replica .; \
    else \
        echo "Using provided code instead of repository"; \
    fi

# Build a smaller final image
FROM alpine:3.17

# Install required system packages
RUN apk add --no-cache bash curl jq

# Copy the binary from the builder stage
# COPY --from=builder /app/build/DeWS-Replica /usr/bin/DeWS-Replica
COPY --from=builder /app/build/DeWS-Replica /app/DeWS-Replica
COPY --from=builder /app/templates /app/templates

# Create directory for the node
RUN mkdir -p /root/.cometbft

# Environment variables with defaults
ENV CMT_HOME=/root/.cometbft \
    NODE_MONIKER=node \
    HTTP_PORT=5000

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose the HTTP port and CometBFT ports
EXPOSE $HTTP_PORT 26656 26657

# Set entrypoint script
ENTRYPOINT ["/entrypoint.sh"]