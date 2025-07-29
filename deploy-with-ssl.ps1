# Enhanced PowerShell Deployment Script with SSL Support
# Agency Login App with nginx Reverse Proxy + SSL

# Configuration
$EC2_HOST = "YOUR_EC2_PUBLIC_IP"  # Update this with your actual EC2 IP
$DOMAIN_NAME = "alphaagency752.com"  # Your Namecheap domain
$EC2_USER = "ec2-user"
$KEY_PATH = "./keys/AlphaAgency752.pem"
$APP_DIR = "/home/ec2-user/agency-login"
$REPO_URL = "https://github.com/TacitBlade/Agency-Log-in.git"
$EMAIL = "admin@alphaagency752.com"  # Update with your email for SSL notifications

Write-Host "🚀 Starting enhanced deployment to AWS EC2 with SSL..." -ForegroundColor Green

# Function to run commands on EC2
function Invoke-EC2Command {
    param($Command)
    ssh -i $KEY_PATH "$EC2_USER@$EC2_HOST" $Command
}

# Function to copy files to EC2
function Copy-ToEC2 {
    param($Source, $Destination)
    scp -i $KEY_PATH -r $Source "$EC2_USER@${EC2_HOST}:$Destination"
}

Write-Host "📦 Installing dependencies on EC2..." -ForegroundColor Yellow
Invoke-EC2Command "sudo yum update -y"
Invoke-EC2Command "sudo yum install -y python3 python3-pip git nginx"

# Install Certbot for Let's Encrypt SSL
Write-Host "🔒 Installing Certbot for SSL..." -ForegroundColor Yellow
Invoke-EC2Command "sudo yum install -y python3-certbot-nginx"

Write-Host "📥 Cloning/updating repository..." -ForegroundColor Yellow
Invoke-EC2Command "if [ -d '$APP_DIR' ]; then cd $APP_DIR && git pull; else git clone $REPO_URL $APP_DIR; fi"

Write-Host "🐍 Setting up Python environment..." -ForegroundColor Yellow
Invoke-EC2Command "cd $APP_DIR && python3 -m venv venv"
Invoke-EC2Command "cd $APP_DIR && source venv/bin/activate && pip install -r requirements.txt"

Write-Host "⚙️ Configuring systemd service..." -ForegroundColor Yellow
@"
[Unit]
Description=Agency Login Flask App
After=network.target

[Service]
User=ec2-user
WorkingDirectory=$APP_DIR
Environment=PATH=$APP_DIR/venv/bin
Environment=FLASK_ENV=production
Environment=PORT=5000
ExecStart=$APP_DIR/venv/bin/gunicorn --bind 127.0.0.1:5000 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
"@ | Out-File -FilePath "$env:TEMP/agency-login.service" -Encoding utf8

Copy-ToEC2 "$env:TEMP/agency-login.service" "/tmp/"
Invoke-EC2Command "sudo mv /tmp/agency-login.service /etc/systemd/system/"
Invoke-EC2Command "sudo systemctl daemon-reload"
Invoke-EC2Command "sudo systemctl enable agency-login"

Write-Host "🌐 Configuring Nginx reverse proxy..." -ForegroundColor Yellow

# Initial nginx config (HTTP only - for Certbot validation)
@"
server {
    listen 80;
    server_name $DOMAIN_NAME $EC2_HOST;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
        proxy_buffering off;
        proxy_redirect off;
    }
}
"@ | Out-File -FilePath "$env:TEMP/nginx-agency-login" -Encoding utf8

Copy-ToEC2 "$env:TEMP/nginx-agency-login" "/tmp/"
Invoke-EC2Command "sudo mv /tmp/nginx-agency-login /etc/nginx/sites-available/agency-login"
Invoke-EC2Command "sudo ln -sf /etc/nginx/sites-available/agency-login /etc/nginx/sites-enabled/"
Invoke-EC2Command "sudo rm -f /etc/nginx/sites-enabled/default"

# Test nginx configuration
Write-Host "🔍 Testing nginx configuration..." -ForegroundColor Yellow
Invoke-EC2Command "sudo nginx -t"

Write-Host "🔄 Starting services..." -ForegroundColor Yellow
Invoke-EC2Command "sudo systemctl start agency-login"
Invoke-EC2Command "sudo systemctl start nginx"

Write-Host "🔒 Setting up SSL with Let's Encrypt..." -ForegroundColor Yellow
if ($DOMAIN_NAME -ne "yourdomain.com") {
    Write-Host "Obtaining SSL certificate for $DOMAIN_NAME..." -ForegroundColor Cyan
    Invoke-EC2Command "sudo certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos --email $EMAIL --redirect"
    
    Write-Host "⏰ Setting up SSL certificate auto-renewal..." -ForegroundColor Yellow
    Invoke-EC2Command "echo '0 12 * * * /usr/bin/certbot renew --quiet' | sudo crontab -"
} else {
    Write-Host "⚠️  Skipping SSL setup - please update DOMAIN_NAME variable" -ForegroundColor Yellow
    Write-Host "   After updating the domain, run:" -ForegroundColor White
    Write-Host "   sudo certbot --nginx -d yourdomain.com --non-interactive --agree-tos --email your-email@example.com --redirect" -ForegroundColor White
}

Write-Host "🔧 Configuring security headers..." -ForegroundColor Yellow
@"
# Security headers configuration
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection `"1; mode=block`";
add_header Strict-Transport-Security `"max-age=31536000; includeSubDomains`" always;
add_header Referrer-Policy `"strict-origin-when-cross-origin`";
"@ | Out-File -FilePath "$env:TEMP/security-headers.conf" -Encoding utf8

Copy-ToEC2 "$env:TEMP/security-headers.conf" "/tmp/"
Invoke-EC2Command "sudo mv /tmp/security-headers.conf /etc/nginx/conf.d/security-headers.conf"

Write-Host "🔄 Restarting services..." -ForegroundColor Yellow
Invoke-EC2Command "sudo systemctl restart agency-login"
Invoke-EC2Command "sudo systemctl restart nginx"

Write-Host "🔍 Checking service status..." -ForegroundColor Yellow
Invoke-EC2Command "sudo systemctl status agency-login --no-pager"
Invoke-EC2Command "sudo systemctl status nginx --no-pager"

Write-Host "✅ Enhanced deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Access your app at:" -ForegroundColor Cyan
if ($DOMAIN_NAME -ne "yourdomain.com") {
    Write-Host "   HTTPS: https://$DOMAIN_NAME (SSL enabled)" -ForegroundColor Green
    Write-Host "   HTTP:  http://$DOMAIN_NAME (redirects to HTTPS)" -ForegroundColor Yellow
} else {
    Write-Host "   HTTP: http://$EC2_HOST" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "📋 Default login credentials:" -ForegroundColor Yellow
Write-Host "   Username: admin" -ForegroundColor White
Write-Host "   Password: password123" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Useful commands:" -ForegroundColor Yellow
Write-Host "   Check app logs: sudo journalctl -u agency-login -f" -ForegroundColor White
Write-Host "   Check nginx logs: sudo tail -f /var/log/nginx/error.log" -ForegroundColor White
Write-Host "   Renew SSL cert: sudo certbot renew" -ForegroundColor White
Write-Host "   Check SSL status: sudo certbot certificates" -ForegroundColor White
