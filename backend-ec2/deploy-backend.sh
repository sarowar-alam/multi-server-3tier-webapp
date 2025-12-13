#!/bin/bash

# BMI Health Tracker - Backend EC2 Deployment Script
# This script sets up the backend on an Ubuntu EC2 instance

set -e

echo "🚀 BMI Health Tracker - Backend EC2 Deployment"
echo "==============================================="

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

# Install PostgreSQL client for testing connection
print_info "Installing PostgreSQL client..."
sudo apt install -y postgresql-client
print_status "PostgreSQL client installed"

# Install PM2
print_info "Installing PM2..."
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
fi
print_status "PM2 installed"

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found"
    print_info "Please create .env file from .env.example and configure:"
    print_info "  - DATABASE_URL with Database EC2 IP"
    print_info "  - FRONTEND_URL with Frontend EC2 IP"
    exit 1
fi

# Load environment variables
source .env
print_status ".env file loaded"

# Test database connection
print_info "Testing database connection..."
if [ ! -z "$DATABASE_URL" ]; then
    if psql "$DATABASE_URL" -c "SELECT 1" > /dev/null 2>&1; then
        print_status "Database connection successful"
    else
        print_error "Cannot connect to database. Check DATABASE_URL and Database EC2 security group"
        exit 1
    fi
else
    print_error "DATABASE_URL not set in .env"
    exit 1
fi

# Install dependencies
print_info "Installing backend dependencies..."
npm install --production
print_status "Dependencies installed"

# Create logs directory
mkdir -p logs
print_status "Logs directory created"

# Stop existing PM2 process
print_info "Stopping existing backend process..."
pm2 delete bmi-backend 2>/dev/null || true
print_status "Existing process stopped"

# Start backend with PM2
print_info "Starting backend with PM2..."
pm2 start ecosystem.config.js
pm2 save
print_status "Backend started with PM2"

# Setup PM2 startup
print_info "Configuring PM2 startup..."
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp $HOME > /dev/null 2>&1 || true
print_status "PM2 startup configured"

# Configure firewall
print_info "Configuring firewall..."
sudo ufw allow 3000/tcp
sudo ufw allow OpenSSH
sudo ufw --force enable
print_status "Firewall configured"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✓ Backend Deployment Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Backend Status:"
pm2 status
echo ""
echo "Backend API: http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):3000"
echo "Health Check: http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):3000/health"
echo ""
echo "Next Steps:"
echo "1. Test health endpoint: curl http://localhost:3000/health"
echo "2. Check PM2 logs: pm2 logs bmi-backend"
echo "3. Update Frontend EC2 with this Backend EC2 IP address"
echo "4. Ensure Security Group allows:"
echo "   - Port 3000 from Frontend EC2 Security Group"
echo "   - Port 5432 to Database EC2"
echo ""
