#!/bin/bash

# Bastion Host User Data Script
# Update system and install basic tools

yum update -y

# Install basic tools
yum install -y \
    htop \
    vim \
    wget \
    curl \
    git \
    postgresql15 \
    jq

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
mv terraform /usr/local/bin/
rm terraform_1.6.0_linux_amd64.zip

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Create a non-root user for better security
useradd -m -s /bin/bash knova
usermod -aG wheel knova

# Set up SSH for knova user
mkdir -p /home/knova/.ssh
chown knova:knova /home/knova/.ssh
chmod 700 /home/knova/.ssh

# Log completion
echo "Bastion host setup completed at $(date)" >> /var/log/bastion-setup.log
