# Pet Project - DevOps Infrastructure

A complete DevOps solution demonstrating AWS infrastructure automation, Kubernetes orchestration, and CI/CD pipelines.

## **What This Project Does**

This project creates a production-ready infrastructure on AWS with:

- **AWS Infrastructure** - VPC, EC2 instances, RDS database
- **Kubernetes Cluster** - k3s for container orchestration  
- **Go API Application** - RESTful microservice
- **Monitoring Stack** - Prometheus, Grafana, AlertManager
- **CI/CD Pipelines** - Automated deployment with GitHub Actions

## **Quick Start**

### **Prerequisites:**
1. AWS CLI configured
2. Terraform installed
3. SSH key pair in AWS Console
4. Database password set

### **Setup:**

#### **1. Configure AWS**
```bash
aws configure
```

#### **2. SSH Keys (Auto-generated)**
- SSH keys are automatically created by Terraform
- No manual key creation needed!
- Keys will be saved as `pet-project-ssh-key.pem` and `pet-project-ssh-key.pub`

#### **3. Set Database Password**
```bash
export DB_PASSWORD="your-secure-password"
```

#### **4. Deploy Everything**
```bash
./scripts/deploy.sh
```

#### **5. Get SSH Keys**
After deployment, SSH keys will be available:
- **Private key**: `infrastructure/terraform/pet-project-ssh-key.pem`
- **Public key**: `infrastructure/terraform/pet-project-ssh-key.pub`

## 📁 **Project Structure**

```
pet-project/
├── infrastructure/          # Infrastructure code
│   ├── terraform/         # AWS resources
│   └── kubernetes/        # K8s manifests
├── application/           # Go API application
├── scripts/              # Deployment scripts
└── .github/workflows/    # CI/CD pipelines
```

## **Configuration**

### **Required Environment Variables:**
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key  
- `DB_PASSWORD` - Database password
- `GRAFANA_ADMIN_PASSWORD` - Grafana admin password (optional, defaults to "admin")

### **Terraform Variables:**
Edit `infrastructure/terraform/terraform.tfvars.example`:
```hcl
region = "us-east-1"
environment = "dev"
key_name = "your-key-name"
db_password = ""  # Leave empty for AWS Secrets Manager
```

## **Deployment**

### **Deploy Infrastructure:**
```bash
cd infrastructure/terraform
terraform init
terraform plan
terraform apply
```

### **Deploy Application:**
```bash
# SSH to k3s node
ssh -i ~/.ssh/your-key.pem ec2-user@<k3s-ip>

# Deploy application
cd /home/ec2-user/pet-project
./scripts/deploy-application.sh
```

## **Access Your Application**

### **API Endpoints:**
- **Health Check**: `http://<k3s-ip>:30000/health`
- **API**: `http://<k3s-ip>:30000/api/v1/`

### **Monitoring:**
```bash
# Prometheus
kubectl port-forward service/prometheus 9090:9090 -n monitoring
# http://localhost:9090

# Grafana  
kubectl port-forward service/grafana 3000:3000 -n monitoring
# http://localhost:3000 (admin/admin)
```

## 🔒 **Security**

### **Secrets Management:**
- Database passwords stored in environment variables
- SSH keys managed through AWS Key Pairs
- GitHub secrets for CI/CD pipelines

### **Network Security:**
- Private subnets for application servers
- Bastion host for secure access
- Security groups for network segmentation

## 🧪 **Testing**

### **Test Application Locally:**
```bash
cd application/backend
go run main.go
```

### **Test Infrastructure:**
```bash
terraform validate
terraform plan
```

## 📊 **CI/CD**

The project includes GitHub Actions workflows for:
- **Infrastructure Pipeline** - Terraform plan/apply
- **Application Pipeline** - Build, test, deploy

## 🗑️ **Cleanup**

### **Destroy Everything:**
```bash
cd infrastructure/terraform
terraform destroy
```

## 🆘 **Troubleshooting**

### **Common Issues:**

**SSH Connection:**
```bash
chmod 600 ~/.ssh/your-key.pem
ssh -i ~/.ssh/your-key.pem ec2-user@<bastion-ip>
```

**Terraform Issues:**
```bash
terraform init -upgrade
terraform plan
```

**Kubernetes Issues:**
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

## 📚 **Documentation**

- **[Security Setup](SECURITY_SETUP.md)** - How to configure secrets
- **[Deployment Guide](docs/DEPLOYMENT.md)** - Detailed deployment steps

## **Next Steps**

- **Production**: Migrate to EKS for managed Kubernetes
- **GitOps**: Add ArgoCD for automated deployments
- **Scaling**: Implement auto-scaling and load balancing
- **Security**: Add pod security policies and network policies

---

**Your DevOps infrastructure is ready!**