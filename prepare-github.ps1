# GitHub preparation script
# This script prepares the project for upload to a public repository.

Write-Host "🔧 Preparing project for GitHub..." -ForegroundColor Cyan

function Remove-SensitiveInfo {
    param([string]$FilePath, [string]$Pattern, [string]$Replacement)

    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw
        $cleanContent = $content -replace $Pattern, $Replacement
        Set-Content -Path $FilePath -Value $cleanContent -NoNewline
        Write-Host "✅ Cleaned: $FilePath" -ForegroundColor Green
    }
}

# Sanitize potentially sensitive values.
Write-Host "🧹 Cleaning sensitive information..." -ForegroundColor Yellow

Remove-SensitiveInfo -FilePath "src\webapp-simple\server.js" `
    -Pattern "InstrumentationKey=[^;]+;[^']*" `
    -Replacement "process.env.APPLICATIONINSIGHTS_CONNECTION_STRING || 'your-connection-string-here'"

Remove-SensitiveInfo -FilePath "infra\main.parameters.json" `
    -Pattern '"ComplexPassword123!"' `
    -Replacement '"YourSecurePassword123!"'

Write-Host "📝 Creating .env.example..." -ForegroundColor Yellow
@"
# Azure Configuration
AZURE_SUBSCRIPTION_ID=your-subscription-id-here
AZURE_TENANT_ID=your-tenant-id-here

# Application Insights
APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=your-key;IngestionEndpoint=https://your-region.in.applicationinsights.azure.com/

# SQL Database
SQL_CONNECTION_STRING=Server=your-server.database.windows.net;Database=your-db;User Id=your-user;Password=your-password;

# App Service
WEBSITE_NODE_DEFAULT_VERSION=18.12.0
"@ | Out-File -FilePath ".env.example" -Encoding UTF8

Write-Host "✅ .env.example created" -ForegroundColor Green

Write-Host "📝 Creating CONTRIBUTING.md..." -ForegroundColor Yellow
@"
# Contributing Guide

Thank you for your interest in contributing to the Azure Monitor Demo project.

## How to Contribute

### 1. Fork and Clone
```bash
git fork https://github.com/your-repo/azure-monitor-demo
git clone https://github.com/your-username/azure-monitor-demo
cd azure-monitor-demo
```

### 2. Create a Branch
```bash
git checkout -b feature/new-feature
```

### 3. Make Changes
- Keep code clean and documented
- Follow existing naming conventions
- Update documentation when needed

### 4. Test
```powershell
.\scripts\demo-final.ps1
```

### 5. Commit and Push
```bash
git add .
git commit -m "feat: describe new feature"
git push origin feature/new-feature
```

### 6. Create Pull Request
- Describe the changes made
- Include screenshots when applicable
- Reference related issues

## Pull Request Checklist

- [ ] Code tested locally
- [ ] Documentation updated
- [ ] No sensitive information (passwords, keys, etc.)
- [ ] Clear commit messages
- [ ] No temporary files or logs

## Conventions

### Commit Messages
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation changes
- `refactor:` code refactoring
- `test:` add or modify tests

### Code Style
- Use descriptive names for variables and functions
- Comment complex code when needed
- Keep functions small and focused

## Development Setup

### Prerequisites
- Azure CLI
- PowerShell 5.1+
- Git
- Code editor (VS Code recommended)

### Initial Setup
```bash
code --install-extension ms-vscode.azure-tools
code --install-extension ms-vscode.powershell
```

Thanks for contributing.
"@ | Out-File -FilePath "CONTRIBUTING.md" -Encoding UTF8

Write-Host "✅ CONTRIBUTING.md created" -ForegroundColor Green

Write-Host "📝 Creating GitHub Actions workflow..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path ".github\workflows" -Force | Out-Null

@"
name: Validate ARM Templates

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  validate-arm:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Login to Azure
      uses: azure/login@v1
      with:
        creds: `${{ secrets.AZURE_CREDENTIALS }}

    - name: Validate ARM Template
      run: |
        az deployment group validate \
          --resource-group "temp-validation-rg" \
          --template-file infra/main.json \
          --parameters infra/main.parameters.json

  validate-scripts:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v3

    - name: Test PowerShell Scripts
      run: |
        # Test script syntax
        Get-ChildItem -Path scripts -Filter "*.ps1" | ForEach-Object {
          `$errors = `$null
          `$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content `$_.FullName -Raw), [ref]`$errors)
          if (`$errors) {
            Write-Error "Syntax errors in `$(`$_.Name): `$errors"
            exit 1
          }
        }
      shell: pwsh
"@ | Out-File -FilePath ".github\workflows\validate.yml" -Encoding UTF8

Write-Host "✅ GitHub Actions workflow created" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor White
Write-Host "1. Review modified files" -ForegroundColor Cyan
Write-Host "2. Run: git add ." -ForegroundColor Cyan
Write-Host "3. Run: git commit -m 'Initial commit'" -ForegroundColor Cyan
Write-Host "4. Create a GitHub repository" -ForegroundColor Cyan
Write-Host "5. Run: git remote add origin <repo-url>" -ForegroundColor Cyan
Write-Host "6. Run: git push -u origin main" -ForegroundColor Cyan
