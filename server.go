package main

import (
	"context"
	"html/template"
	"log"
	"net/http"

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
	app      *KVStoreApplication
	httpAddr string
	server   *http.Server
	logger   cmtlog.Logger
	node     *nm.Node
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
		logger: logger,
		node:   node,
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
	}

	log.Println(webserver.node.Switch().Peers())

	nodeStatus := "online"
	if webserver.node.ConsensusReactor().WaitSync() {
		nodeStatus = "syncing"
	}
	if !webserver.node.IsListening() {
		nodeStatus = "offline"
	}
	data := NodeData{
		NodeID:            string(webserver.node.NodeInfo().ID()),
		Status:            nodeStatus,
		CurrentHeight:     int(webserver.node.BlockStore().Height()),
		HighestBlock:      int(0),
		P2PListenAddress:  webserver.node.Config().P2P.ListenAddress,
		GrpcListenAddress: webserver.node.Config().GRPC.ListenAddress,
		RpcListenAddress:  webserver.node.Config().RPC.ListenAddress,
		PeerCount:         webserver.node.Switch().Peers().Size(),
		PendingTxCount:    webserver.node.Mempool().Size(),
		Version:           webserver.node.Config().Version,
	}

	err = nodeTemplate.ExecuteTemplate(w, "node", data)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}
