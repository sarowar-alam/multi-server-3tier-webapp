#!/bin/bash

# BMI Health Tracker - Frontend EC2 Deployment Script
# This script sets up the frontend on an Ubuntu EC2 instance

set -e

echo "🚀 BMI Health Tracker - Frontend EC2 Deployment"
echo "================================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${YELLOW}ℹ${NC} $1"; }

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   print_error "Please do not run as root"
   exit 1
fi

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
    print_info "Please create .env file from .env.example and configure BACKEND_EC2_IP"
    exit 1
fi

# Load environment variables
source .env
print_status ".env file loaded"

# Install dependencies
print_info "Installing frontend dependencies..."
npm install
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
if [ ! -z "$VITE_BACKEND_URL" ]; then
    # Extract IP from BACKEND_URL
    BACKEND_IP=$(echo $VITE_BACKEND_URL | sed 's/http:\/\///' | sed 's/:3000//')
    
    # Update nginx config with backend IP
    sudo cp nginx.conf /etc/nginx/sites-available/bmi-frontend
    sudo sed -i "s/BACKEND_EC2_PRIVATE_IP/$BACKEND_IP/g" /etc/nginx/sites-available/bmi-frontend
    sudo sed -i "s/YOUR_FRONTEND_DOMAIN_OR_IP/$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/g" /etc/nginx/sites-available/bmi-frontend
    
    # Enable site
    sudo ln -sf /etc/nginx/sites-available/bmi-frontend /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload nginx
    sudo nginx -t
    sudo systemctl reload nginx
    print_status "Nginx configured and reloaded"
else
    print_error "VITE_BACKEND_URL not set in .env file"
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
echo -e "${GREEN}✓ Frontend Deployment Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Frontend URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo ""
echo "Next Steps:"
echo "1. Access the application in your browser"
echo "2. Ensure Backend EC2 is running and accessible"
echo "3. Check Nginx logs: sudo tail -f /var/log/nginx/bmi-frontend-error.log"
echo ""
