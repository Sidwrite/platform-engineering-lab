# Security Setup Guide

This document explains how to properly configure secrets and sensitive information for the Pet Project.

## **IMPORTANT: Never commit sensitive information to Git!**

## **Required Secrets**

### **1. AWS Credentials**
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and region
```

### **2. SSH Key Pair (Auto-generated)**
```bash
# SSH keys are automatically created by Terraform
# No manual creation needed!
# Keys will be saved as:
# - pet-project-ssh-key.pem (private key)
# - pet-project-ssh-key.pub (public key)
```

### **3. Grafana Password**
```bash
# Grafana password is managed through GitHub Secrets
# Set GRAFANA_ADMIN_PASSWORD in GitHub repository secrets
# The password will be automatically injected into Kubernetes manifests
```

### **4. Database Password**
```bash
export DB_PASSWORD="your-secure-password"
```

## **GitHub Secrets Setup**

For CI/CD pipelines, configure these secrets in GitHub:

### **Repository Secrets:**
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
- `DB_PASSWORD` - Database password
- `GRAFANA_ADMIN_PASSWORD` - Grafana admin password (optional)

### **How to add secrets:**
1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with its value

## **Terraform Configuration**

Create `terraform.tfvars` file:
```hcl
# AWS Configuration
region = "us-east-1"
environment = "dev"

# Key Pair (create this in AWS Console first)
key_name = "your-key-name"

# Database Configuration
db_password = ""  # Leave empty to use AWS Secrets Manager
```

## **Environment Variables**

Set these in your shell:
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
export DB_PASSWORD="your-database-password"
```

## **Production Security**

### **1. Use AWS Secrets Manager:**
```hcl
# In terraform.tfvars
db_password = ""  # Leave empty to use AWS Secrets Manager
```

### **2. Rotate secrets regularly:**
- Database passwords: Every 90 days
- SSH keys: Every 180 days
- AWS credentials: Every 90 days

### **3. Use IAM roles instead of access keys:**
- Create IAM roles for EC2 instances
- Use role-based access instead of access keys

## **Security Checklist**

Before deploying, ensure:
- [ ] No hardcoded passwords in code
- [ ] Environment variables used for secrets
- [ ] GitHub secrets configured
- [ ] SSH keys have correct permissions (600)
- [ ] Database passwords are strong (12+ characters)
- [ ] AWS credentials are least-privilege
- [ ] Regular secret rotation planned

## **Security Audit Commands**

```bash
# Check for sensitive files
find . -name "*.tfstate" -o -name "*.pem" -o -name "*.key" -o -name "terraform.tfvars"

# Check for hardcoded secrets
grep -r "password.*=" infrastructure/ --exclude-dir=.terraform
grep -r "secret.*=" infrastructure/ --exclude-dir=.terraform
grep -r "key.*=" infrastructure/ --exclude-dir=.terraform
```

## **If you accidentally committed secrets:**

1. **Immediately rotate the secrets**
2. **Remove from Git history:**
   ```bash
   git filter-branch --force --index-filter \
   'git rm --cached --ignore-unmatch path/to/secret/file' \
   --prune-empty --tag-name-filter cat -- --all
   ```
3. **Force push to remote:**
   ```bash
   git push origin --force --all
   ```

## **Additional Resources**

- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)