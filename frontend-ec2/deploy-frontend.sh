#!/bin/bash

# BMI Health Tracker - Frontend EC2 Deployment Script
# This script sets up the frontend on an Ubuntu EC2 instance

set -e

echo "BMI Health Tracker - Frontend EC2 Deployment"
echo "================================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[OK]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

# Update system
print_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y
print_status "System updated"

# Install Node.js using NVM
print_info "Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
fi
print_status "Node.js $(node -v) installed"

# Install Nginx
print_info "Installing Nginx..."
sudo apt install -y nginx
sudo systemctl enable nginx
print_status "Nginx installed"

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found"
    print_info "Please create .env file from .env.example"
    print_info "Set VITE_BACKEND_URL to your Frontend EC2 PUBLIC IP (e.g., http://52.24.187.55)"
    exit 1
fi

# Load environment variables
source .env
print_status ".env file loaded"

# Install dependencies
print_info "Installing frontend dependencies..."
npm install
npm install -D terser
print_status "Dependencies installed"

# Build frontend
print_info "Building frontend for production..."
npm run build
print_status "Frontend built successfully"

# Deploy to nginx directory
print_info "Deploying frontend to /var/www/bmi-health-tracker..."
sudo mkdir -p /var/www/bmi-health-tracker
sudo rm -rf /var/www/bmi-health-tracker/*
sudo cp -r dist/* /var/www/bmi-health-tracker/
sudo chown -R www-data:www-data /var/www/bmi-health-tracker
print_status "Frontend deployed"

# Configure Nginx
print_info "Configuring Nginx..."

# We need the backend PRIVATE IP for nginx proxy, not the public frontend IP
# Backend EC2 private IP should be provided via environment or discovered
if [ -z "$BACKEND_PRIVATE_IP" ]; then
    print_info "BACKEND_PRIVATE_IP not set, please provide it:"
    read -p "Enter Backend EC2 Private IP: " BACKEND_PRIVATE_IP
fi

if [ ! -z "$BACKEND_PRIVATE_IP" ]; then
    # Get EC2 public IP using IMDSv2
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    PUBLIC_IP=$(curl -s \
      -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/public-ipv4)
    
    # Update nginx config with backend IP
    sudo cp nginx.conf /etc/nginx/sites-available/bmi-frontend
    sudo sed -i "s/BACKEND_EC2_PRIVATE_IP/$BACKEND_PRIVATE_IP/g" /etc/nginx/sites-available/bmi-frontend
    sudo sed -i "s/YOUR_FRONTEND_DOMAIN_OR_IP/$PUBLIC_IP/g" /etc/nginx/sites-available/bmi-frontend
    
    # Enable site
    sudo ln -sf /etc/nginx/sites-available/bmi-frontend /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload nginx
    sudo nginx -t
    sudo systemctl reload nginx
    print_status "Nginx configured and reloaded"
else
    print_error "BACKEND_PRIVATE_IP not provided"
    exit 1
fi

# Configure firewall
print_info "Configuring firewall..."
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
sudo ufw --force enable
print_status "Firewall configured"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Frontend Deployment Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Get EC2 public IP using IMDSv2 (reuse token if within TTL, or get new one)
if [ -z "$PUBLIC_IP" ]; then
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    PUBLIC_IP=$(curl -s \
      -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/public-ipv4)
fi

echo "Frontend URL: http://$PUBLIC_IP"
echo ""
echo "Next Steps:"
echo "1. Access the application in your browser"
echo "2. Ensure Backend EC2 is running and accessible"
echo "3. Check Nginx logs: sudo tail -f /var/log/nginx/bmi-frontend-error.log"
echo ""
