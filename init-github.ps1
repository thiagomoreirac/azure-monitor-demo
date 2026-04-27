# 🚀 GitHub Initialization Script
# Run this script after installing Git

Write-Host "🎯 Initializing Git repository for Azure Monitor Demo..." -ForegroundColor Cyan
Write-Host ""

# Verify Git is installed
try {
    git --version | Out-Null
    Write-Host "✅ Git detected" -ForegroundColor Green
} catch {
    Write-Host "❌ Git is not installed. Please install Git first:" -ForegroundColor Red
    Write-Host "   https://git-scm.com/download/windows" -ForegroundColor Yellow
    exit 1
}

# Initialize repository if it does not exist
if (-not (Test-Path ".git")) {
    Write-Host "📂 Initializing Git repository..." -ForegroundColor Yellow
    git init
    Write-Host "✅ Repository initialized" -ForegroundColor Green
} else {
    Write-Host "✅ Git repository already exists" -ForegroundColor Green
}

# Configure user if not set
$userName = git config user.name
$userEmail = git config user.email

if (-not $userName) {
    $name = Read-Host "Enter your name for Git"
    git config user.name $name
    Write-Host "✅ Name configured: $name" -ForegroundColor Green
}

if (-not $userEmail) {
    $email = Read-Host "Enter your email for Git"
    git config user.email $email
    Write-Host "✅ Email configured: $email" -ForegroundColor Green
}

# Add files
Write-Host "📦 Adding files to the repository..." -ForegroundColor Yellow
git add .

# Check status
Write-Host "📊 Repository status:" -ForegroundColor Yellow
git status --short

# Create initial commit
Write-Host "💾 Creating initial commit..." -ForegroundColor Yellow
git commit -m "feat: Initial commit - Azure Monitor Demo project

✨ Features:
- Complete ARM template infrastructure
- Node.js application with Application Insights
- PowerShell automation scripts
- Comprehensive documentation
- GitHub Actions workflows

📊 Components:
- App Service with Node.js runtime
- Application Insights with custom telemetry
- SQL Database for dependencies
- Log Analytics Workspace
- Storage Account and Azure Functions
- Pre-configured alerts

🎯 Ready for demo presentations!"

Write-Host "✅ Initial commit created" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 Repository prepared for GitHub!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor White
Write-Host "1. Create repository on GitHub:" -ForegroundColor Cyan
Write-Host "   https://github.com/new" -ForegroundColor Blue
Write-Host ""
Write-Host "2. Connect local repository to GitHub:" -ForegroundColor Cyan
Write-Host "   git remote add origin https://github.com/your-username/azure-monitor-demo.git" -ForegroundColor Blue
Write-Host ""
Write-Host "3. Set main as the default branch:" -ForegroundColor Cyan
Write-Host "   git branch -M main" -ForegroundColor Blue
Write-Host ""
Write-Host "4. Push code to GitHub:" -ForegroundColor Cyan
Write-Host "   git push -u origin main" -ForegroundColor Blue
Write-Host ""
Write-Host "5. (Optional) Configure GitHub Actions:" -ForegroundColor Cyan
Write-Host "   - Go to Settings > Secrets and variables > Actions" -ForegroundColor Blue
Write-Host "   - Add AZURE_CREDENTIALS for automated validation" -ForegroundColor Blue
Write-Host ""
Write-Host "🔗 The project includes:" -ForegroundColor Yellow
Write-Host "   ✅ Complete README.md with instructions" -ForegroundColor Green
Write-Host "   ✅ Documentation organized in /docs" -ForegroundColor Green
Write-Host "   ✅ Scripts organized in /scripts" -ForegroundColor Green
Write-Host "   ✅ Clean source code without sensitive information" -ForegroundColor Green
Write-Host "   ✅ Properly configured .gitignore" -ForegroundColor Green
Write-Host "   ✅ MIT license included" -ForegroundColor Green
Write-Host "   ✅ GitHub Actions for validation" -ForegroundColor Green
Write-Host "   ✅ Contribution guides" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Your project is ready to impress on GitHub!" -ForegroundColor Green
