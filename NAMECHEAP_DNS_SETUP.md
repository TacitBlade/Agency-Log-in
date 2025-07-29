# Namecheap DNS Configuration Guide for alphaagency752.com

## 🌐 Setting up your Namecheap domain to point to AWS EC2

### Step 1: Get your EC2 Public IP Address

First, you need your EC2 instance's public IP address. You can find this in:
- AWS Console → EC2 → Instances → Select your instance → Public IPv4 address
- Or run: `curl -s http://checkip.amazonaws.com/` from your EC2 instance

**Example IP**: `54.123.45.67` (replace with your actual IP)

### Step 2: Configure Namecheap DNS Settings

1. **Log into Namecheap**:
   - Go to https://namecheap.com
   - Sign in to your account
   - Go to "Domain List" → Click "Manage" next to alphaagency.com

2. **Access DNS Settings**:
   - Click on the "Advanced DNS" tab
   - You'll see the DNS records management interface

3. **Configure A Records**:
   Add/modify these DNS records:

   | Type | Host | Value | TTL |
   |------|------|-------|-----|
   | A Record | @ | YOUR_EC2_PUBLIC_IP | Automatic |
   | A Record | www | YOUR_EC2_PUBLIC_IP | Automatic |
   | CNAME Record | * | alphaagency752.com | Automatic |

   **Example with IP 54.123.45.67**:
   ```
   A Record    @      54.123.45.67    Automatic
   A Record    www    54.123.45.67    Automatic  
   CNAME       *      alphaagency752.com Automatic
   ```

4. **Remove Default Records** (if present):
   - Delete any existing parking page redirects
   - Remove any conflicting A or CNAME records

### Step 3: Update Your Deployment Configuration

1. **Update your EC2 IP in the deployment script**:
   ```powershell
   # Edit deploy-with-ssl.ps1
   $EC2_HOST = "54.123.45.67"  # Your actual EC2 IP
   ```

2. **The domain is already configured**:
   ```powershell
   $DOMAIN_NAME = "alphaagency752.com"
   $EMAIL = "admin@alphaagency752.com"
   ```

### Step 4: Test DNS Propagation

DNS changes can take 24-48 hours to fully propagate. Test with these commands:

```powershell
# Check if domain resolves to your IP
nslookup alphaagency752.com
nslookup www.alphaagency752.com

# Alternative tools
ping alphaagency752.com
```

**Expected output**:
```
Name:    alphaagency752.com
Address: 54.123.45.67  # Your EC2 IP
```

### Step 5: Deploy with SSL

Once DNS propagation is complete (usually 1-2 hours), run:

```powershell
# Make sure your EC2 IP is updated in the script first!
.\deploy-with-ssl.ps1
```

### Step 6: Verify SSL Installation

After deployment, test your SSL setup:

1. **Browser Test**: Visit https://alphaagency752.com
2. **SSL Test**: https://www.ssllabs.com/ssltest/analyze.html?d=alphaagency752.com
3. **Certificate Check**: 
   ```powershell
   # From your local machine
   openssl s_client -connect alphaagency752.com:443 -servername alphaagency752.com
   ```

### Troubleshooting

#### DNS Not Resolving:
1. **Check TTL**: Namecheap's TTL is usually automatic (300 seconds)
2. **Clear DNS Cache**: 
   ```powershell
   ipconfig /flushdns
   ```
3. **Use Different DNS**: Try 8.8.8.8 or 1.1.1.1

#### SSL Certificate Failed:
1. **Ensure DNS points to server**: Domain must resolve before SSL works
2. **Check domain in script**: Verify DOMAIN_NAME is exactly "alphaagency752.com"
3. **Manual SSL setup**:
   ```bash
   # SSH to your EC2 instance
   ssh -i ./keys/AlphaAgency752.pem ec2-user@YOUR_EC2_IP
   
   # Run Certbot manually
   sudo certbot --nginx -d alphaagency752.com -d www.alphaagency752.com
   ```

#### EC2 Security Groups:
Ensure these ports are open in your EC2 Security Group:
- **Port 22**: SSH access
- **Port 80**: HTTP (required for Let's Encrypt validation)
- **Port 443**: HTTPS

### Timeline Expectations

- **DNS Propagation**: 1-24 hours (usually 1-2 hours)
- **SSL Certificate**: 2-5 minutes after DNS is working
- **Full Deployment**: 5-10 minutes after DNS resolves

### Final URLs

After successful deployment, your app will be available at:
- **Primary**: https://alphaagency752.com
- **With www**: https://www.alphaagency752.com
- **HTTP redirects**: http://alphaagency752.com → https://alphaagency752.com

🎉 Your Agency Login app will have a professional domain with SSL encryption!
