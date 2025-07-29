# AWS Key Setup Script
# This script helps you properly configure your AWS PEM key

param(
    [Parameter(Mandatory=$false)]
    [string]$PemFilePath
)

Write-Host "🔑 AWS Key Setup for Agency Login App" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$keysDir = "./keys"
$targetPemPath = "$keysDir/AlphaAgency752.pem"

# Create keys directory if it doesn't exist
if (!(Test-Path $keysDir)) {
    New-Item -ItemType Directory -Path $keysDir -Force
    Write-Host "✅ Created keys directory" -ForegroundColor Green
}

# If PEM file path is provided, copy it to the keys directory
if ($PemFilePath -and (Test-Path $PemFilePath)) {
    Copy-Item $PemFilePath $targetPemPath -Force
    Write-Host "✅ Copied PEM file to $targetPemPath" -ForegroundColor Green
} elseif ($PemFilePath) {
    Write-Host "❌ PEM file not found at: $PemFilePath" -ForegroundColor Red
    exit 1
}

# Check if PEM file exists in keys directory
if (Test-Path $targetPemPath) {
    Write-Host "✅ PEM file found at: $targetPemPath" -ForegroundColor Green
    
    # Set appropriate permissions (equivalent to chmod 400 on Unix)
    if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
        # Windows: Remove inheritance and set permissions
        $acl = Get-Acl $targetPemPath
        $acl.SetAccessRuleProtection($true, $false)
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
        $acl.SetAccessRule($accessRule)
        Set-Acl $targetPemPath $acl
        Write-Host "✅ Set Windows file permissions" -ForegroundColor Green
    } else {
        # Unix-like systems
        chmod 400 $targetPemPath
        Write-Host "✅ Set Unix file permissions (400)" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  PEM file not found. Please:" -ForegroundColor Yellow
    Write-Host "   1. Place your AlphaAgency752.pem file in the ./keys/ directory, OR" -ForegroundColor White
    Write-Host "   2. Run this script with the -PemFilePath parameter:" -ForegroundColor White
    Write-Host "      .\setup-aws-key.ps1 -PemFilePath 'C:\path\to\your\key.pem'" -ForegroundColor White
}

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Update aws-config.env with your EC2 instance IP" -ForegroundColor White
Write-Host "2. Copy aws-config.env to .env and customize as needed" -ForegroundColor White
Write-Host "3. Run .\deploy.ps1 to deploy to AWS" -ForegroundColor White
Write-Host ""
Write-Host "🔒 Security Reminder:" -ForegroundColor Yellow
Write-Host "- The keys/ directory is excluded from Git" -ForegroundColor White
Write-Host "- Never commit PEM files to version control" -ForegroundColor White
Write-Host "- Keep your AWS credentials secure" -ForegroundColor White
