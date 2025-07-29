# SSL Configuration Guide for Agency Login App

## 🔒 SSL/HTTPS Setup with Let's Encrypt

This guide explains how to set up SSL encryption for your Agency Login app using nginx reverse proxy and Let's Encrypt certificates.

### Prerequisites

1. **Domain Name**: You need a domain name pointing to your EC2 instance
2. **DNS Configuration**: Ensure your domain's A record points to your EC2 public IP
3. **Security Groups**: Allow HTTP (80) and HTTPS (443) traffic

### Quick Setup

1. **Update Configuration**:
   ```bash
   # Edit deploy-with-ssl.ps1 or deploy-with-ssl.sh
   DOMAIN_NAME="yourdomain.com"        # Your actual domain
   EMAIL="your-email@example.com"      # For Let's Encrypt notifications
   ```

2. **Run Enhanced Deployment**:
   ```powershell
   # Windows
   .\deploy-with-ssl.ps1
   
   # Linux/Mac  
   chmod +x deploy-with-ssl.sh
   ./deploy-with-ssl.sh
   ```

### What the SSL Setup Includes

#### 🔧 **Nginx Configuration**
- Reverse proxy setup pointing to Flask app (port 5000)
- Initial HTTP configuration for domain validation
- Automatic HTTPS redirect after SSL certificate installation

#### 🔐 **Let's Encrypt SSL Certificate**
- Free SSL certificate from Let's Encrypt
- Automatic certificate installation via Certbot
- Nginx configuration updated for HTTPS

#### 🛡️ **Security Headers**
- `X-Frame-Options: DENY` - Prevents clickjacking
- `X-Content-Type-Options: nosniff` - Prevents MIME sniffing
- `X-XSS-Protection` - Cross-site scripting protection
- `Strict-Transport-Security` - Forces HTTPS connections
- `Referrer-Policy` - Controls referrer information

#### ⏰ **Auto-Renewal**
- Automatic certificate renewal via cron job
- Runs daily at 12:00 PM to check for renewal

### Manual SSL Commands

If you need to manage SSL certificates manually:

```bash
# Connect to your EC2 instance
ssh -i ./keys/AlphaAgency752.pem ec2-user@YOUR_EC2_IP

# Obtain SSL certificate
sudo certbot --nginx -d yourdomain.com --non-interactive --agree-tos --email your-email@example.com

# Check certificate status
sudo certbot certificates

# Test renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal

# Check nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

### Troubleshooting

#### Common Issues:

1. **Domain not pointing to server**:
   ```bash
   # Check DNS resolution
   nslookup yourdomain.com
   dig yourdomain.com
   ```

2. **Port 80/443 not accessible**:
   - Check AWS Security Groups
   - Ensure inbound rules allow HTTP (80) and HTTPS (443)

3. **Certificate failed to obtain**:
   ```bash
   # Check Certbot logs
   sudo tail -f /var/log/letsencrypt/letsencrypt.log
   ```

4. **Nginx configuration errors**:
   ```bash
   # Test configuration
   sudo nginx -t
   
   # Check nginx logs
   sudo tail -f /var/log/nginx/error.log
   ```

### Security Best Practices

1. **Firewall Configuration**:
   ```bash
   # Only allow necessary ports
   sudo ufw allow 22    # SSH
   sudo ufw allow 80    # HTTP
   sudo ufw allow 443   # HTTPS
   sudo ufw enable
   ```

2. **Regular Updates**:
   ```bash
   # Keep system updated
   sudo yum update -y
   
   # Update Certbot
   sudo yum update python3-certbot-nginx
   ```

3. **Monitor Certificate Expiry**:
   ```bash
   # Check expiry dates
   sudo certbot certificates
   
   # Set up monitoring alerts
   ```

### Testing Your SSL Setup

1. **SSL Labs Test**: https://www.ssllabs.com/ssltest/
2. **Check certificate chain**: `openssl s_client -connect yourdomain.com:443`
3. **Test redirects**: `curl -I http://yourdomain.com`

Your Agency Login app will be accessible via HTTPS with an A+ SSL rating!
