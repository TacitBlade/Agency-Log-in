#!/bin/bash

# Enhanced Bash Deployment Script with SSL Support
# Agency Login App with nginx Reverse Proxy + SSL

# Configuration
EC2_HOST="YOUR_EC2_PUBLIC_IP"
DOMAIN_NAME="yourdomain.com"  # Set this to your actual domain
EC2_USER="ec2-user"
KEY_PATH="./keys/AlphaAgency752.pem"
APP_DIR="/home/ec2-user/agency-login"
REPO_URL="https://github.com/TacitBlade/Agency-Log-in.git"
EMAIL="your-email@example.com"  # For Let's Encrypt notifications

echo "🚀 Starting enhanced deployment to AWS EC2 with SSL..."

# Function to run commands on EC2
run_on_ec2() {
    ssh -i "$KEY_PATH" "$EC2_USER@$EC2_HOST" "$1"
}

# Function to copy files to EC2
copy_to_ec2() {
    scp -i "$KEY_PATH" "$1" "$EC2_USER@$EC2_HOST:$2"
}

echo "📦 Installing dependencies on EC2..."
run_on_ec2 "sudo yum update -y"
run_on_ec2 "sudo yum install -y python3 python3-pip git nginx"

# Install Certbot for Let's Encrypt SSL
echo "🔒 Installing Certbot for SSL..."
run_on_ec2 "sudo yum install -y python3-certbot-nginx"

echo "📥 Cloning/updating repository..."
run_on_ec2 "if [ -d '$APP_DIR' ]; then cd $APP_DIR && git pull; else git clone $REPO_URL $APP_DIR; fi"

echo "🐍 Setting up Python environment..."
run_on_ec2 "cd $APP_DIR && python3 -m venv venv"
run_on_ec2 "cd $APP_DIR && source venv/bin/activate && pip install -r requirements.txt"

echo "⚙️ Configuring systemd service..."
cat > /tmp/agency-login.service << EOF
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
EOF

copy_to_ec2 "/tmp/agency-login.service" "/tmp/"
run_on_ec2 "sudo mv /tmp/agency-login.service /etc/systemd/system/"
run_on_ec2 "sudo systemctl daemon-reload"
run_on_ec2 "sudo systemctl enable agency-login"

echo "🌐 Configuring Nginx reverse proxy..."

# Initial nginx config (HTTP only - for Certbot validation)
cat > /tmp/nginx-agency-login << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME $EC2_HOST;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_buffering off;
        proxy_redirect off;
    }
}
EOF

copy_to_ec2 "/tmp/nginx-agency-login" "/tmp/"
run_on_ec2 "sudo mv /tmp/nginx-agency-login /etc/nginx/sites-available/agency-login"
run_on_ec2 "sudo ln -sf /etc/nginx/sites-available/agency-login /etc/nginx/sites-enabled/"
run_on_ec2 "sudo rm -f /etc/nginx/sites-enabled/default"

# Test nginx configuration
echo "🔍 Testing nginx configuration..."
run_on_ec2 "sudo nginx -t"

echo "🔄 Starting services..."
run_on_ec2 "sudo systemctl start agency-login"
run_on_ec2 "sudo systemctl start nginx"

echo "🔒 Setting up SSL with Let's Encrypt..."
if [ "$DOMAIN_NAME" != "yourdomain.com" ]; then
    echo "Obtaining SSL certificate for $DOMAIN_NAME..."
    run_on_ec2 "sudo certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos --email $EMAIL --redirect"
    
    echo "⏰ Setting up SSL certificate auto-renewal..."
    run_on_ec2 "echo '0 12 * * * /usr/bin/certbot renew --quiet' | sudo crontab -"
else
    echo "⚠️  Skipping SSL setup - please update DOMAIN_NAME variable"
    echo "   After updating the domain, run:"
    echo "   sudo certbot --nginx -d yourdomain.com --non-interactive --agree-tos --email your-email@example.com --redirect"
fi

echo "🔧 Configuring security headers..."
cat > /tmp/security-headers.conf << EOF
# Security headers configuration
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Referrer-Policy "strict-origin-when-cross-origin";
EOF

copy_to_ec2 "/tmp/security-headers.conf" "/tmp/"
run_on_ec2 "sudo mv /tmp/security-headers.conf /etc/nginx/conf.d/security-headers.conf"

echo "🔄 Restarting services..."
run_on_ec2 "sudo systemctl restart agency-login"
run_on_ec2 "sudo systemctl restart nginx"

echo "🔍 Checking service status..."
run_on_ec2 "sudo systemctl status agency-login --no-pager"
run_on_ec2 "sudo systemctl status nginx --no-pager"

echo "✅ Enhanced deployment complete!"
echo ""
echo "🌐 Access your app at:"
if [ "$DOMAIN_NAME" != "yourdomain.com" ]; then
    echo "   HTTPS: https://$DOMAIN_NAME (SSL enabled)"
    echo "   HTTP:  http://$DOMAIN_NAME (redirects to HTTPS)"
else
    echo "   HTTP: http://$EC2_HOST"
fi
echo ""
echo "📋 Default login credentials:"
echo "   Username: admin"
echo "   Password: password123"
echo ""
echo "🔧 Useful commands:"
echo "   Check app logs: sudo journalctl -u agency-login -f"
echo "   Check nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "   Renew SSL cert: sudo certbot renew"
echo "   Check SSL status: sudo certbot certificates"
