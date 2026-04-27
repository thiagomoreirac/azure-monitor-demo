# 🚀 Script to configure GitHub and push the repository
# Run step-by-step to connect with GitHub

Write-Host "🎯 GITHUB CONFIGURATION - Azure Monitor Demo" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Step 1: Verify current Git configuration
Write-Host "`n📋 Step 1: Git configuration check" -ForegroundColor Yellow
git config --list --global

# Step 2: Show current repository status
Write-Host "`n📦 Step 2: Current repository status" -ForegroundColor Yellow
git status
git log --oneline -5

# Step 3: Instructions to create repository on GitHub
Write-Host "`n🌐 Step 3: Create repository on GitHub" -ForegroundColor Yellow
Write-Host "Go to: https://github.com/new" -ForegroundColor Green
Write-Host "Recommended settings:" -ForegroundColor White
Write-Host "  - Repository name: azure-monitor-demo" -ForegroundColor Gray
Write-Host "  - Description: Complete Azure Monitor and Application Insights demo environment for client presentations" -ForegroundColor Gray
Write-Host "  - Public repository" -ForegroundColor Gray
Write-Host "  - DO NOT initialize with README (already included)" -ForegroundColor Gray
Write-Host "  - DO NOT add .gitignore (already included)" -ForegroundColor Gray
Write-Host "  - Select MIT License if desired" -ForegroundColor Gray

# Pause so the user can create the repository
Write-Host "`n⏸️  PAUSE: Create the repository on GitHub and press Enter to continue..." -ForegroundColor Red
Read-Host

# Step 4: Get repository URL
Write-Host "`n🔗 Step 4: Remote configuration" -ForegroundColor Yellow
$githubUsername = Read-Host "Enter your GitHub username"
$repoName = Read-Host "Enter repository name (default: azure-monitor-demo)"
if ([string]::IsNullOrEmpty($repoName)) {
    $repoName = "azure-monitor-demo"
}

$repoUrl = "https://github.com/$githubUsername/$repoName.git"
Write-Host "Repository URL: $repoUrl" -ForegroundColor Green

# Step 5: Add remote and push code
Write-Host "`n🚀 Step 5: Connect and push to repository" -ForegroundColor Yellow
try {
    git remote add origin $repoUrl
    Write-Host "✅ Remote added successfully" -ForegroundColor Green
    
    git branch -M main
    Write-Host "✅ Branch renamed to 'main'" -ForegroundColor Green
    
    Write-Host "🔄 Pushing code to GitHub..." -ForegroundColor Yellow
    git push -u origin main
    Write-Host "✅ Code pushed successfully!" -ForegroundColor Green
    
    # Open repository in browser
    Write-Host "`n🌐 Opening repository in browser..." -ForegroundColor Yellow
    Start-Process $repoUrl.Replace('.git', '')
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Fallback manual commands:" -ForegroundColor Yellow
    Write-Host "git remote add origin $repoUrl" -ForegroundColor Gray
    Write-Host "git branch -M main" -ForegroundColor Gray
    Write-Host "git push -u origin main" -ForegroundColor Gray
}

Write-Host "`n🎉 REPOSITORY CONFIGURED!" -ForegroundColor Green
Write-Host "Your project is now at: $repoUrl" -ForegroundColor Green
Write-Host "`n📊 Important URLs:" -ForegroundColor Cyan
Write-Host "- GitHub Repo: $($repoUrl.Replace('.git', ''))" -ForegroundColor White
Write-Host "- Demo App: https://app-bwkinh757hlog.azurewebsites.net" -ForegroundColor White
Write-Host "- Demo Guide: docs/DEMO-GUIDE.md" -ForegroundColor White
