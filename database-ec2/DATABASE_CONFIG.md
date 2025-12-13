# BMI Health Tracker - Database Configuration Notes

## PostgreSQL Configuration

### Database Details
- **Database Name**: bmidb
- **Database User**: bmi_user
- **Port**: 5432 (PostgreSQL default)

### Tables
- **measurements**: Stores all health measurement data
  - Includes BMI, BMR, daily calories calculations
  - Indexed on created_at and bmi for performance

### Remote Access Configuration

The setup script configures PostgreSQL to accept connections from the Backend EC2 instance:

1. **postgresql.conf**: Sets `listen_addresses = '*'` to allow network connections
2. **pg_hba.conf**: Adds rules to allow MD5 authentication from private subnet

### Security Considerations

1. **Network Security**:
   - Database EC2 should be in a private subnet (no direct internet access)
   - Security Group should only allow port 5432 from Backend EC2 Security Group
   - Never expose PostgreSQL directly to the internet

2. **Authentication**:
   - Use strong passwords for database user
   - Store credentials securely in .env files
   - Never commit credentials to version control

3. **Firewall Rules**:
   - UFW is configured to only allow SSH (22) and PostgreSQL (5432)
   - Additional ports should not be opened unless necessary

### Connection String Format

```
postgresql://bmi_user:PASSWORD@DATABASE_EC2_PRIVATE_IP:5432/bmidb
```

Replace:
- `PASSWORD`: The password you set during setup
- `DATABASE_EC2_PRIVATE_IP`: The private IP address of the Database EC2 instance

### Backup and Maintenance

#### Create Backup
```bash
pg_dump -U bmi_user -d bmidb -h localhost > bmidb_backup_$(date +%Y%m%d).sql
```

#### Restore from Backup
```bash
psql -U bmi_user -d bmidb -h localhost < bmidb_backup_YYYYMMDD.sql
```

#### Check Database Size
```sql
SELECT pg_size_pretty(pg_database_size('bmidb'));
```

#### View Active Connections
```sql
SELECT * FROM pg_stat_activity WHERE datname = 'bmidb';
```

### Troubleshooting

#### Cannot Connect from Backend EC2

1. Check Security Groups:
   - Database EC2 SG allows inbound 5432 from Backend EC2 SG
   - Backend EC2 SG allows outbound to 5432

2. Check PostgreSQL is listening:
   ```bash
   sudo netstat -plnt | grep 5432
   ```

3. Check pg_hba.conf has correct subnet:
   ```bash
   sudo cat /etc/postgresql/*/main/pg_hba.conf | grep bmidb
   ```

4. Test from Backend EC2:
   ```bash
   psql postgresql://bmi_user:PASSWORD@PRIVATE_IP:5432/bmidb -c "SELECT 1"
   ```

#### Performance Issues

1. Check connection pool size in Backend
2. Monitor active connections
3. Add indexes if queries are slow
4. Consider increasing PostgreSQL memory settings

### Monitoring

#### Check PostgreSQL Status
```bash
sudo systemctl status postgresql
```

#### View Logs
```bash
sudo tail -f /var/log/postgresql/postgresql-*-main.log
```

#### Monitor Disk Usage
```bash
df -h
```

## AWS VPC Configuration

### Recommended Setup

1. **VPC Structure**:
   - Public Subnet: Frontend EC2 (with Elastic IP)
   - Private Subnet 1: Backend EC2
   - Private Subnet 2: Database EC2

2. **Security Groups**:
   - Frontend SG: Allow 80, 443 from internet; 22 from your IP
   - Backend SG: Allow 3000 from Frontend SG; 22 from your IP
   - Database SG: Allow 5432 from Backend SG; 22 from your IP

3. **Route Tables**:
   - Public Subnet: Routes to Internet Gateway
   - Private Subnets: Routes to NAT Gateway for outbound internet
