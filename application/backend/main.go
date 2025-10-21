package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

// Transaction represents a simple transaction
type Transaction struct {
	ID          string    `json:"id"`
	Amount      float64   `json:"amount"`
	Currency    string    `json:"currency"`
	Description string    `json:"description"`
	Timestamp   time.Time `json:"timestamp"`
}

// HealthResponse represents health check response
type HealthResponse struct {
	Status    string `json:"status"`
	Service   string `json:"service"`
	Version   string `json:"version"`
	Timestamp string `json:"timestamp"`
}

// APIResponse represents a generic API response
type APIResponse struct {
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

var transactions []Transaction

func main() {
	// Initialize with some sample data
	transactions = []Transaction{
		{
			ID:          "txn-001",
			Amount:      100.50,
			Currency:    "USD",
			Description: "Coffee purchase",
			Timestamp:   time.Now().Add(-1 * time.Hour),
		},
		{
			ID:          "txn-002",
			Amount:      25.00,
			Currency:    "USD",
			Description: "Lunch",
			Timestamp:   time.Now().Add(-2 * time.Hour),
		},
	}

	// Routes
	http.HandleFunc("/", homeHandler)
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/transactions", transactionsHandler)
	http.HandleFunc("/transactions/", transactionHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting Pet Project API on port %s", port)
	log.Printf("Health check: http://localhost:%s/health", port)
	log.Printf("Transactions: http://localhost:%s/transactions", port)

	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal("Server failed to start:", err)
	}
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
	response := APIResponse{
		Message: "Welcome to Pet Project API",
		Data: map[string]interface{}{
			"version":   "1.0.0",
			"endpoints": []string{"/health", "/transactions"},
		},
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	response := HealthResponse{
		Status:    "healthy",
		Service:   "pet-project-api",
		Version:   "1.0.0",
		Timestamp: time.Now().Format(time.RFC3339),
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func transactionsHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		getTransactions(w, r)
	case http.MethodPost:
		createTransaction(w, r)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func getTransactions(w http.ResponseWriter, r *http.Request) {
	response := APIResponse{
		Message: "Transactions retrieved successfully",
		Data:    transactions,
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func createTransaction(w http.ResponseWriter, r *http.Request) {
	var newTxn Transaction
	if err := json.NewDecoder(r.Body).Decode(&newTxn); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Generate ID if not provided
	if newTxn.ID == "" {
		newTxn.ID = fmt.Sprintf("txn-%d", time.Now().Unix())
	}
	
	// Set timestamp if not provided
	if newTxn.Timestamp.IsZero() {
		newTxn.Timestamp = time.Now()
	}

	transactions = append(transactions, newTxn)

	response := APIResponse{
		Message: "Transaction created successfully",
		Data:    newTxn,
	}
	
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

func transactionHandler(w http.ResponseWriter, r *http.Request) {
	// Extract transaction ID from URL path
	path := r.URL.Path
	id := path[len("/transactions/"):]
	
	if id == "" {
		http.Error(w, "Transaction ID required", http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodGet:
		getTransaction(w, r, id)
	case http.MethodPut:
		updateTransaction(w, r, id)
	case http.MethodDelete:
		deleteTransaction(w, r, id)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func getTransaction(w http.ResponseWriter, r *http.Request, id string) {
	for _, txn := range transactions {
		if txn.ID == id {
			response := APIResponse{
				Message: "Transaction found",
				Data:    txn,
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(response)
			return
		}
	}
	
	http.Error(w, "Transaction not found", http.StatusNotFound)
}

func updateTransaction(w http.ResponseWriter, r *http.Request, id string) {
	var updatedTxn Transaction
	if err := json.NewDecoder(r.Body).Decode(&updatedTxn); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	for i, txn := range transactions {
		if txn.ID == id {
			updatedTxn.ID = id // Ensure ID doesn't change
			transactions[i] = updatedTxn
			
			response := APIResponse{
				Message: "Transaction updated successfully",
				Data:    updatedTxn,
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(response)
			return
		}
	}
	
	http.Error(w, "Transaction not found", http.StatusNotFound)
}

func deleteTransaction(w http.ResponseWriter, r *http.Request, id string) {
	for i, txn := range transactions {
		if txn.ID == id {
			transactions = append(transactions[:i], transactions[i+1:]...)
			
			response := APIResponse{
				Message: "Transaction deleted successfully",
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(response)
			return
		}
	}
	
	http.Error(w, "Transaction not found", http.StatusNotFound)
}
