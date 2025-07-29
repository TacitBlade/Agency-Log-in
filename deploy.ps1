# PowerShell Deployment Script for Agency Login App
# Make sure to update the variables below with your actual values

# Configuration
$EC2_HOST = "YOUR_EC2_PUBLIC_IP"
$EC2_USER = "ec2-user"
$KEY_PATH = "./keys/AlphaAgency752.pem"
$APP_DIR = "/home/ec2-user/agency-login"
$REPO_URL = "https://github.com/TacitBlade/Agency-Log-in.git"

Write-Host "🚀 Starting deployment to AWS EC2..." -ForegroundColor Green

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
ExecStart=$APP_DIR/venv/bin/gunicorn --bind 0.0.0.0:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
"@ | Out-File -FilePath "$env:TEMP/agency-login.service" -Encoding utf8

Copy-ToEC2 "$env:TEMP/agency-login.service" "/tmp/"
Invoke-EC2Command "sudo mv /tmp/agency-login.service /etc/systemd/system/"
Invoke-EC2Command "sudo systemctl daemon-reload"
Invoke-EC2Command "sudo systemctl enable agency-login"

Write-Host "🌐 Configuring Nginx..." -ForegroundColor Yellow
@"
server {
    listen 80;
    server_name $EC2_HOST;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
    }
}
"@ | Out-File -FilePath "$env:TEMP/nginx-agency-login" -Encoding utf8

Copy-ToEC2 "$env:TEMP/nginx-agency-login" "/tmp/"
Invoke-EC2Command "sudo mv /tmp/nginx-agency-login /etc/nginx/conf.d/agency-login.conf"
Invoke-EC2Command "sudo systemctl enable nginx"

Write-Host "🔄 Starting services..." -ForegroundColor Yellow
Invoke-EC2Command "sudo systemctl restart agency-login"
Invoke-EC2Command "sudo systemctl restart nginx"

Write-Host "🔍 Checking service status..." -ForegroundColor Yellow
Invoke-EC2Command "sudo systemctl status agency-login --no-pager"
Invoke-EC2Command "sudo systemctl status nginx --no-pager"

Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host "🌐 Your app should be available at: http://$EC2_HOST" -ForegroundColor Cyan
Write-Host "📋 Default login credentials:" -ForegroundColor Yellow
Write-Host "   Username: admin" -ForegroundColor White
Write-Host "   Password: password123" -ForegroundColor White
Write-Host ""
Write-Host "🔧 To check logs:" -ForegroundColor Yellow
Write-Host "   sudo journalctl -u agency-login -f" -ForegroundColor White
