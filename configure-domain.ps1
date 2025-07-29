# Quick Domain Configuration Script for alphaagency752.com
# This script helps you set your EC2 IP in the deployment files

param(
    [Parameter(Mandatory=$true)]
    [string]$EC2_IP
)

Write-Host "🔧 Configuring alphaagency752.com deployment..." -ForegroundColor Green

# Validate IP format
if ($EC2_IP -notmatch "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$") {
    Write-Host "❌ Invalid IP format. Please provide a valid IP address (e.g., 54.123.45.67)" -ForegroundColor Red
    exit 1
}

$files = @(
    "deploy-with-ssl.ps1",
    "deploy-with-ssl.sh",
    "aws-config.env"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        # Update PowerShell files
        if ($file -like "*.ps1") {
            (Get-Content $file) -replace '\$EC2_HOST = "YOUR_EC2_PUBLIC_IP"', "`$EC2_HOST = `"$EC2_IP`"" | Set-Content $file
        }
        # Update Bash files
        elseif ($file -like "*.sh") {
            (Get-Content $file) -replace 'EC2_HOST="YOUR_EC2_PUBLIC_IP"', "EC2_HOST=`"$EC2_IP`"" | Set-Content $file
        }
        # Update config files
        elseif ($file -like "*.env") {
            (Get-Content $file) -replace 'EC2_HOST=YOUR_EC2_PUBLIC_IP_HERE', "EC2_HOST=$EC2_IP" | Set-Content $file
        }
        
        Write-Host "✅ Updated $file with IP: $EC2_IP" -ForegroundColor Green
    } else {
        Write-Host "⚠️  File not found: $file" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🌐 Domain Configuration Summary:" -ForegroundColor Cyan
Write-Host "   Domain: alphaagency752.com" -ForegroundColor White
Write-Host "   EC2 IP: $EC2_IP" -ForegroundColor White
Write-Host "   SSL Email: admin@alphaagency752.com" -ForegroundColor White
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Configure DNS in Namecheap (see NAMECHEAP_DNS_SETUP.md)" -ForegroundColor White
Write-Host "2. Wait for DNS propagation (1-2 hours)" -ForegroundColor White
Write-Host "3. Test DNS: nslookup alphaagency752.com" -ForegroundColor White
Write-Host "4. Deploy with SSL: .\deploy-with-ssl.ps1" -ForegroundColor White
Write-Host ""
Write-Host "🔍 Test DNS propagation:" -ForegroundColor Cyan
Write-Host "   nslookup alphaagency752.com" -ForegroundColor White
Write-Host "   ping alphaagency752.com" -ForegroundColor White
