#!/bin/bash

# BMI Health Tracker - Database EC2 Setup Script
# This script sets up PostgreSQL on an Ubuntu EC2 instance

set -e

echo "🗄️  BMI Health Tracker - Database EC2 Setup"
echo "==========================================="

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

# Database credentials
DB_USER="bmi_user"
DB_NAME="bmidb"

echo ""
print_info "This script will:"
echo "  1. Install PostgreSQL"
echo "  2. Create database user: $DB_USER"
echo "  3. Create database: $DB_NAME"
echo "  4. Run migrations"
echo "  5. Configure PostgreSQL for remote access"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Get password
read -sp "Enter password for database user '$DB_USER': " DB_PASS
echo ""
read -sp "Confirm password: " DB_PASS_CONFIRM
echo ""

if [ "$DB_PASS" != "$DB_PASS_CONFIRM" ]; then
    print_error "Passwords do not match"
    exit 1
fi

# Update system
print_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y
print_status "System updated"

# Install PostgreSQL
print_info "Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib
print_status "PostgreSQL installed"

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql
print_status "PostgreSQL service started"

# Create user
print_info "Creating database user..."
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" 2>/dev/null || print_info "User may already exist"
print_status "Database user created/verified"

# Create database
print_info "Creating database..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>/dev/null || print_info "Database may already exist"
print_status "Database created/verified"

# Grant privileges
print_info "Granting privileges..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
print_status "Privileges granted"

# Run migrations
print_info "Running migrations..."
cd "$(dirname "$0")"
export PGPASSWORD=$DB_PASS
psql -U $DB_USER -d $DB_NAME -h localhost -f migrations/001_create_measurements.sql
print_status "Migrations completed"

# Get EC2 private IP
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
print_info "EC2 Private IP: $PRIVATE_IP"

# Configure PostgreSQL for remote access
print_info "Configuring PostgreSQL for remote access..."

# Backup original configs
sudo cp /etc/postgresql/*/main/postgresql.conf /etc/postgresql/*/main/postgresql.conf.backup
sudo cp /etc/postgresql/*/main/pg_hba.conf /etc/postgresql/*/main/pg_hba.conf.backup

# Update postgresql.conf to listen on all interfaces
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

# Update pg_hba.conf to allow connections from Backend EC2
# Allow connections from private subnet (adjust CIDR as needed)
echo "host    $DB_NAME    $DB_USER    10.0.0.0/16    md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
echo "host    $DB_NAME    $DB_USER    172.31.0.0/16   md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf

print_status "PostgreSQL configured for remote access"

# Restart PostgreSQL
print_info "Restarting PostgreSQL..."
sudo systemctl restart postgresql
print_status "PostgreSQL restarted"

# Configure firewall
print_info "Configuring firewall..."
sudo ufw allow 5432/tcp
sudo ufw allow OpenSSH
sudo ufw --force enable
print_status "Firewall configured"

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}✓ Database EC2 Setup Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo "Database Connection String:"
echo "postgresql://$DB_USER:$DB_PASS@$PRIVATE_IP:5432/$DB_NAME"
echo ""
echo "IMPORTANT: Add this to Backend EC2 .env file as DATABASE_URL"
echo ""
echo "Next Steps:"
echo "1. Update Backend EC2 Security Group to allow outbound to port 5432"
echo "2. Update Database EC2 Security Group to allow inbound from Backend EC2"
echo "3. Test connection from Backend EC2:"
echo "   psql postgresql://$DB_USER:$DB_PASS@$PRIVATE_IP:5432/$DB_NAME"
echo ""
echo "Database Status:"
sudo systemctl status postgresql --no-pager
echo ""
