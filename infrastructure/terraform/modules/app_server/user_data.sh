#!/bin/bash

# Application Server User Data Script
# Set up application environment

yum update -y

# Install basic tools and dependencies
yum install -y \
    htop \
    vim \
    wget \
    curl \
    git \
    postgresql15 \
    python3 \
    python3-pip \
    docker \
    jq

# Start and enable Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Create application directory
mkdir -p /opt/knova-app
cd /opt/knova-app

# Create a simple Python Flask application
cat > app.py << 'EOF'
from flask import Flask, jsonify, request
import psycopg2
import os
import json

app = Flask(__name__)

# Database configuration
DB_CONFIG = {
    'host': '${db_endpoint}',
    'port': 5432,
    'database': 'pet_project',
    'user': 'pet_admin',
    'password': os.environ.get('DB_PASSWORD', '')  # Use environment variable
}

def get_db_connection():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

@app.route('/health')
def health_check():
    return jsonify({'status': 'healthy', 'service': 'pet-project-api'})

@app.route('/')
def home():
    return jsonify({
        'message': 'Welcome to Pet Project API',
        'version': '1.0.0',
        'endpoints': ['/health', '/transactions', '/accounts']
    })

@app.route('/transactions', methods=['GET', 'POST'])
def transactions():
    if request.method == 'GET':
        # Get all transactions
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM transactions ORDER BY created_at DESC LIMIT 10")
            transactions = cursor.fetchall()
            cursor.close()
            conn.close()
            
            return jsonify({'transactions': transactions})
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    elif request.method == 'POST':
        # Create new transaction
        data = request.get_json()
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        try:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO transactions (amount, description, account_id) VALUES (%s, %s, %s)",
                (data.get('amount'), data.get('description'), data.get('account_id'))
            )
            conn.commit()
            cursor.close()
            conn.close()
            
            return jsonify({'message': 'Transaction created successfully'}), 201
        except Exception as e:
            return jsonify({'error': str(e)}), 500

@app.route('/accounts', methods=['GET'])
def accounts():
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM accounts")
        accounts = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify({'accounts': accounts})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=True)
EOF

# Create requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.3.3
psycopg2-binary==2.9.7
gunicorn==21.2.0
EOF

# Install Python dependencies
pip3 install -r requirements.txt

# Create systemd service for the application
cat > /etc/systemd/system/knova-app.service << 'EOF'
[Unit]
Description=Knova Fintech API
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/knova-app
ExecStart=/usr/local/bin/gunicorn --bind 0.0.0.0:80 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable knova-app
# Note: Service will be started after database is ready

# Log completion
echo "Application server setup completed at $(date)" >> /var/log/app-setup.log
