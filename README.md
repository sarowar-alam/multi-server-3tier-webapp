# BMI Health Tracker - Multiple EC2 3-Tier Web Application

A production-ready 3-tier web application deployed across multiple AWS EC2 instances for tracking Body Mass Index (BMI), Basal Metabolic Rate (BMR), and daily calorie requirements.

## 🏗️ Architecture Overview

This application is designed to run on **three separate Ubuntu EC2 instances**:

```
┌─────────────────────────────────────────────────────────┐
│                     Internet Users                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │     FRONTEND EC2           │
        │   (Public Subnet)          │
        │                            │
        │  • Nginx Web Server        │
        │  • React Static Files      │
        │  • Port 80/443             │
        │  • Public IP Address       │
        └────────────┬───────────────┘
                     │
                     │ HTTP API Calls (Port 3000)
                     │
                     ▼
        ┌────────────────────────────┐
        │     BACKEND EC2            │
        │   (Private Subnet)         │
        │                            │
        │  • Node.js Express API     │
        │  • PM2 Process Manager     │
        │  • Port 3000               │
        │  • Private IP Only         │
        └────────────┬───────────────┘
                     │
                     │ PostgreSQL (Port 5432)
                     │
                     ▼
        ┌────────────────────────────┐
        │     DATABASE EC2           │
        │   (Private Subnet)         │
        │                            │
        │  • PostgreSQL Server       │
        │  • Port 5432               │
        │  • Private IP Only         │
        └────────────────────────────┘
```

## 🚀 Features

- **Real-time Health Metrics**: Calculate BMI, BMR, and daily calorie needs
- **Historical Tracking**: Store and view past measurements
- **Trend Visualization**: 30-day BMI trend charts
- **Responsive Design**: Works on desktop and mobile devices
- **Scalable Architecture**: Separate tiers for easy scaling
- **Secure Deployment**: Database and backend in private subnets

## 📋 Prerequisites

### AWS Requirements
- AWS Account with EC2 access
- VPC with public and private subnets
- 3 EC2 instances (Ubuntu 22.04 LTS)
- Elastic IP for frontend
- Properly configured Security Groups

### Local Requirements (for deployment)
- SSH client
- SSH key pair for EC2 instances
- Basic knowledge of AWS console

## 📦 Project Structure

```
multiple-ec2-3tier-webapp/
│
├── frontend-ec2/          # Frontend deployment files
│   ├── src/               # React source code
│   ├── deploy-frontend.sh # Automated deployment script
│   ├── nginx.conf         # Nginx configuration
│   └── package.json       # Dependencies
│
├── backend-ec2/           # Backend deployment files
│   ├── src/               # Express API source code
│   ├── deploy-backend.sh  # Automated deployment script
│   ├── ecosystem.config.js # PM2 configuration
│   └── package.json       # Dependencies
│
├── database-ec2/          # Database setup files
│   ├── migrations/        # SQL migration files
│   ├── setup-database.sh  # Automated setup script
│   └── DATABASE_CONFIG.md # Configuration guide
│
├── AGENT.md              # Complete project documentation
└── README.md             # This file
```

## 🎯 Quick Start Deployment

### Step 1: Launch EC2 Instances

Create 3 Ubuntu 22.04 LTS EC2 instances:

1. **Frontend EC2** (Public Subnet):
   - Instance type: t2.micro (minimum)
   - Auto-assign Public IP: Yes
   - Associate Elastic IP (recommended)

2. **Backend EC2** (Private Subnet):
   - Instance type: t2.micro (minimum)
   - Auto-assign Public IP: No

3. **Database EC2** (Private Subnet):
   - Instance type: t2.micro (minimum)
   - Auto-assign Public IP: No

### Step 2: Configure Security Groups

#### Frontend Security Group
```
Inbound:
- HTTP (80) from 0.0.0.0/0
- HTTPS (443) from 0.0.0.0/0
- SSH (22) from YOUR_IP

Outbound:
- Custom TCP (3000) to Backend SG
- HTTP/HTTPS to 0.0.0.0/0
```

#### Backend Security Group
```
Inbound:
- Custom TCP (3000) from Frontend SG
- SSH (22) from YOUR_IP

Outbound:
- PostgreSQL (5432) to Database SG
- HTTP/HTTPS to 0.0.0.0/0
```

#### Database Security Group
```
Inbound:
- PostgreSQL (5432) from Backend SG
- SSH (22) from YOUR_IP
```

### Step 3: Deploy Database EC2

```bash
# Connect to Database EC2
ssh -i your-key.pem ubuntu@DATABASE_EC2_IP

# Upload files
scp -i your-key.pem -r database-ec2/ ubuntu@DATABASE_EC2_IP:~/

# Run setup
cd database-ec2
chmod +x setup-database.sh
./setup-database.sh
```

**Important**: Note the database connection string provided at the end!

### Step 4: Deploy Backend EC2

```bash
# Connect to Backend EC2
ssh -i your-key.pem ubuntu@BACKEND_EC2_IP

# Upload files
scp -i your-key.pem -r backend-ec2/ ubuntu@BACKEND_EC2_IP:~/

# Configure environment
cd backend-ec2
cp .env.example .env
nano .env  # Update DATABASE_URL and FRONTEND_URL

# Run deployment
chmod +x deploy-backend.sh
./deploy-backend.sh
```

### Step 5: Deploy Frontend EC2

```bash
# Connect to Frontend EC2
ssh -i your-key.pem ubuntu@FRONTEND_EC2_PUBLIC_IP

# Upload files
scp -i your-key.pem -r frontend-ec2/ ubuntu@FRONTEND_EC2_PUBLIC_IP:~/

# Configure environment
cd frontend-ec2
cp .env.example .env
nano .env  # Update VITE_BACKEND_URL

# Run deployment
chmod +x deploy-frontend.sh
./deploy-frontend.sh
```

### Step 6: Access Your Application

Open your browser and navigate to:
```
http://YOUR_FRONTEND_EC2_PUBLIC_IP
```

## 🔧 Configuration Details

### Environment Variables

#### Frontend EC2 (.env)
```env
VITE_BACKEND_URL=http://BACKEND_EC2_PRIVATE_IP:3000
```

#### Backend EC2 (.env)
```env
PORT=3000
NODE_ENV=production
DATABASE_URL=postgresql://bmi_user:PASSWORD@DATABASE_EC2_PRIVATE_IP:5432/bmidb
FRONTEND_URL=http://FRONTEND_EC2_PUBLIC_IP
```

### Network Configuration

| Component | Port | Access |
|-----------|------|--------|
| Frontend (Nginx) | 80 | Public Internet |
| Frontend (HTTPS) | 443 | Public Internet |
| Backend (API) | 3000 | Frontend EC2 only |
| Database (PostgreSQL) | 5432 | Backend EC2 only |

## 📊 API Endpoints

### Health Check
```
GET /health
```

### Measurements
```
POST /api/measurements    # Create new measurement
GET  /api/measurements    # Get all measurements
GET  /api/measurements/trends  # Get 30-day BMI trends
```

## 🧪 Testing

### Test Database Connection
```bash
# From Backend EC2
psql postgresql://bmi_user:PASSWORD@DATABASE_PRIVATE_IP:5432/bmidb -c "SELECT 1"
```

### Test Backend API
```bash
# From Backend EC2
curl http://localhost:3000/health
curl http://localhost:3000/api/measurements
```

### Test Frontend
```bash
# From Frontend EC2
curl http://localhost
curl http://localhost/api/measurements
```

### End-to-End Test
1. Open application in browser
2. Fill out the measurement form
3. Submit a new measurement
4. Verify it appears in the recent measurements list
5. Check that the 30-day trend chart displays

## 🔍 Monitoring & Logs

### Frontend Logs
```bash
# Nginx access logs
sudo tail -f /var/log/nginx/bmi-frontend-access.log

# Nginx error logs
sudo tail -f /var/log/nginx/bmi-frontend-error.log
```

### Backend Logs
```bash
# PM2 logs
pm2 logs bmi-backend

# PM2 monitoring dashboard
pm2 monit
```

### Database Logs
```bash
# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*-main.log
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Frontend cannot connect to Backend
**Symptoms**: API requests fail, no data displays

**Solutions**:
- Verify Backend EC2 is running: `pm2 status`
- Check Security Group allows Frontend → Backend (port 3000)
- Verify nginx.conf has correct Backend IP
- Test from Frontend: `curl http://BACKEND_IP:3000/health`

#### 2. Backend cannot connect to Database
**Symptoms**: 500 errors, database connection failures

**Solutions**:
- Verify PostgreSQL is running: `sudo systemctl status postgresql`
- Check Security Group allows Backend → Database (port 5432)
- Verify DATABASE_URL in .env is correct
- Test from Backend: `psql $DATABASE_URL -c "SELECT 1"`

#### 3. Application not accessible from internet
**Symptoms**: Cannot reach frontend URL

**Solutions**:
- Verify Elastic IP is associated with Frontend EC2
- Check Security Group allows HTTP (80) from 0.0.0.0/0
- Verify Nginx is running: `sudo systemctl status nginx`
- Check firewall: `sudo ufw status`

## 💰 Cost Estimation

### AWS Free Tier (First 12 Months)
- 3 × t2.micro instances: 750 hours/month per instance (FREE)
- Elastic IP: Free when associated
- Data transfer: 15 GB/month (FREE)

### After Free Tier
- 3 × t2.micro instances: ~$7.50/month each = ~$22.50/month
- Elastic IP: Free when associated
- Data transfer: First 1 GB free, then ~$0.09/GB

**Total**: ~$25-30/month

## 📈 Scaling Recommendations

### When to Scale

Scale up when you experience:
- High CPU usage (>70% sustained)
- High memory usage (>80%)
- Slow response times
- Increased user traffic

### Scaling Options

1. **Vertical Scaling**:
   - Upgrade instance types (t2.micro → t2.small → t2.medium)
   - Increase PM2 instances for backend
   - Tune PostgreSQL configuration

2. **Horizontal Scaling**:
   - Add Application Load Balancer for frontend
   - Deploy multiple backend instances
   - Migrate to RDS PostgreSQL for managed database

3. **Alternative Architectures**:
   - Use S3 + CloudFront for frontend (static hosting)
   - Use Elastic Beanstalk for backend
   - Use RDS Multi-AZ for database high availability

## 🔒 Security Best Practices

- ✅ Database isolated in private subnet
- ✅ Backend isolated in private subnet
- ✅ Strong database passwords
- ✅ Minimal Security Group permissions
- ✅ Regular security updates
- ✅ Encrypted connections (HTTPS recommended)
- ✅ Database backups
- ✅ CloudWatch monitoring

## 📚 Additional Documentation

- **AGENT.md**: Complete project documentation with all file contents
- **DATABASE_CONFIG.md**: Database configuration and troubleshooting
- **deploy-*.sh**: Automated deployment scripts with inline comments

## 🤝 Contributing

This is a demonstration project. For production use, consider:
- Adding user authentication
- Implementing HTTPS with SSL/TLS certificates
- Setting up automated backups
- Adding monitoring and alerting (CloudWatch)
- Implementing CI/CD pipeline

## 📄 License

MIT License - Free to use and modify

## 💡 Support

For issues and questions:
1. Check the troubleshooting section
2. Review AGENT.md for detailed documentation
3. Check AWS CloudWatch logs
4. Review application logs on each EC2 instance

---

**Built with ❤️ for learning AWS multi-tier architecture**

**Version**: 1.0.0  
**Last Updated**: December 13, 2025
