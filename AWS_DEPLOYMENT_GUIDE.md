# Comprehensive setup guide for deploying Agency Login App to AWS EC2

## Prerequisites

1. AWS EC2 instance running Amazon Linux 2 or similar
2. SSH key pair for EC2 access (AlphaAgency752.pem)
3. Security group allowing HTTP (port 80) and SSH (port 22) access
4. Git repository with your code

## Quick Setup Steps

### 1. Configure AWS Keys

**Option A: Use the setup script (Recommended)**
```powershell
# If your PEM file is elsewhere, copy it automatically:
.\setup-aws-key.ps1 -PemFilePath "C:\path\to\your\AlphaAgency752.pem"

# Or if you've already placed it in the keys/ directory:
.\setup-aws-key.ps1
```

**Option B: Manual setup**
1. Place your `AlphaAgency752.pem` file in the `./keys/` directory
2. Set appropriate permissions (the setup script does this automatically)

### 2. Configure Environment

1. Copy `aws-config.env` to `.env`:
   ```powershell
   Copy-Item aws-config.env .env
   ```

2. Edit `.env` and update:
   - `EC2_HOST`: Your EC2 instance's public IP address
   - `SECRET_KEY`: Generate a secure random string
   - Other AWS settings as needed

### 3. Run Deployment

**Basic Deployment (HTTP only):**
```powershell
# Windows
.\deploy.ps1

# Linux/Mac
chmod +x deploy.sh
./deploy.sh
```

**Enhanced Deployment with SSL (Recommended):**
```powershell
# Windows
.\deploy-with-ssl.ps1

# Linux/Mac
chmod +x deploy-with-ssl.sh
./deploy-with-ssl.sh
```

> **Note**: For SSL deployment, you need a domain name. See `SSL_SETUP_GUIDE.md` for details.

### 4. Manual Setup (Alternative)

If you prefer manual setup, follow these steps:

#### Connect to your EC2 instance:
```bash
ssh -i ~/.ssh/your-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

#### Install dependencies:
```bash
sudo yum update -y
sudo yum install -y python3 python3-pip git nginx
```

#### Clone and setup the application:
```bash
git clone https://github.com/TacitBlade/Agency-Log-in.git agency-login
cd agency-login
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### Create systemd service:
```bash
sudo nano /etc/systemd/system/agency-login.service
```

Add the following content:
```ini
[Unit]
Description=Agency Login Flask App
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user/agency-login
Environment=PATH=/home/ec2-user/agency-login/venv/bin
Environment=FLASK_ENV=production
Environment=PORT=5000
ExecStart=/home/ec2-user/agency-login/venv/bin/gunicorn --bind 0.0.0.0:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
```

#### Configure Nginx:
```bash
sudo nano /etc/nginx/conf.d/agency-login.conf
```

Add the following content:
```nginx
server {
    listen 80;
    server_name YOUR_EC2_PUBLIC_IP;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### Start services:
```bash
sudo systemctl daemon-reload
sudo systemctl enable agency-login
sudo systemctl enable nginx
sudo systemctl start agency-login
sudo systemctl start nginx
```

## Security Group Configuration

Make sure your EC2 security group allows:
- Port 22 (SSH) from your IP
- Port 80 (HTTP) from anywhere (0.0.0.0/0)
- Port 443 (HTTPS) from anywhere if you plan to add SSL

## Default Login Credentials

- Username: `admin`
- Password: `password123`
- Username: `user`
- Password: `userpass`

**Important**: Change these credentials in production!

## Monitoring and Troubleshooting

### Check application logs:
```bash
sudo journalctl -u agency-login -f
```

### Check Nginx logs:
```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Restart services:
```bash
sudo systemctl restart agency-login
sudo systemctl restart nginx
```

### Check service status:
```bash
sudo systemctl status agency-login
sudo systemctl status nginx
```

## Environment Variables

Create a `.env` file based on `.env.example` for production configuration:

```bash
cp .env.example .env
nano .env
```

Update the values according to your production requirements.

## SSL Certificate (Optional but Recommended)

To add HTTPS support using Let's Encrypt:

```bash
sudo yum install -y epel-release
sudo yum install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## Updates and Maintenance

To update the application:
```bash
cd /home/ec2-user/agency-login
git pull
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart agency-login
```

## Database Integration (Future Enhancement)

The current setup uses in-memory storage. For production, consider:
- Amazon RDS (PostgreSQL/MySQL)
- Amazon DynamoDB
- SQLite for simple deployments

## Load Balancing (For High Traffic)

For production with high traffic:
- Use Application Load Balancer (ALB)
- Multiple EC2 instances
- Auto Scaling Groups
- Amazon ECS or EKS for containerized deployment
