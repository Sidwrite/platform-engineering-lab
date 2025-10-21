#!/bin/bash

# Setup Monitoring Stack
# This script deploys Prometheus, Grafana, and AlertManager for monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found. Please install kubectl first."
        exit 1
    fi
    
    # Check if cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Deploy monitoring stack
deploy_monitoring() {
    print_status "Deploying monitoring stack..."
    
    # Create monitoring namespace
    print_status "Creating monitoring namespace..."
    kubectl apply -f infrastructure/kubernetes/monitoring/namespace.yaml
    
    # Deploy Prometheus
    print_status "Deploying Prometheus..."
    kubectl apply -f infrastructure/kubernetes/monitoring/prometheus-config.yaml
    kubectl apply -f infrastructure/kubernetes/monitoring/prometheus-deployment.yaml
    
    # Deploy Grafana
    print_status "Deploying Grafana..."
    kubectl apply -f infrastructure/kubernetes/monitoring/grafana-deployment.yaml
    
    # Deploy AlertManager
    print_status "Deploying AlertManager..."
    kubectl apply -f infrastructure/kubernetes/monitoring/alertmanager.yaml
    
    print_success "Monitoring stack deployed!"
}

# Wait for deployments
wait_for_deployments() {
    print_status "Waiting for deployments to be ready..."
    
    # Wait for Prometheus
    print_status "Waiting for Prometheus..."
    kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring
    
    # Wait for Grafana
    print_status "Waiting for Grafana..."
    kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring
    
    # Wait for AlertManager
    print_status "Waiting for AlertManager..."
    kubectl wait --for=condition=available --timeout=300s deployment/alertmanager -n monitoring
    
    print_success "All deployments are ready!"
}

# Check status
check_status() {
    print_status "Checking monitoring stack status..."
    
    # Check pods
    print_status "Monitoring pods:"
    kubectl get pods -n monitoring
    
    # Check services
    print_status "Monitoring services:"
    kubectl get services -n monitoring
    
    # Check if services are accessible
    print_status "Testing service connectivity..."
    
    # Test Prometheus
    if kubectl port-forward service/prometheus 9090:9090 -n monitoring &>/dev/null &
    then
        PROMETHEUS_PID=$!
        sleep 5
        if curl -f http://localhost:9090 &>/dev/null; then
            print_success "Prometheus is accessible"
        else
            print_error "Prometheus is not accessible"
        fi
        kill $PROMETHEUS_PID 2>/dev/null || true
    fi
    
    # Test Grafana
    if kubectl port-forward service/grafana 3000:3000 -n monitoring &>/dev/null &
    then
        GRAFANA_PID=$!
        sleep 5
        if curl -f http://localhost:3000 &>/dev/null; then
            print_success "Grafana is accessible"
        else
            print_error "Grafana is not accessible"
        fi
        kill $GRAFANA_PID 2>/dev/null || true
    fi
}

# Show access information
show_access_info() {
    print_success "Monitoring stack is ready!"
    echo ""
    echo "📊 Access Information:"
    echo ""
    echo "Prometheus (Metrics):"
    echo "  kubectl port-forward service/prometheus 9090:9090 -n monitoring"
    echo "  http://localhost:9090"
    echo ""
    echo "📈 Grafana (Dashboards):"
    echo "  kubectl port-forward service/grafana 3000:3000 -n monitoring"
    echo "  http://localhost:3000"
    echo "  Username: admin"
    echo "  Password: admin"
    echo ""
    echo "🚨 AlertManager (Alerts):"
    echo "  kubectl port-forward service/alertmanager 9093:9093 -n monitoring"
    echo "  http://localhost:9093"
    echo ""
    echo "Monitoring Commands:"
    echo "  # Check pods"
    echo "  kubectl get pods -n monitoring"
    echo ""
    echo "  # Check logs"
    echo "  kubectl logs -f deployment/prometheus -n monitoring"
    echo "  kubectl logs -f deployment/grafana -n monitoring"
    echo ""
    echo "  # Check alerts"
    echo "  kubectl port-forward service/prometheus 9090:9090 -n monitoring"
    echo "  # Then visit http://localhost:9090/alerts"
}

# Cleanup
cleanup() {
    print_status "Cleaning up monitoring stack..."
    
    # Stop port-forwards
    pkill -f "kubectl port-forward" || true
    
    # Delete monitoring resources
    kubectl delete -f infrastructure/kubernetes/monitoring/ --ignore-not-found=true
    
    print_success "Monitoring stack cleaned up!"
}

# Show usage
show_usage() {
    echo "Usage: $0 [deploy|status|cleanup|all]"
    echo ""
    echo "Commands:"
    echo "  deploy  - Deploy monitoring stack"
    echo "  status  - Check monitoring status"
    echo "  cleanup - Remove monitoring stack"
    echo "  all     - Deploy and show access info"
    echo ""
    echo "Examples:"
    echo "  $0 deploy  # Deploy monitoring only"
    echo "  $0 all     # Full setup"
    echo "  $0 cleanup # Remove monitoring"
}

# Main execution
main() {
    case "${1:-all}" in
        deploy)
            check_prerequisites
            deploy_monitoring
            wait_for_deployments
            ;;
        status)
            check_status
            ;;
        cleanup)
            cleanup
            ;;
        all)
            check_prerequisites
            deploy_monitoring
            wait_for_deployments
            check_status
            show_access_info
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
