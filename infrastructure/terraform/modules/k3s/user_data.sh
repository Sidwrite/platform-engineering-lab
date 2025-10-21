#!/bin/bash

# K3s Installation and Configuration Script
# This script installs and configures k3s on Amazon Linux 2

set -e

# Variables
CLUSTER_NAME="${cluster_name}"
ENVIRONMENT="${environment}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# Update system
print_status "Updating system packages..."
yum update -y
yum install -y curl wget git

# Install Docker
print_status "Installing Docker..."
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install k3s
print_status "Installing k3s..."
curl -sfL https://get.k3s.io | sh -s - \
    --cluster-name="$CLUSTER_NAME" \
    --disable=traefik \
    --disable=servicelb \
    --write-kubeconfig-mode=644 \
    --node-name=k3s-master

# Wait for k3s to be ready
print_status "Waiting for k3s to be ready..."
sleep 60

# Ensure k3s is running
print_status "Ensuring k3s is running..."
systemctl start k3s
systemctl enable k3s

# Wait for k3s to be fully ready
print_status "Waiting for k3s to be fully ready..."
for i in {1..30}; do
    if kubectl get nodes > /dev/null 2>&1; then
        print_success "K3s is ready!"
        break
    fi
    print_status "Waiting for k3s... ($i/30)"
    sleep 10
done

# Install Helm
print_status "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Configure kubeconfig for ec2-user
print_status "Configuring kubeconfig..."
mkdir -p /home/ec2-user/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
chown ec2-user:ec2-user /home/ec2-user/.kube/config
chmod 600 /home/ec2-user/.kube/config

# Set KUBECONFIG environment variable
echo 'export KUBECONFIG=/home/ec2-user/.kube/config' >> /home/ec2-user/.bashrc

# Create pet-project namespace
print_status "Creating pet-project namespace..."
kubectl create namespace pet-project --dry-run=client -o yaml | kubectl apply -f -

# Create deployment script
print_status "Creating deployment script..."
cat > /home/ec2-user/deploy-pet-project.sh << 'EOF'
#!/bin/bash

# Deploy Pet Project API to k3s

set -e

echo "=== Deploying Pet Project API ==="
kubectl apply -f - << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pet-project-api
  namespace: pet-project
  labels:
    app: pet-project-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pet-project-api
  template:
    metadata:
      labels:
        app: pet-project-api
    spec:
      containers:
      - name: pet-project-api
        image: golang:1.21-alpine
        command: ["/bin/sh"]
        args:
        - -c
        - |
          apk add --no-cache git curl
          cat > main.go << 'GOLANG'
package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "time"
)

type Transaction struct {
    ID          string    `json:"id"`
    Amount      float64   `json:"amount"`
    Currency    string    `json:"currency"`
    Description string    `json:"description"`
    Timestamp   time.Time `json:"timestamp"`
}

type HealthResponse struct {
    Status    string `json:"status"`
    Service   string `json:"service"`
    Version   string `json:"version"`
    Timestamp string `json:"timestamp"`
}

var transactions []Transaction

func main() {
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

    http.HandleFunc("/", homeHandler)
    http.HandleFunc("/health", healthHandler)
    http.HandleFunc("/transactions", transactionsHandler)

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("Starting Pet Project API on port %s", port)
    if err := http.ListenAndServe(":"+port, nil); err != nil {
        log.Fatal("Server failed to start:", err)
    }
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
    response := map[string]interface{}{
        "message": "Welcome to Pet Project API",
        "version": "1.0.0",
        "endpoints": []string{"/health", "/transactions"},
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
    response := map[string]interface{}{
        "message": "Transactions retrieved successfully",
        "data":    transactions,
    }
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}
GOLANG
          go run main.go
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: pet-project-api
  namespace: pet-project
spec:
  selector:
    app: pet-project-api
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: pet-project-api
  namespace: pet-project
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: pet-project-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
YAML

echo "=== Waiting for deployment ==="
kubectl wait --for=condition=available --timeout=300s deployment/pet-project-api -n pet-project

echo "=== Pod status ==="
kubectl get pods -n pet-project

echo "=== Service status ==="
kubectl get services -n pet-project

echo "=== HPA status ==="
kubectl get hpa -n pet-project

echo "=== Testing API ==="
kubectl port-forward service/pet-project-api 8080:80 -n pet-project &
sleep 10
curl -f http://localhost:8080/health || echo "Health check failed"
curl -f http://localhost:8080/transactions || echo "Transactions endpoint failed"
pkill -f "kubectl port-forward"
EOF

chmod +x /home/ec2-user/deploy-pet-project.sh
chown ec2-user:ec2-user /home/ec2-user/deploy-pet-project.sh

# Final status
print_success "K3s installation completed successfully!"
print_status "Cluster information:"
kubectl get nodes
kubectl get pods --all-namespaces

print_status "Available commands:"
echo "  kubectl get pods -n pet-project"
echo "  kubectl get services -n pet-project"
echo "  kubectl get hpa -n pet-project"
echo "  ./deploy-pet-project.sh"

print_success "K3s cluster is ready for Pet Project API deployment!"