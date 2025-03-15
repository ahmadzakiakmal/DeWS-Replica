package main

import (
	"context"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"time"

	cmtlog "github.com/cometbft/cometbft/libs/log"
	nm "github.com/cometbft/cometbft/node"
)

type QueryRequest struct {
	Key string `json:"key"`
}
type QueryResponse struct {
	Key   string `json:"key,omitempty"`
	Value string `json:"value,omitempty"`
	Error string `json:"error,omitempty"`
}

type WebServer struct {
	app       *KVStoreApplication
	httpAddr  string
	server    *http.Server
	logger    cmtlog.Logger
	node      *nm.Node
	startTime time.Time
}

type NodeData struct {
	NodeID            string
	Status            string
	CurrentHeight     int
	HighestBlock      int
	P2PListenAddress  string
	GrpcListenAddress string
	RpcListenAddress  string
	PeerCount         int
	PendingTxCount    int
	Version           string

	// Added fields to match template
	SyncPercentage int
	Network        string
	Uptime         string
	GasPrice       float64
	Peers          []PeerInfo
	LatestBlocks   []BlockInfo
	Config         NodeConfig
}

// PeerInfo represents info about connected peers
type PeerInfo struct {
	ID      string
	IP      string
	Client  string
	Latency int
}

// BlockInfo represents info about a block
type BlockInfo struct {
	Number  int64
	Hash    string
	Time    string
	TxCount int
}

// NodeConfig represents node configuration
type NodeConfig struct {
	Consensus string
	SyncMode  string
	Features  []string
	P2PPort   string
	RPCPort   string
}

func NewWebServer(app *KVStoreApplication, httpPort string, logger cmtlog.Logger, node *nm.Node) *WebServer {
	mux := http.NewServeMux()

	server := &WebServer{
		app:      app,
		httpAddr: ":" + httpPort,
		server: &http.Server{
			Addr:    ":" + httpPort,
			Handler: mux,
		},
		logger:    logger,
		node:      node,
		startTime: time.Now(),
	}

	mux.HandleFunc("/", server.handleRoot)

	return server
}

func (webserver *WebServer) Start() error {
	webserver.logger.Info("Starting HTTP web server", "addr", webserver.httpAddr)
	go func() {
		if err := webserver.server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			webserver.logger.Error("HTTP server error: ", "err", err)
		}
	}()
	return nil
}

func (webserver *WebServer) Shutdown(ctx context.Context) error {
	webserver.logger.Info("Shutting down web server")
	return webserver.server.Shutdown(ctx)
}

func (webserver *WebServer) handleRoot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "text/html")
	nodeTemplate, err := template.ParseFiles("templates/node.tmpl")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	log.Println(webserver.node.Switch().Peers())

	nodeStatus := "online"
	if webserver.node.ConsensusReactor().WaitSync() {
		nodeStatus = "syncing"
	}
	if !webserver.node.IsListening() {
		nodeStatus = "offline"
	}

	// Calculate uptime
	uptime := time.Since(webserver.startTime)
	uptimeStr := formatDuration(uptime)

	// Get peers info
	peers := make([]PeerInfo, 0)
	// Option 1: Using Copy() to get a list of peers
	peersList := webserver.node.Switch().Peers().Copy()
	for _, peer := range peersList {
		nodeNetAddress, _ := peer.NodeInfo().NetAddress()
		peers = append(peers, PeerInfo{
			ID:      string(peer.ID()),
			IP:      peer.RemoteIP().String(),
			Client:  nodeNetAddress.String(),
			Latency: int(peer.Status().Duration),
		})
	}

	// Option 2: Alternative implementation using ForEach
	/*
		webserver.node.Switch().Peers().ForEach(func(peer p2p.Peer) {
			peers = append(peers, PeerInfo{
				ID:      string(peer.ID()),
				IP:      peer.RemoteIP().String(),
				Client:  peer.NodeInfo().Moniker,
				Latency: int(peer.LatencyMean().Milliseconds()),
			})
		})
	*/

	// Get latest blocks (example - you'll need to implement this based on your needs)
	latestBlocks := getLatestBlocks(webserver.node, 5)

	// Calculate sync percentage (example)
	syncPercentage := 0
	if nodeStatus == "syncing" && webserver.node.BlockStore().Height() > 0 {
		// This is a placeholder. In a real implementation you'd get the highest known block
		// from peers and calculate the actual percentage
		highestBlock := int(webserver.node.BlockStore().Height() + 100) // Example
		syncPercentage = int(float64(webserver.node.BlockStore().Height()) / float64(highestBlock) * 100)
	}

	// Network detection based on P2P config test fields
	network := "mainnet"
	if webserver.node.Config().P2P.TestDialFail || webserver.node.Config().P2P.TestFuzz {
		network = "testnet"
	}

	// Alternative approach - check if we're in seed mode or using specific test flags
	if webserver.node.Config().P2P.SeedMode {
		// SeedMode is often used for testnets
		network = "testnet"
	}

	// Another option - check if it's a local/private network by AddrBookStrict setting
	if !webserver.node.Config().P2P.AddrBookStrict {
		// Non-strict address book is often used for private/local networks
		network = "localnet"
	}

	data := NodeData{
		NodeID:            string(webserver.node.NodeInfo().ID()),
		Status:            nodeStatus,
		CurrentHeight:     int(webserver.node.BlockStore().Height()),
		HighestBlock:      int(webserver.node.BlockStore().Height()), // This should be the highest known block
		P2PListenAddress:  webserver.node.Config().P2P.ListenAddress,
		GrpcListenAddress: webserver.node.Config().GRPC.ListenAddress,
		RpcListenAddress:  webserver.node.Config().RPC.ListenAddress,
		PeerCount:         webserver.node.Switch().Peers().Size(),
		PendingTxCount:    webserver.node.Mempool().Size(),
		Version:           webserver.node.Config().Version,

		// Added fields
		SyncPercentage: syncPercentage,
		Network:        network,
		Uptime:         uptimeStr,
		GasPrice:       1.5, // Example value
		Peers:          peers,
		LatestBlocks:   latestBlocks,
		Config: NodeConfig{
			Consensus: "Test",                            // Example value
			SyncMode:  "Test",                            // Example value
			Features:  []string{"Webserver", "Database"}, // Example values
			P2PPort:   extractPortFromAddress(webserver.node.Config().P2P.ListenAddress),
			RPCPort:   extractPortFromAddress(webserver.node.Config().RPC.ListenAddress),
		},
	}

	err = nodeTemplate.ExecuteTemplate(w, "node", data)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

// Helper function to extract port from address like "tcp://0.0.0.0:26656"
func extractPortFromAddress(address string) string {
	// Simple implementation - in a real app you'd use proper URL parsing
	// This is just an example
	for i := len(address) - 1; i >= 0; i-- {
		if address[i] == ':' {
			return address[i+1:]
		}
	}
	return ""
}

// Helper function to format duration as a readable string
func formatDuration(d time.Duration) string {
	days := int(d.Hours()) / 24
	hours := int(d.Hours()) % 24
	minutes := int(d.Minutes()) % 60

	if days > 0 {
		return fmt.Sprintf("%dd %dh %dm", days, hours, minutes)
	}
	if hours > 0 {
		return fmt.Sprintf("%dh %dm", hours, minutes)
	}
	return fmt.Sprintf("%dm", minutes)
}

// Helper function to get latest blocks
func getLatestBlocks(node *nm.Node, count int) []BlockInfo {
	blocks := make([]BlockInfo, 0, count)

	currentHeight := node.BlockStore().Height()
	for i := currentHeight; i > 0 && i > currentHeight-int64(count); i-- {
		// Get block at height i
		block, _ := node.BlockStore().LoadBlock(i)
		if block == nil {
			continue
		}

		blockTime := block.Time.Format("2006-01-02 15:04:05")
		blocks = append(blocks, BlockInfo{
			Number:  i,
			Hash:    block.Hash().String(),
			Time:    blockTime,
			TxCount: len(block.Txs),
		})
	}

	return blocks
}
