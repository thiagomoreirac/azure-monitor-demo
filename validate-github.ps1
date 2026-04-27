# 🔍 Final Project Validation for GitHub
# This script verifies that the project is ready to be pushed to GitHub

Write-Host "🔍 FINAL VALIDATION - Azure Monitor Demo" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

$validationIssues = @()
$warnings = @()
$passed = 0

# Helper function for checks
function Test-FileExists {
    param($Path, $Description)
    if (Test-Path $Path) {
        Write-Host "✅ $Description" -ForegroundColor Green
        $script:passed++
        return $true
    } else {
        Write-Host "❌ $Description" -ForegroundColor Red
        $script:validationIssues += $Description
        return $false
    }
}

function Test-DirectoryExists {
    param($Path, $Description)
    if (Test-Path $Path -PathType Container) {
        Write-Host "✅ $Description" -ForegroundColor Green
        $script:passed++
        return $true
    } else {
        Write-Host "❌ $Description" -ForegroundColor Red
        $script:validationIssues += $Description
        return $false
    }
}

function Test-ContentDoesNotContain {
    param($Path, $Pattern, $Description)
    if (Test-Path $Path) {
        $content = Get-Content $Path -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -match $Pattern) {
            Write-Host "⚠️  $Description" -ForegroundColor Yellow
            $script:warnings += $Description
            return $false
        } else {
            Write-Host "✅ $Description" -ForegroundColor Green
            $script:passed++
            return $true
        }
    } else {
        Write-Host "❌ File not found: $Path" -ForegroundColor Red
        $script:validationIssues += "File not found: $Path"
        return $false
    }
}

# 1. Verify directory structure
Write-Host "📁 Verifying directory structure..." -ForegroundColor Yellow
Test-DirectoryExists "docs" "docs/ directory"
Test-DirectoryExists "scripts" "scripts/ directory"
Test-DirectoryExists "src" "src/ directory"
Test-DirectoryExists "infra" "infra/ directory"
Test-DirectoryExists ".github\workflows" ".github/workflows/ directory"
Test-DirectoryExists ".vscode" ".vscode/ directory"

Write-Host ""

# 2. Verify essential files
Write-Host "📄 Verifying essential files..." -ForegroundColor Yellow
Test-FileExists "README.md" "Main README.md"
Test-FileExists "LICENSE" "License file"
Test-FileExists ".gitignore" ".gitignore file"
Test-FileExists "CONTRIBUTING.md" "Contribution guide"
Test-FileExists ".env.example" "Example environment variables file"
Test-FileExists "QUICKSTART.md" "Quick start guide"

Write-Host ""

# 3. Verify documentation
Write-Host "📚 Verifying documentation..." -ForegroundColor Yellow
Test-FileExists "docs\README.md" "Documentation README"
Test-FileExists "docs\DEMO-GUIDE.md" "Demo guide"
Test-FileExists "docs\DEPLOYMENT.md" "Deployment guide"
Test-FileExists "docs\DEMO-READY-FINAL.md" "Final summary"

Write-Host ""

# 4. Verify scripts
Write-Host "📜 Verifying scripts..." -ForegroundColor Yellow
Test-FileExists "scripts\README.md" "Scripts README"
Test-FileExists "scripts\deploy.ps1" "Deployment script"
Test-FileExists "scripts\demo-final.ps1" "Demo script"
Test-FileExists "scripts\generate-traffic.ps1" "Traffic generator"

Write-Host ""

# 5. Verify source code
Write-Host "💻 Verifying source code..." -ForegroundColor Yellow
Test-FileExists "src\README.md" "Source code README"
Test-FileExists "src\webapp-simple\server.js" "Main Node.js application"
Test-FileExists "src\webapp-simple\package.json" "Node.js package.json"
Test-FileExists "infra\main.json" "Main ARM template"
Test-FileExists "infra\main.parameters.json" "ARM template parameters"

Write-Host ""

# 6. Verify there is no sensitive information
Write-Host "🔒 Verifying absence of sensitive information..." -ForegroundColor Yellow
Test-ContentDoesNotContain "src\webapp-simple\server.js" "21c11c05-b593-4b4b-93d3-d2e9a5f6be25" "No real keys in server.js"
Test-ContentDoesNotContain "infra\main.parameters.json" "ComplexPassword123!" "No real passwords in parameters"

# Verify sensitive files do not exist
if (Test-Path "DEMO-CREDENTIALS.md") {
    Write-Host "⚠️  Sensitive file found: DEMO-CREDENTIALS.md" -ForegroundColor Yellow
    $warnings += "Sensitive file found: DEMO-CREDENTIALS.md"
} else {
    Write-Host "✅ No credential files found" -ForegroundColor Green
    $passed++
}

Write-Host ""

# 7. Verify GitHub configuration
Write-Host "🐙 Verifying GitHub configuration..." -ForegroundColor Yellow
Test-FileExists ".github\workflows\validate.yml" "GitHub Actions workflow"
Test-FileExists ".vscode\extensions.json" "Recommended VS Code extensions"
Test-FileExists "azure-monitor-demo.code-workspace" "VS Code workspace"

Write-Host ""

# 8. Verify temporary/unnecessary files
Write-Host "🧹 Verifying cleanup..." -ForegroundColor Yellow
$tempFiles = @("*.zip", "logs-extracted", "temp-logs", "*.log", "Lab.sln")
$foundTemp = $false

foreach ($pattern in $tempFiles) {
    $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
    if ($files) {
        Write-Host "⚠️  Temporary files found: $pattern" -ForegroundColor Yellow
        $warnings += "Temporary files found: $pattern"
        $foundTemp = $true
    }
}

if (-not $foundTemp) {
    Write-Host "✅ No temporary files found" -ForegroundColor Green
    $passed++
}

Write-Host ""

# 9. Verify project size
Write-Host "📊 Verifying project size..." -ForegroundColor Yellow
$totalSize = (Get-ChildItem -Recurse -File | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)

if ($totalSizeMB -lt 50) {
    Write-Host "✅ Project size: $totalSizeMB MB (appropriate for GitHub)" -ForegroundColor Green
    $passed++
} else {
    Write-Host "⚠️  Project size: $totalSizeMB MB (consider optimization)" -ForegroundColor Yellow
    $warnings += "Large project size: $totalSizeMB MB"
}

Write-Host ""

Write-Host "📋 VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host "✅ Checks passed: $passed" -ForegroundColor Green

if ($warnings.Count -gt 0) {
    Write-Host "⚠️  Warnings: $($warnings.Count)" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   - $warning" -ForegroundColor Yellow
    }
}

if ($validationIssues.Count -gt 0) {
    Write-Host "❌ Errors: $($validationIssues.Count)" -ForegroundColor Red
    $validationIssues | ForEach-Object {
        Write-Host "   - $_" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "🚨 ACTION REQUIRED: Fix errors before pushing to GitHub" -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "🎉 PROJECT READY FOR GITHUB!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Recommended next steps:" -ForegroundColor White
    Write-Host "1. Run: .\init-github.ps1" -ForegroundColor Cyan
    Write-Host "2. Create repository on GitHub" -ForegroundColor Cyan
    Write-Host "3. Connect and push code" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🌟 Your Azure Monitor Demo project is perfectly prepared!" -ForegroundColor Green
}
