# BMI Health Tracker - Complete Deployment Guide

This guide provides step-by-step instructions for deploying the BMI Health Tracker application across three AWS EC2 instances.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Infrastructure Setup](#aws-infrastructure-setup)
3. [Database EC2 Deployment](#database-ec2-deployment)
4. [Backend EC2 Deployment](#backend-ec2-deployment)
5. [Frontend EC2 Deployment](#frontend-ec2-deployment)
6. [Post-Deployment Verification](#post-deployment-verification)
7. [Troubleshooting Guide](#troubleshooting-guide)

---

## Prerequisites

### AWS Account Requirements

- Active AWS account with billing enabled
- IAM user with EC2 full access permissions
- EC2 key pair created and downloaded
- VPC with at least one public and one private subnet

### Local Machine Requirements

- SSH client installed
- Text editor (nano, vim, or VS Code with Remote SSH)
- Web browser for testing
- Basic familiarity with Linux command line

### Knowledge Requirements

- Basic AWS EC2 concepts
- Basic Linux command line operations
- Understanding of SSH connections
- Basic networking concepts (IP addresses, ports)

---

## AWS Infrastructure Setup

### Step 1: Create VPC (if needed)

1. **Navigate to VPC Console**
   - Go to AWS Console → VPC
   - Click "Create VPC"

2. **Configure VPC**
   - Name: `bmi-tracker-vpc`
   - IPv4 CIDR block: `10.0.0.0/16`
   - Create VPC

3. **Create Subnets**
   
   **Public Subnet** (for Frontend):
   - Name: `bmi-public-subnet`
   - VPC: `bmi-tracker-vpc`
   - CIDR: `10.0.1.0/24`
   - Auto-assign public IPv4: Yes
   
   **Private Subnet 1** (for Backend):
   - Name: `bmi-private-subnet-1`
   - VPC: `bmi-tracker-vpc`
   - CIDR: `10.0.2.0/24`
   
   **Private Subnet 2** (for Database):
   - Name: `bmi-private-subnet-2`
   - VPC: `bmi-tracker-vpc`
   - CIDR: `10.0.3.0/24`

4. **Create Internet Gateway**
   - Name: `bmi-igw`
   - Attach to `bmi-tracker-vpc`

5. **Create NAT Gateway** (for private subnets to access internet)
   - Subnet: `bmi-public-subnet`
   - Allocate Elastic IP
   - Name: `bmi-nat-gateway`

6. **Configure Route Tables**
   
   **Public Route Table**:
   - Associate with `bmi-public-subnet`
   - Add route: `0.0.0.0/0` → Internet Gateway
   
   **Private Route Table**:
   - Associate with `bmi-private-subnet-1` and `bmi-private-subnet-2`
   - Add route: `0.0.0.0/0` → NAT Gateway

#### ✅ VALIDATION CHECKPOINT 1: VPC and Network Setup

Before proceeding, verify your VPC configuration:

**1. Verify VPC Created**
```bash
# In AWS Console: VPC → Your VPCs
# Check: bmi-tracker-vpc exists with CIDR 10.0.0.0/16
```

**2. Verify Subnets**
```bash
# In AWS Console: VPC → Subnets
# Verify 3 subnets exist:
✓ bmi-public-subnet (10.0.1.0/24) - Auto-assign public IPv4: Yes
✓ bmi-private-subnet-1 (10.0.2.0/24)
✓ bmi-private-subnet-2 (10.0.3.0/24)
```

**3. Verify Internet Gateway**
```bash
# In AWS Console: VPC → Internet Gateways
✓ bmi-igw is attached to bmi-tracker-vpc
```

**4. Verify NAT Gateway**
```bash
# In AWS Console: VPC → NAT Gateways
✓ bmi-nat-gateway is in bmi-public-subnet
✓ Status: Available
✓ Has Elastic IP associated
```

**5. Verify Route Tables**
```bash
# In AWS Console: VPC → Route Tables

# Public Route Table:
✓ Associated with bmi-public-subnet
✓ Has route: 0.0.0.0/0 → Internet Gateway

# Private Route Table:
✓ Associated with bmi-private-subnet-1 and bmi-private-subnet-2
✓ Has route: 0.0.0.0/0 → NAT Gateway
```

**✅ All checks passed? Proceed to Step 2**  
**❌ Issues found? Fix them before continuing**

---

### Step 2: Create Security Groups

#### Frontend Security Group

1. **Create Security Group**
   - Name: `bmi-frontend-sg`
   - Description: Frontend web server security group
   - VPC: `bmi-tracker-vpc`

2. **Inbound Rules**
   ```
   Type        Protocol  Port Range  Source          Description
   HTTP        TCP       80          0.0.0.0/0       Allow web traffic
   HTTPS       TCP       443         0.0.0.0/0       Allow HTTPS traffic
   SSH         TCP       22          YOUR_IP/32      SSH access
   ```

3. **Outbound Rules**
   ```
   Type        Protocol  Port Range  Destination     Description
   Custom TCP  TCP       3000        bmi-backend-sg  Backend API
   HTTP        TCP       80          0.0.0.0/0       Package downloads
   HTTPS       TCP       443         0.0.0.0/0       Package downloads
   ```

#### Backend Security Group

1. **Create Security Group**
   - Name: `bmi-backend-sg`
   - Description: Backend API server security group
   - VPC: `bmi-tracker-vpc`

2. **Inbound Rules**
   ```
   Type        Protocol  Port Range  Source            Description
   Custom TCP  TCP       3000        bmi-frontend-sg   API from frontend
   SSH         TCP       22          YOUR_IP/32        SSH access
   ```

3. **Outbound Rules**
   ```
   Type        Protocol  Port Range  Destination      Description
   PostgreSQL  TCP       5432        bmi-database-sg  Database access
   HTTP        TCP       80          0.0.0.0/0        Package downloads
   HTTPS       TCP       443         0.0.0.0/0        Package downloads
   ```

#### Database Security Group

1. **Create Security Group**
   - Name: `bmi-database-sg`
   - Description: Database server security group
   - VPC: `bmi-tracker-vpc`

2. **Inbound Rules**
   ```
   Type        Protocol  Port Range  Source           Description
   PostgreSQL  TCP       5432        bmi-backend-sg   Backend access
   SSH         TCP       22          YOUR_IP/32       SSH access
   ```

3. **Outbound Rules**
   ```
   Type        Protocol  Port Range  Destination  Description
   HTTP        TCP       80          0.0.0.0/0    Package downloads
   HTTPS       TCP       443         0.0.0.0/0    Package downloads
   ```

#### ✅ VALIDATION CHECKPOINT 2: Security Groups

Verify all three security groups are correctly configured:

**1. Frontend Security Group (bmi-frontend-sg)**
```bash
# In AWS Console: EC2 → Security Groups → bmi-frontend-sg

Inbound Rules:
✓ HTTP (80) from 0.0.0.0/0
✓ HTTPS (443) from 0.0.0.0/0
✓ SSH (22) from YOUR_IP/32

Outbound Rules:
✓ Custom TCP (3000) to bmi-backend-sg
✓ HTTP (80) to 0.0.0.0/0
✓ HTTPS (443) to 0.0.0.0/0
```

**2. Backend Security Group (bmi-backend-sg)**
```bash
Inbound Rules:
✓ Custom TCP (3000) from bmi-frontend-sg
✓ SSH (22) from YOUR_IP/32

Outbound Rules:
✓ PostgreSQL (5432) to bmi-database-sg
✓ HTTP (80) to 0.0.0.0/0
✓ HTTPS (443) to 0.0.0.0/0
```

**3. Database Security Group (bmi-database-sg)**
```bash
Inbound Rules:
✓ PostgreSQL (5432) from bmi-backend-sg
✓ SSH (22) from YOUR_IP/32

Outbound Rules:
✓ HTTP (80) to 0.0.0.0/0
✓ HTTPS (443) to 0.0.0.0/0
```

**Important**: Make sure the source/destination is set to the **Security Group ID** (not IP addresses) for inter-EC2 communication.

**✅ All security groups verified? Proceed to Step 3**  
**❌ Missing or incorrect rules? Fix them now**

---

### Step 3: Create EC2 Key Pair

1. Go to EC2 Console → Key Pairs
2. Click "Create key pair"
3. Name: `bmi-tracker-key`
4. Key pair type: RSA
5. Private key file format: .pem
6. Click "Create key pair"
7. Save the downloaded .pem file securely
8. Set permissions (on Linux/Mac):
   ```bash
   chmod 400 bmi-tracker-key.pem
   ```

#### ✅ VALIDATION CHECKPOINT 3: Key Pair

**1. Verify Key Pair Exists**
```bash
# In AWS Console: EC2 → Key Pairs
✓ bmi-tracker-key is listed
✓ Type: RSA
```

**2. Verify Local File**
```bash
# Check file exists
ls -la bmi-tracker-key.pem

# Verify permissions (should be 400 or -r--------)
ls -l bmi-tracker-key.pem
```

**3. Test Key Format (optional)**
```bash
# Should show RSA PRIVATE KEY
head -n 1 bmi-tracker-key.pem
# Output should be: -----BEGIN RSA PRIVATE KEY-----
```

**✅ Key pair ready? Proceed to Database EC2 Deployment**  
**❌ Issues with key pair? Recreate it**

---

## Database EC2 Deployment

### Step 1: Launch Database EC2 Instance

1. **Navigate to EC2 Console**
   - Click "Launch Instance"

2. **Configure Instance**
   - Name: `bmi-database-ec2`
   - AMI: Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
   - Architecture: 64-bit (x86)
   - Instance type: t2.micro (Free tier eligible)
   
3. **Network Settings**
   - VPC: `bmi-tracker-vpc`
   - Subnet: `bmi-private-subnet-2`
   - Auto-assign public IP: Disable
   - Security group: `bmi-database-sg`
   
4. **Storage**
   - Size: 8 GB (default)
   - Volume type: gp3
   
5. **Key Pair**
   - Select: `bmi-tracker-key`
   
6. **Launch Instance**

7. **Note Private IP Address**
   - Go to instance details
   - Note the "Private IPv4 addresses"
   - Example: `10.0.3.15`

#### ✅ VALIDATION CHECKPOINT 4: Database EC2 Launch

**1. Verify Instance Running**
```bash
# In AWS Console: EC2 → Instances
✓ Instance Name: bmi-database-ec2
✓ Instance State: Running
✓ Status Checks: 2/2 checks passed (wait 2-3 minutes)
```

**2. Verify Instance Configuration**
```bash
✓ AMI: Ubuntu Server 22.04 LTS
✓ Instance Type: t2.micro
✓ VPC: bmi-tracker-vpc
✓ Subnet: bmi-private-subnet-2 (10.0.3.0/24)
✓ Auto-assign Public IP: No
✓ Security Group: bmi-database-sg
✓ Key Pair: bmi-tracker-key
```

**3. Note Private IP**
```bash
# Write down the Private IPv4 address
Database EC2 Private IP: ___________________
Example: 10.0.3.15
```

**✅ Instance running and configured correctly? Proceed to Step 2**  
**❌ Wrong configuration? Terminate and relaunch**

---

### Step 2: Connect to Database EC2

Since this is in a private subnet, you'll need a bastion host or use Session Manager:

**Option A: Using Bastion Host**
```bash
# Connect to bastion first
ssh -i bmi-tracker-key.pem ubuntu@BASTION_PUBLIC_IP

# Then connect to database EC2
ssh ubuntu@DATABASE_PRIVATE_IP
```

**Option B: Using AWS Session Manager**
1. Ensure EC2 has SSM agent (Ubuntu 22.04 has it by default)
2. Use AWS Console → EC2 → Connect → Session Manager

### Step 3: Upload Database Files

```bash
# From your local machine
# First, upload to bastion or use S3

# Option 1: Via Bastion
scp -i bmi-tracker-key.pem -r database-ec2/ ubuntu@BASTION_IP:~/
ssh -i bmi-tracker-key.pem ubuntu@BASTION_IP
scp -r database-ec2/ ubuntu@DATABASE_PRIVATE_IP:~/

# Option 2: Via S3
aws s3 cp database-ec2/ s3://your-bucket/database-ec2/ --recursive
# Then from Database EC2:
aws s3 cp s3://your-bucket/database-ec2/ ~/database-ec2/ --recursive
```

### Step 4: Run Database Setup Script

```bash
# Connect to Database EC2
cd ~/database-ec2
chmod +x setup-database.sh
./setup-database.sh
```

**During setup, you'll be prompted for**:
- Continue? (y/n): Enter `y`
- Database password: Enter a strong password (e.g., `BMI@Tracker2025!`)
- Confirm password: Re-enter the same password

**Important**: Write down the connection string provided at the end!
Example:
```
postgresql://bmi_user:BMI@Tracker2025!@10.0.3.15:5432/bmidb
```

**Script Should Complete Successfully**:
- ✅ System packages updated
- ✅ PostgreSQL installed
- ✅ Database user created
- ✅ Database created
- ✅ Privileges granted
- ✅ Migrations completed
- ✅ Remote access configured
- ✅ PostgreSQL restarted
- ✅ Firewall configured

### Step 5: Verify Database Setup

```bash
# Test connection
psql -U bmi_user -d bmidb -h localhost

# Run test query
SELECT * FROM measurements;

# Exit
\q
```

#### ✅ VALIDATION CHECKPOINT 5: Database EC2 Complete

**1. Verify PostgreSQL Service**
```bash
sudo systemctl status postgresql
# Should show: active (running)
```

**2. Verify Database and Table**
```bash
psql -U bmi_user -d bmidb -h localhost

# List tables
\dt
# Should show: measurements table

# Check table structure
\d measurements
# Should show all columns: id, weight_kg, height_cm, age, sex, etc.

# Exit
\q
```

**3. Verify Remote Access Configuration**
```bash
# Check PostgreSQL is listening on all interfaces
sudo netstat -plnt | grep 5432
# Should show: 0.0.0.0:5432

# Check pg_hba.conf has remote access rules
sudo cat /etc/postgresql/*/main/pg_hba.conf | grep bmidb
# Should show host entries for 10.0.0.0/16 or 172.31.0.0/16
```

**4. Verify Firewall**
```bash
sudo ufw status
# Should show:
# 5432/tcp   ALLOW       Anywhere
# 22/tcp     ALLOW       Anywhere
```

**5. Document Connection Details**
```bash
# Write these down - you'll need them for Backend EC2!
Database Private IP: ___________________
Database User: bmi_user
Database Name: bmidb
Database Password: ___________________
Connection String: postgresql://bmi_user:PASSWORD@PRIVATE_IP:5432/bmidb
```

**✅ All database checks passed? Proceed to Backend EC2**  
**❌ Any failures? Review logs and troubleshoot before continuing**

---

## Backend EC2 Deployment

### Step 1: Launch Backend EC2 Instance

1. **Navigate to EC2 Console**
   - Click "Launch Instance"

2. **Configure Instance**
   - Name: `bmi-backend-ec2`
   - AMI: Ubuntu Server 22.04 LTS
   - Instance type: t2.micro
   
3. **Network Settings**
   - VPC: `bmi-tracker-vpc`
   - Subnet: `bmi-private-subnet-1`
   - Auto-assign public IP: Disable
   - Security group: `bmi-backend-sg`
   
4. **Key Pair**: `bmi-tracker-key`
   
5. **Launch Instance**

6. **Note Private IP**: Example: `10.0.2.20`

#### ✅ VALIDATION CHECKPOINT 6: Backend EC2 Launch

**1. Verify Instance Running**
```bash
# In AWS Console: EC2 → Instances
✓ Instance Name: bmi-backend-ec2
✓ Instance State: Running
✓ Status Checks: 2/2 checks passed
```

**2. Verify Instance Configuration**
```bash
✓ AMI: Ubuntu Server 22.04 LTS
✓ Instance Type: t2.micro
✓ VPC: bmi-tracker-vpc
✓ Subnet: bmi-private-subnet-1 (10.0.2.0/24)
✓ Auto-assign Public IP: No
✓ Security Group: bmi-backend-sg
✓ Key Pair: bmi-tracker-key
```

**3. Note Private IP**
```bash
Backend EC2 Private IP: ___________________
Example: 10.0.2.20
```

**✅ Instance configured correctly? Proceed to Step 2**

---

### Step 2: Upload Backend Files

```bash
# Upload via bastion or S3 (similar to database)
scp -i bmi-tracker-key.pem -r backend-ec2/ ubuntu@BASTION_IP:~/
ssh -i bmi-tracker-key.pem ubuntu@BASTION_IP
scp -r backend-ec2/ ubuntu@BACKEND_PRIVATE_IP:~/
```

### Step 3: Configure Backend Environment

```bash
# Connect to Backend EC2
cd ~/backend-ec2
cp .env.example .env
nano .env
```

**Edit .env file**:
```env
PORT=3000
NODE_ENV=production

# Use Database EC2 Private IP
DATABASE_URL=postgresql://bmi_user:BMI@Tracker2025!@10.0.3.15:5432/bmidb

# Use Frontend EC2 Public IP (will get this in next section)
FRONTEND_URL=http://FRONTEND_PUBLIC_IP
```

Save and exit (Ctrl+X, Y, Enter)

### Step 4: Test Database Connection

```bash
# Install PostgreSQL client
sudo apt update
sudo apt install -y postgresql-client

# Test connection
psql postgresql://bmi_user:BMI@Tracker2025!@10.0.3.15:5432/bmidb -c "SELECT 1"
```

If successful, you should see:
```
 ?column? 
----------
        1
```

#### ✅ VALIDATION CHECKPOINT 7: Backend Database Connection

**1. Test Database Connectivity**
```bash
# This is CRITICAL - if this fails, backend will not work!
psql $DATABASE_URL -c "SELECT 1"
# Expected: Returns 1
```

**2. Test Database Query**
```bash
psql $DATABASE_URL -c "SELECT COUNT(*) FROM measurements"
# Expected: Returns count (0 if no data yet)
```

**3. Verify Network Connectivity**
```bash
# Test if port 5432 is reachable
telnet DATABASE_PRIVATE_IP 5432
# Expected: Connection successful (Ctrl+C to exit)

# Or use nc (netcat)
nc -zv DATABASE_PRIVATE_IP 5432
# Expected: Connection to DATABASE_PRIVATE_IP 5432 port [tcp/postgresql] succeeded!
```

**✅ Database connection successful? Proceed to deploy**  
**❌ Connection failed? Check:**
- Database EC2 is running
- Security groups allow Backend → Database (port 5432)
- DATABASE_URL is correct
- Password has no typos

---

### Step 5: Deploy Backend

```bash
chmod +x deploy-backend.sh
./deploy-backend.sh
```

The script will:
1. Install Node.js via NVM
2. Install PostgreSQL client
3. Install PM2
4. Install npm dependencies
5. Test database connection
6. Start backend with PM2
7. Configure firewall

### Step 6: Verify Backend Deployment

```bash
# Check PM2 status
pm2 status

# Test health endpoint
curl http://localhost:3000/health

# Check logs
pm2 logs bmi-backend

# Test API endpoints
curl http://localhost:3000/api/measurements
```

Expected health response:
```json
{
  "status": "ok",
  "environment": "production",
  "timestamp": "2025-12-13T..."
}
```

#### ✅ VALIDATION CHECKPOINT 8: Backend EC2 Complete

**1. Verify PM2 Process**
```bash
pm2 status
# Should show:
# │ bmi-backend │ online │ 0 │ 0 │ ... │
```

**2. Verify Backend Health**
```bash
curl http://localhost:3000/health
# Expected: {"status":"ok","environment":"production",...}
```

**3. Verify Database Connection from Backend**
```bash
# Check logs for database connection message
pm2 logs bmi-backend --lines 50 | grep -i database
# Should see: "✅ Database connected successfully at: ..."
```

**4. Test API Endpoints**
```bash
# Test GET measurements (should return empty array initially)
curl http://localhost:3000/api/measurements
# Expected: {"rows":[]}

# Test POST measurement
curl -X POST http://localhost:3000/api/measurements \
  -H "Content-Type: application/json" \
  -d '{"weightKg":70,"heightCm":175,"age":30,"sex":"male","activity":"moderate"}'
# Expected: {"measurement":{"id":1,...}}

# Verify measurement was saved
curl http://localhost:3000/api/measurements
# Expected: {"rows":[{"id":1,...}]}
```

**5. Verify Firewall**
```bash
sudo ufw status
# Should allow:
# 3000/tcp   ALLOW       Anywhere
# 22/tcp     ALLOW       Anywhere
```

**6. Check PM2 Startup**
```bash
pm2 startup
# Should show: "PM2 startup configured"

pm2 save
# Should show: "Successfully saved in ..."
```

**7. Document Backend Details**
```bash
Backend Private IP: ___________________
Backend Port: 3000
Backend Health URL: http://PRIVATE_IP:3000/health
```

**✅ All backend checks passed? Proceed to Frontend EC2**  
**❌ Any failures?**
- Check PM2 logs: `pm2 logs bmi-backend`
- Verify database connection
- Check security groups
- Review environment variables

---

## Frontend EC2 Deployment

### Step 1: Launch Frontend EC2 Instance

1. **Navigate to EC2 Console**
   - Click "Launch Instance"

2. **Configure Instance**
   - Name: `bmi-frontend-ec2`
   - AMI: Ubuntu Server 22.04 LTS
   - Instance type: t2.micro
   
3. **Network Settings**
   - VPC: `bmi-tracker-vpc`
   - Subnet: `bmi-public-subnet`
   - Auto-assign public IP: Enable
   - Security group: `bmi-frontend-sg`
   
4. **Key Pair**: `bmi-tracker-key`
   
5. **Launch Instance**

6. **Note Public IP**: Example: `54.123.45.67`

### Step 2: Allocate and Associate Elastic IP (Recommended)

1. **Allocate Elastic IP**
   - Go to EC2 → Elastic IPs
   - Click "Allocate Elastic IP address"
   - Click "Allocate"

2. **Associate with Frontend EC2**
   - Select the new Elastic IP
   - Actions → Associate Elastic IP address
   - Instance: `bmi-frontend-ec2`
   - Click "Associate"

3. **Note Elastic IP**: Example: `52.123.45.67`
#### ✅ VALIDATION CHECKPOINT 9: Frontend EC2 Launch

**1. Verify Instance Running**
```bash
# In AWS Console: EC2 → Instances
✓ Instance Name: bmi-frontend-ec2
✓ Instance State: Running
✓ Status Checks: 2/2 checks passed
```

**2. Verify Instance Configuration**
```bash
✓ AMI: Ubuntu Server 22.04 LTS
✓ Instance Type: t2.micro
✓ VPC: bmi-tracker-vpc
✓ Subnet: bmi-public-subnet (10.0.1.0/24)
✓ Auto-assign Public IP: Yes (or Elastic IP associated)
✓ Security Group: bmi-frontend-sg
✓ Key Pair: bmi-tracker-key
```

**3. Verify Elastic IP**
```bash
# In AWS Console: EC2 → Elastic IPs
✓ Elastic IP is allocated
✓ Associated with bmi-frontend-ec2
✓ Status: Associated
```

**4. Test SSH Connection**
```bash
# From your local machine
ssh -i bmi-tracker-key.pem ubuntu@FRONTEND_ELASTIC_IP

# If successful, you should be connected to the instance
ubuntu@ip-10-0-1-10:~$
```

**5. Document Frontend Details**
```bash
Frontend Public IP: ___________________
Frontend Elastic IP: ___________________
Frontend Private IP: ___________________
```

**✅ Can SSH to frontend? Proceed to Step 3**  
**❌ Cannot connect?**
- Check Security Group allows SSH from your IP
- Verify key pair permissions (should be 400)
- Confirm instance is in public subnet
- Check Elastic IP is associated

---
### Step 3: Upload Frontend Files

```bash
# From your local machine
scp -i bmi-tracker-key.pem -r frontend-ec2/ ubuntu@FRONTEND_PUBLIC_IP:~/
```

### Step 4: Update Backend with Frontend URL

```bash
# Connect to Backend EC2
ssh ubuntu@BACKEND_PRIVATE_IP

# Update .env
nano ~/backend-ec2/.env
# Change FRONTEND_URL to Frontend's Elastic IP
# FRONTEND_URL=http://52.123.45.67

# Restart backend
pm2 restart bmi-backend
```

### Step 5: Configure Frontend Environment

```bash
# Connect to Frontend EC2
ssh -i bmi-tracker-key.pem ubuntu@FRONTEND_PUBLIC_IP

cd ~/frontend-ec2
cp .env.example .env
nano .env
```

**Edit .env file**:
```env
# Use Backend EC2 Private IP
VITE_BACKEND_URL=http://10.0.2.20:3000
```

Save and exit

### Step 6: Deploy Frontend

```bash
chmod +x deploy-frontend.sh
./deploy-frontend.sh
```

The script will:
1. Install Node.js via NVM
2. Install Nginx
3. Install npm dependencies
4. Build React app
5. Deploy to /var/www/bmi-health-tracker
6. Configure Nginx with backend proxy
7. Configure firewall

### Step 7: Verify Frontend Deployment

```bash
# Check Nginx status
sudo systemctl status nginx

# Test Nginx configuration
sudo nginx -t

# Test local access
curl http://localhost

# Test API proxy
curl http://localhost/api/measurements
```

#### ✅ VALIDATION CHECKPOINT 10: Frontend EC2 Complete

**1. Verify Nginx Service**
```bash
sudo systemctl status nginx
# Should show: active (running)
```

**2. Verify Nginx Configuration**
```bash
sudo nginx -t
# Expected: nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**3. Verify Application Files Deployed**
```bash
ls -la /var/www/bmi-health-tracker/
# Should show: index.html, assets/, favicon.ico, etc.

# Check index.html exists and has content
head -n 5 /var/www/bmi-health-tracker/index.html
# Should show HTML content
```

**4. Test Local Frontend Access**
```bash
curl http://localhost
# Should return HTML content (index.html)

curl -I http://localhost
# Expected: HTTP/1.1 200 OK
```

**5. Test Backend Connectivity from Frontend**
```bash
# Test if frontend can reach backend
curl http://BACKEND_PRIVATE_IP:3000/health
# Expected: {"status":"ok",...}

# Test API proxy
curl http://localhost/api/health
# Expected: {"status":"ok",...}
```

**6. Verify Nginx Proxy Configuration**
```bash
sudo cat /etc/nginx/sites-available/bmi-frontend | grep proxy_pass
# Should show: proxy_pass http://BACKEND_PRIVATE_IP:3000/api/;
```

**7. Check Nginx Logs for Errors**
```bash
sudo tail -n 20 /var/log/nginx/bmi-frontend-error.log
# Should be empty or no critical errors
```

**8. Verify Firewall**
```bash
sudo ufw status
# Should show:
# 80/tcp     ALLOW       Anywhere
# 443/tcp    ALLOW       Anywhere (if HTTPS configured)
# 22/tcp     ALLOW       Anywhere
```

**9. Test External Access**
```bash
# From your local machine (not the EC2 instance)
curl http://FRONTEND_ELASTIC_IP
# Should return HTML content

# Test in browser
Open: http://FRONTEND_ELASTIC_IP
# Should see the BMI Health Tracker application
```

**10. Check Browser Console**
```bash
# In browser, open Developer Tools (F12)
# Console tab should have no errors
# Network tab should show successful API calls
```

**✅ All frontend checks passed? Proceed to End-to-End Verification**  
**❌ Any failures?**
- Nginx not running: `sudo systemctl start nginx`
- Configuration errors: `sudo nginx -t`
- Backend unreachable: Check security groups and backend IP
- Files not deployed: Re-run build and deployment

---

## Post-Deployment Verification

### Complete End-to-End Test

1. **Open Browser**
   ```
   http://FRONTEND_ELASTIC_IP
   ```
   or
   ```
   http://52.123.45.67
   ```

2. **Test Form Submission**
   - Fill out the measurement form:
     - Weight: 70 kg
     - Height: 175 cm
     - Age: 30
     - Sex: Male
     - Activity: Moderate
   - Click "Save Measurement"
   - Should see success message

3. **Verify Data Display**
   - Check "Recent Measurements" section
   - Should see your new measurement
   - Should display calculated BMI, BMR, and calories

4. **Check Trend Chart**
   - Should display 30-day BMI trend chart
   - Add measurements over multiple days to see trends

### Verification Checklist

**Frontend:**
- [ ] Frontend loads in browser at http://ELASTIC_IP
- [ ] No 404 or 502 errors
- [ ] Page styling loads correctly
- [ ] No console errors in browser developer tools

**Functionality:**
- [ ] Can submit new measurement form
- [ ] Success message appears after submission
- [ ] Measurement appears in "Recent Measurements" list
- [ ] BMI calculation is correct (e.g., 70kg / 1.75m² = 22.9)
- [ ] BMR and daily calories are displayed
- [ ] Chart displays (even if empty initially)

**API:**
- [ ] API requests complete successfully (check Network tab)
- [ ] POST /api/measurements returns 201 status
- [ ] GET /api/measurements returns data
- [ ] GET /api/measurements/trends works
- [ ] No CORS errors

**Data Persistence:**
- [ ] After page refresh, submitted measurements still appear
- [ ] Can submit multiple measurements
- [ ] All data is saved to database

**Cross-Component:**
- [ ] Stats cards update with latest measurement
- [ ] Total records count increases
- [ ] After adding measurements over multiple days, trend chart shows data

### Check All Services

**Database EC2**:
```bash
sudo systemctl status postgresql
psql -U bmi_user -d bmidb -h localhost -c "SELECT COUNT(*) FROM measurements"
```

**Backend EC2**:
```bash
pm2 status
curl http://localhost:3000/health
```

**Frontend EC2**:
```bash
sudo systemctl status nginx
curl http://localhost
```

#### ✅ FINAL VALIDATION: Complete System Check

**Run this comprehensive test to verify everything works end-to-end:**

**1. Three-Tier Connectivity Test**
```bash
# From your local machine
echo "Testing complete application stack..."

# Test 1: Frontend accessible
echo "Test 1: Frontend Access"
curl -I http://FRONTEND_ELASTIC_IP
# Expected: HTTP/1.1 200 OK

# Test 2: API through frontend proxy
echo "Test 2: API Proxy"
curl http://FRONTEND_ELASTIC_IP/api/health
# Expected: {"status":"ok"}

# Test 3: Submit measurement through API
echo "Test 3: Submit Measurement"
curl -X POST http://FRONTEND_ELASTIC_IP/api/measurements \
  -H "Content-Type: application/json" \
  -d '{"weightKg":75,"heightCm":180,"age":25,"sex":"male","activity":"moderate"}'
# Expected: {"measurement":{...}}

# Test 4: Retrieve measurements
echo "Test 4: Retrieve Data"
curl http://FRONTEND_ELASTIC_IP/api/measurements
# Expected: {"rows":[...]}

echo "All tests completed!"
```

**2. Service Health Check**
```bash
# Database EC2
ssh -i key.pem ubuntu@DATABASE_IP "sudo systemctl is-active postgresql"
# Expected: active

# Backend EC2
ssh -i key.pem ubuntu@BACKEND_IP "pm2 status | grep online"
# Expected: bmi-backend│online

# Frontend EC2
ssh -i key.pem ubuntu@FRONTEND_IP "sudo systemctl is-active nginx"
# Expected: active
```

**3. Security Validation**
```bash
# Verify private instances are not directly accessible
curl -I http://BACKEND_PRIVATE_IP:3000/health --max-time 5
# Expected: Timeout (good - not publicly accessible)

curl -I http://DATABASE_PRIVATE_IP:5432 --max-time 5
# Expected: Timeout (good - not publicly accessible)
```

**4. Log Check**
```bash
# No errors in logs
ssh -i key.pem ubuntu@FRONTEND_IP "sudo tail -20 /var/log/nginx/bmi-frontend-error.log"
# Should be empty or no critical errors

ssh -i key.pem ubuntu@BACKEND_IP "pm2 logs bmi-backend --lines 50 --nostream | grep -i error"
# Should have no error messages
```

**✅ SUCCESS CRITERIA:**
- ✓ Frontend returns 200 OK
- ✓ API health endpoint responds
- ✓ Can submit and retrieve measurements
- ✓ All services are active
- ✓ Private instances not publicly accessible
- ✓ No errors in logs

**If all checks pass: 🎉 DEPLOYMENT SUCCESSFUL!**

**If any checks fail: See Troubleshooting Guide below**

---

## Troubleshooting Guide

### Issue: Cannot SSH to Private EC2 Instances

**Solution**:
1. Use bastion host in public subnet
2. Or use AWS Systems Manager Session Manager
3. Ensure security groups allow SSH from your IP

### Issue: Backend Cannot Connect to Database

**Symptoms**: 500 errors, "Database connection failed"

**Checks**:
1. Database EC2 Security Group allows port 5432 from Backend SG
2. Backend EC2 Security Group allows outbound to port 5432
3. DATABASE_URL in backend .env is correct
4. PostgreSQL is running: `sudo systemctl status postgresql`

**Test**:
```bash
# From Backend EC2
psql $DATABASE_URL -c "SELECT 1"
```

### Issue: Frontend Cannot Reach Backend

**Symptoms**: API errors, no data loading

**Checks**:
1. Frontend EC2 Security Group allows outbound to port 3000
2. Backend EC2 Security Group allows inbound 3000 from Frontend SG
3. Backend is running: `pm2 status`
4. nginx.conf has correct Backend IP

**Test**:
```bash
# From Frontend EC2
curl http://BACKEND_PRIVATE_IP:3000/health
```

### Issue: Application Not Accessible from Internet

**Symptoms**: Browser cannot reach application

**Checks**:
1. Frontend EC2 has public/Elastic IP
2. Frontend SG allows inbound HTTP (80) from 0.0.0.0/0
3. Nginx is running: `sudo systemctl status nginx`
4. Firewall allows port 80: `sudo ufw status`

**Test**:
```bash
# From Frontend EC2
curl http://localhost

# From your local machine
curl http://FRONTEND_PUBLIC_IP
```

### Issue: PM2 Process Keeps Restarting

**Symptoms**: Backend continuously restarts

**Check logs**:
```bash
pm2 logs bmi-backend --lines 100
```

**Common causes**:
- Database connection issues
- Missing environment variables
- Port already in use
- Insufficient memory

### Issue: Nginx 502 Bad Gateway

**Symptoms**: Frontend shows "502 Bad Gateway"

**Checks**:
1. Backend is running: `pm2 status`
2. Backend responds: `curl http://localhost:3000/health`
3. Nginx proxy configuration is correct

**Check logs**:
```bash
sudo tail -f /var/log/nginx/bmi-frontend-error.log
```

### Getting Help

1. Check service status on each EC2
2. Review application logs
3. Verify security group configurations
4. Test connectivity between instances
5. Check environment variables
6. Review AGENT.md for detailed documentation

---

## Next Steps

### Optional Enhancements

1. **Setup HTTPS**:
   - Obtain SSL certificate (Let's Encrypt)
   - Configure Nginx for HTTPS
   - Update security groups

2. **Setup Monitoring**:
   - Configure CloudWatch alarms
   - Setup log aggregation
   - Monitor resource usage

3. **Implement Backups**:
   - Create database backup script
   - Schedule automated backups
   - Store backups in S3

4. **Add Domain Name**:
   - Register domain
   - Create Route 53 hosted zone
   - Point domain to Frontend Elastic IP

---

## Deployment Checklist

### Pre-Deployment
- [ ] AWS account ready
- [ ] EC2 key pair created
- [ ] VPC and subnets configured
- [ ] Security groups created
- [ ] Project files ready

### Database EC2
- [ ] Instance launched
- [ ] setup-database.sh executed
- [ ] Connection string noted
- [ ] Database accessible from Backend

### Backend EC2
- [ ] Instance launched
- [ ] .env configured with Database URL
- [ ] deploy-backend.sh executed
- [ ] PM2 running successfully
- [ ] API endpoints responding

### Frontend EC2
- [ ] Instance launched
- [ ] Elastic IP associated
- [ ] .env configured with Backend URL
- [ ] deploy-frontend.sh executed
- [ ] Nginx serving application
- [ ] Application accessible from internet

### Verification
- [ ] End-to-end test completed
- [ ] All measurements working
- [ ] No console errors
- [ ] Services monitored and stable

---

**Congratulations! Your BMI Health Tracker is now deployed on AWS!** 🎉

For ongoing maintenance and updates, refer to the AGENT.md documentation.
