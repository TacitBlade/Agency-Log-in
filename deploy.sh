#!/bin/bash

# AWS EC2 Deployment Script for Agency Login App
# Make sure to update the variables below with your actual values

# Configuration
EC2_HOST="YOUR_EC2_PUBLIC_IP"
EC2_USER="ec2-user"
KEY_PATH="./keys/AlphaAgency752.pem"
APP_DIR="/home/ec2-user/agency-login"
REPO_URL="https://github.com/TacitBlade/Agency-Log-in.git"

echo "🚀 Starting deployment to AWS EC2..."

# Function to run commands on EC2
run_on_ec2() {
    ssh -i "$KEY_PATH" "$EC2_USER@$EC2_HOST" "$1"
}

# Function to copy files to EC2
copy_to_ec2() {
    scp -i "$KEY_PATH" -r "$1" "$EC2_USER@$EC2_HOST:$2"
}

echo "📦 Installing dependencies on EC2..."
run_on_ec2 "sudo yum update -y"
run_on_ec2 "sudo yum install -y python3 python3-pip git nginx"

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
ExecStart=$APP_DIR/venv/bin/gunicorn --bind 0.0.0.0:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

copy_to_ec2 "/tmp/agency-login.service" "/tmp/"
run_on_ec2 "sudo mv /tmp/agency-login.service /etc/systemd/system/"
run_on_ec2 "sudo systemctl daemon-reload"
run_on_ec2 "sudo systemctl enable agency-login"

echo "🌐 Configuring Nginx..."
cat > /tmp/nginx-agency-login << EOF
server {
    listen 80;
    server_name $EC2_HOST;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

copy_to_ec2 "/tmp/nginx-agency-login" "/tmp/"
run_on_ec2 "sudo mv /tmp/nginx-agency-login /etc/nginx/conf.d/agency-login.conf"
run_on_ec2 "sudo systemctl enable nginx"

echo "🔄 Starting services..."
run_on_ec2 "sudo systemctl restart agency-login"
run_on_ec2 "sudo systemctl restart nginx"

echo "🔍 Checking service status..."
run_on_ec2 "sudo systemctl status agency-login --no-pager"
run_on_ec2 "sudo systemctl status nginx --no-pager"

echo "✅ Deployment complete!"
echo "🌐 Your app should be available at: http://$EC2_HOST"
echo "📋 Default login credentials:"
echo "   Username: admin"
echo "   Password: password123"
echo ""
echo "🔧 To check logs:"
echo "   sudo journalctl -u agency-login -f"
