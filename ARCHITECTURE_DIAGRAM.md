# Architecture Diagram - Multiple EC2 3-Tier Deployment

## Visual Architecture

```
                           ┌──────────────────────────────────┐
                           │      INTERNET USERS              │
                           │      (Web Browsers)              │
                           └────────────┬─────────────────────┘
                                        │
                                        │ HTTP/HTTPS
                                        │ Port 80/443
                                        │
                           ┌────────────▼─────────────────────┐
                           │     AWS VPC                       │
                           │  (10.0.0.0/16)                   │
                           │                                   │
┌──────────────────────────┼───────────────────────────────────┼──────────────────────────────┐
│                          │                                   │                              │
│  ┌───────────────────────┼───────────────────────────────────┼────────────────────────┐    │
│  │  PUBLIC SUBNET        │                                   │                        │    │
│  │  (10.0.1.0/24)        │                                   │                        │    │
│  │                       │                                   │                        │    │
│  │    ┏━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━━━━┓         │                        │    │
│  │    ┃   FRONTEND EC2                            ┃         │                        │    │
│  │    ┃   Ubuntu 22.04                            ┃         │                        │    │
│  │    ┃   ─────────────────────────────────────   ┃         │                        │    │
│  │    ┃   • Nginx Web Server                      ┃         │                        │    │
│  │    ┃   • React App (Static Files)              ┃         │                        │    │
│  │    ┃   • Port 80 (HTTP)                        ┃         │                        │    │
│  │    ┃   • Port 443 (HTTPS)                      ┃         │                        │    │
│  │    ┃   • Public IP: 52.123.45.67               ┃         │                        │    │
│  │    ┃   • Private IP: 10.0.1.10                 ┃         │                        │    │
│  │    ┃                                            ┃         │                        │    │
│  │    ┃   nginx.conf:                              ┃         │                        │    │
│  │    ┃   location /api/ {                         ┃         │                        │    │
│  │    ┃     proxy_pass → Backend EC2:3000         ┃         │                        │    │
│  │    ┃   }                                        ┃         │                        │    │
│  │    ┗━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━┛         │                        │    │
│  │                       │                                   │                        │    │
│  └───────────────────────┼───────────────────────────────────┼────────────────────────┘    │
│                          │                                   │                              │
│                          │ HTTP API Calls                    │                              │
│                          │ Port 3000                         │                              │
│                          │ Private Network                   │                              │
│  ┌───────────────────────┼───────────────────────────────────┼────────────────────────┐    │
│  │  PRIVATE SUBNET 1     │                                   │                        │    │
│  │  (10.0.2.0/24)        │                                   │                        │    │
│  │                       │                                   │                        │    │
│  │    ┏━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━━━━┓         │                        │    │
│  │    ┃   BACKEND EC2                             ┃         │                        │    │
│  │    ┃   Ubuntu 22.04                            ┃         │                        │    │
│  │    ┃   ─────────────────────────────────────   ┃         │                        │    │
│  │    ┃   • Node.js 18 (via NVM)                  ┃         │                        │    │
│  │    ┃   • Express.js REST API                   ┃         │                        │    │
│  │    ┃   • PM2 Process Manager                   ┃         │                        │    │
│  │    ┃   • Port 3000 (API)                       ┃         │                        │    │
│  │    ┃   • Private IP: 10.0.2.20                 ┃         │                        │    │
│  │    ┃                                            ┃         │                        │    │
│  │    ┃   API Routes:                              ┃         │                        │    │
│  │    ┃   • POST   /api/measurements              ┃         │                        │    │
│  │    ┃   • GET    /api/measurements              ┃         │                        │    │
│  │    ┃   • GET    /api/measurements/trends       ┃         │                        │    │
│  │    ┃   • GET    /health                        ┃         │                        │    │
│  │    ┗━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━┛         │                        │    │
│  │                       │                                   │                        │    │
│  └───────────────────────┼───────────────────────────────────┼────────────────────────┘    │
│                          │                                   │                              │
│                          │ PostgreSQL Queries                │                              │
│                          │ Port 5432                         │                              │
│                          │ Private Network                   │                              │
│  ┌───────────────────────┼───────────────────────────────────┼────────────────────────┐    │
│  │  PRIVATE SUBNET 2     │                                   │                        │    │
│  │  (10.0.3.0/24)        │                                   │                        │    │
│  │                       │                                   │                        │    │
│  │    ┏━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━━━━┓         │                        │    │
│  │    ┃   DATABASE EC2                            ┃         │                        │    │
│  │    ┃   Ubuntu 22.04                            ┃         │                        │    │
│  │    ┃   ─────────────────────────────────────   ┃         │                        │    │
│  │    ┃   • PostgreSQL 14+                        ┃         │                        │    │
│  │    ┃   • Port 5432                             ┃         │                        │    │
│  │    ┃   • Private IP: 10.0.3.15                 ┃         │                        │    │
│  │    ┃                                            ┃         │                        │    │
│  │    ┃   Database: bmidb                          ┃         │                        │    │
│  │    ┃   User: bmi_user                          ┃         │                        │    │
│  │    ┃                                            ┃         │                        │    │
│  │    ┃   Tables:                                  ┃         │                        │    │
│  │    ┃   • measurements (BMI data)               ┃         │                        │    │
│  │    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛         │                        │    │
│  │                                                            │                        │    │
│  └────────────────────────────────────────────────────────────┼────────────────────────┘    │
│                                                               │                              │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐    │
│  │  NETWORK COMPONENTS                                                                  │    │
│  │                                                                                       │    │
│  │  • Internet Gateway  → Connected to Public Subnet                                   │    │
│  │  • NAT Gateway       → Allows Private Subnets to access Internet                    │    │
│  │  • Route Tables      → Public routes to IGW, Private routes to NAT                  │    │
│  │  • Security Groups   → Firewall rules for each EC2 instance                         │    │
│  └───────────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

## Security Groups Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        SECURITY GROUP RULES                              │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐      ┌──────────────────────┐      ┌──────────────────────┐
│  Frontend SG         │      │  Backend SG          │      │  Database SG         │
│                      │      │                      │      │                      │
│  INBOUND:            │      │  INBOUND:            │      │  INBOUND:            │
│  • 80 ← 0.0.0.0/0   │      │  • 3000 ← Frontend  │      │  • 5432 ← Backend   │
│  • 443 ← 0.0.0.0/0  │      │  • 22 ← Admin IP    │      │  • 22 ← Admin IP    │
│  • 22 ← Admin IP    │      │                      │      │                      │
│                      │      │  OUTBOUND:           │      │  OUTBOUND:           │
│  OUTBOUND:           │      │  • 5432 → Database  │      │  • All traffic       │
│  • 3000 → Backend   │      │  • 80/443 → Internet│      │                      │
│  • 80/443 → Internet│      │                      │      │                      │
└──────────────────────┘      └──────────────────────┘      └──────────────────────┘
```

## Data Flow

### User Request Flow
```
1. User opens http://52.123.45.67
   ↓
2. DNS resolves to Frontend EC2 Public IP
   ↓
3. Request hits Nginx on Frontend EC2 (Port 80)
   ↓
4. Nginx serves index.html and static assets
   ↓
5. React app loads in browser
```

### API Call Flow
```
1. User submits measurement form
   ↓
2. React sends POST to /api/measurements
   ↓
3. Nginx proxy forwards to Backend EC2:3000
   ↓
4. Express API receives request
   ↓
5. Backend calculates BMI/BMR/calories
   ↓
6. Backend queries PostgreSQL on Database EC2:5432
   ↓
7. Database inserts data and returns result
   ↓
8. Backend sends response to Frontend
   ↓
9. Frontend displays success message and updates list
```

## Network Isolation

```
┌─────────────────────────────────────────────────────┐
│  INTERNET                                            │
│  (Public Access)                                     │
└───────────────┬─────────────────────────────────────┘
                │
                │ Can Access
                ↓
        ┌───────────────┐
        │  Frontend EC2 │ ← Only component with public IP
        │  (Public)     │
        └───────┬───────┘
                │
                │ Private Network
                │ Can Access
                ↓
        ┌───────────────┐
        │  Backend EC2  │ ← No public IP
        │  (Private)    │
        └───────┬───────┘
                │
                │ Private Network
                │ Can Access
                ↓
        ┌───────────────┐
        │  Database EC2 │ ← No public IP
        │  (Private)    │ ← Most secure
        └───────────────┘
```

## Component Details

### Frontend EC2 Specifications
```yaml
Operating System: Ubuntu 22.04 LTS
Instance Type: t2.micro (1 vCPU, 1GB RAM)
Storage: 8 GB gp3
Network: Public Subnet
Software Stack:
  - Nginx 1.18+
  - Node.js 18 LTS (for building)
  - React 18.2
  - Vite 5.0
Services:
  - Nginx (Port 80, 443)
```

### Backend EC2 Specifications
```yaml
Operating System: Ubuntu 22.04 LTS
Instance Type: t2.micro (1 vCPU, 1GB RAM)
Storage: 8 GB gp3
Network: Private Subnet
Software Stack:
  - Node.js 18 LTS
  - Express.js 4.18
  - PM2 (Process Manager)
  - PostgreSQL Client
Services:
  - Node.js API (Port 3000)
  - PM2 (Process Manager)
```

### Database EC2 Specifications
```yaml
Operating System: Ubuntu 22.04 LTS
Instance Type: t2.micro (1 vCPU, 1GB RAM)
Storage: 8 GB gp3
Network: Private Subnet
Software Stack:
  - PostgreSQL 14+
Services:
  - PostgreSQL (Port 5432)
```

## Deployment Scripts

```
database-ec2/setup-database.sh
├── Install PostgreSQL
├── Create database user
├── Create database
├── Run migrations
├── Configure remote access
└── Setup firewall

backend-ec2/deploy-backend.sh
├── Install Node.js (NVM)
├── Install PostgreSQL client
├── Install PM2
├── Install npm dependencies
├── Test database connection
├── Start API with PM2
└── Configure firewall

frontend-ec2/deploy-frontend.sh
├── Install Node.js (NVM)
├── Install Nginx
├── Install npm dependencies
├── Build React app
├── Deploy to /var/www
├── Configure Nginx
└── Configure firewall
```

## Scaling Strategy

### Horizontal Scaling
```
Current:
  1 Frontend EC2 → 1 Backend EC2 → 1 Database EC2

Scale to:
  Load Balancer
       ↓
  3 Frontend EC2s → 5 Backend EC2s → RDS PostgreSQL (Multi-AZ)
```

### Vertical Scaling
```
t2.micro (1 vCPU, 1GB)
    ↓
t2.small (1 vCPU, 2GB)
    ↓
t2.medium (2 vCPU, 4GB)
    ↓
t2.large (2 vCPU, 8GB)
```

## Monitoring Points

```
Frontend EC2:
  - Nginx access logs
  - Nginx error logs
  - CPU/Memory usage
  - Network traffic

Backend EC2:
  - PM2 logs
  - API response times
  - CPU/Memory usage
  - Database connection pool

Database EC2:
  - PostgreSQL logs
  - Query performance
  - Connection count
  - Disk usage
```

---

This architecture provides a secure, scalable, and maintainable 3-tier application deployment on AWS EC2.
