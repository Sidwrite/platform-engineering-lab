#!/bin/bash

# Pet Project - Complete Deployment Script
# Deploys infrastructure and application

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
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install AWS CLI first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found. Please install Terraform first."
        exit 1
    fi
    
    # Check SSH key
    if [ ! -f ~/.ssh/id_rsa.pem ] && [ ! -f ~/.ssh/pet-project-key.pem ]; then
        print_error "SSH key not found. Please create SSH key pair in AWS Console and download the .pem file."
        exit 1
    fi
    
    # Check database password
    if [ -z "$DB_PASSWORD" ]; then
        print_error "DB_PASSWORD environment variable not set. Please set it: export DB_PASSWORD='your-password'"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure..."
    
    cd infrastructure/terraform
    terraform init
    terraform plan
    terraform apply -auto-approve
    
    print_success "Infrastructure deployed"
    cd ../..
}

# Deploy application
deploy_application() {
    print_status "Deploying application..."
    
    # Get infrastructure info
    cd infrastructure/terraform
    BASTION_IP=$(terraform output -raw bastion_public_ip)
    K3S_IP=$(terraform output -raw k3s_private_ip)
    cd ../..
    
    print_status "Bastion IP: $BASTION_IP"
    print_status "K3s IP: $K3S_IP"
    
    # Wait for k3s to be ready
    print_status "Waiting for k3s to be ready..."
    sleep 120
    
    # Deploy application
    print_status "Deploying application to k3s..."
    ssh -i ~/.ssh/id_rsa ec2-user@$BASTION_IP "ssh ec2-user@$K3S_IP './deploy-pet-project.sh'"
    
    print_success "Application deployed"
}

# Test deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Get infrastructure info
    cd infrastructure/terraform
    BASTION_IP=$(terraform output -raw bastion_public_ip)
    K3S_IP=$(terraform output -raw k3s_private_ip)
    cd ../..
    
    # Test application
    print_status "Testing application..."
    ssh -i ~/.ssh/id_rsa ec2-user@$BASTION_IP "ssh ec2-user@$K3S_IP 'kubectl get pods -n pet-project'"
    
    print_success "Deployment test completed"
}

# Show access information
show_access_info() {
    print_success "Deployment completed successfully!"
    echo ""
    echo "📊 Access Information:"
    echo "  Bastion IP: $BASTION_IP"
    echo "  K3s IP: $K3S_IP"
    echo ""
    echo "Management Commands:"
    echo "  # SSH to bastion"
    echo "  ssh -i ~/.ssh/id_rsa ec2-user@$BASTION_IP"
    echo ""
    echo "  # SSH to k3s from bastion"
    echo "  ssh ec2-user@$K3S_IP"
    echo ""
    echo "  # Check application status"
    echo "  kubectl get pods -n pet-project"
    echo "  kubectl get services -n pet-project"
    echo "  kubectl get hpa -n pet-project"
    echo ""
    echo "🧪 Testing Commands:"
    echo "  # Port forward from k3s instance"
    echo "  kubectl port-forward service/pet-project-api 8080:80 -n pet-project"
    echo "  curl http://localhost:8080/health"
    echo "  curl http://localhost:8080/transactions"
    echo ""
    echo "🗑️  Cleanup:"
    echo "  cd infrastructure/terraform && terraform destroy"
}

# Main execution
main() {
    echo "Pet Project - Complete Deployment"
    echo "===================================="
    echo ""
    
    check_prerequisites
    deploy_infrastructure
    deploy_application
    test_deployment
    show_access_info
}

# Run main function
main "$@"
