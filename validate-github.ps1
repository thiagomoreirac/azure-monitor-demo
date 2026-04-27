# 🔍 Validación Final del Proyecto para GitHub
# Este script verifica que el proyecto esté listo para ser subido a GitHub

Write-Host "🔍 VALIDACIÓN FINAL - Azure Monitor Demo" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

$errors = @()
$warnings = @()
$passed = 0

# Función helper para checks
function Test-FileExists {
    param($Path, $Description)
    if (Test-Path $Path) {
        Write-Host "✅ $Description" -ForegroundColor Green
        $script:passed++
        return $true
    } else {
        Write-Host "❌ $Description" -ForegroundColor Red
        $script:errors += $Description
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
        $script:errors += $Description
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
        Write-Host "❌ Archivo no encontrado: $Path" -ForegroundColor Red
        $script:errors += "Archivo no encontrado: $Path"
        return $false
    }
}

# 1. Verificar estructura de directorios
Write-Host "📁 Verificando estructura de directorios..." -ForegroundColor Yellow
Test-DirectoryExists "docs" "Directorio docs/"
Test-DirectoryExists "scripts" "Directorio scripts/"
Test-DirectoryExists "src" "Directorio src/"
Test-DirectoryExists "infra" "Directorio infra/"
Test-DirectoryExists ".github\workflows" "Directorio .github/workflows/"
Test-DirectoryExists ".vscode" "Directorio .vscode/"

Write-Host ""

# 2. Verificar archivos esenciales
Write-Host "📄 Verificando archivos esenciales..." -ForegroundColor Yellow
Test-FileExists "README.md" "README.md principal"
Test-FileExists "LICENSE" "Archivo de licencia"
Test-FileExists ".gitignore" "Archivo .gitignore"
Test-FileExists "CONTRIBUTING.md" "Guía de contribución"
Test-FileExists ".env.example" "Archivo de ejemplo de variables de entorno"
Test-FileExists "QUICKSTART.md" "Guía de inicio rápido"

Write-Host ""

# 3. Verificar documentación
Write-Host "📚 Verificando documentación..." -ForegroundColor Yellow
Test-FileExists "docs\README.md" "README de documentación"
Test-FileExists "docs\DEMO-GUIDE.md" "Guía de demostración"
Test-FileExists "docs\DEPLOYMENT.md" "Guía de despliegue"
Test-FileExists "docs\DEMO-READY-FINAL.md" "Resumen final"

Write-Host ""

# 4. Verificar scripts
Write-Host "📜 Verificando scripts..." -ForegroundColor Yellow
Test-FileExists "scripts\README.md" "README de scripts"
Test-FileExists "scripts\deploy.ps1" "Script de despliegue"
Test-FileExists "scripts\demo-final.ps1" "Script de demostración"
Test-FileExists "scripts\generate-traffic.ps1" "Generador de tráfico"

Write-Host ""

# 5. Verificar código fuente
Write-Host "💻 Verificando código fuente..." -ForegroundColor Yellow
Test-FileExists "src\README.md" "README de código fuente"
Test-FileExists "src\webapp-simple\server.js" "Aplicación Node.js principal"
Test-FileExists "src\webapp-simple\package.json" "Package.json de Node.js"
Test-FileExists "infra\main.json" "ARM Template principal"
Test-FileExists "infra\main.parameters.json" "Parámetros ARM Template"

Write-Host ""

# 6. Verificar que no hay información sensible
Write-Host "🔒 Verificando ausencia de información sensible..." -ForegroundColor Yellow
Test-ContentDoesNotContain "src\webapp-simple\server.js" "21c11c05-b593-4b4b-93d3-d2e9a5f6be25" "Sin keys reales en server.js"
Test-ContentDoesNotContain "infra\main.parameters.json" "ComplexPassword123!" "Sin passwords reales en parámetros"

# Verificar que no existen archivos sensibles
if (Test-Path "DEMO-CREDENTIALS.md") {
    Write-Host "⚠️  Archivo sensible encontrado: DEMO-CREDENTIALS.md" -ForegroundColor Yellow
    $warnings += "Archivo sensible encontrado: DEMO-CREDENTIALS.md"
} else {
    Write-Host "✅ Sin archivos de credenciales" -ForegroundColor Green
    $passed++
}

Write-Host ""

# 7. Verificar configuración GitHub
Write-Host "🐙 Verificando configuración GitHub..." -ForegroundColor Yellow
Test-FileExists ".github\workflows\validate.yml" "GitHub Actions workflow"
Test-FileExists ".vscode\extensions.json" "Extensiones VS Code recomendadas"
Test-FileExists "azure-monitor-demo.code-workspace" "Workspace de VS Code"

Write-Host ""

# 8. Verificar archivos temporales/innecesarios
Write-Host "🧹 Verificando limpieza..." -ForegroundColor Yellow
$tempFiles = @("*.zip", "logs-extracted", "temp-logs", "*.log", "Lab.sln")
$foundTemp = $false

foreach ($pattern in $tempFiles) {
    $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
    if ($files) {
        Write-Host "⚠️  Archivos temporales encontrados: $pattern" -ForegroundColor Yellow
        $warnings += "Archivos temporales encontrados: $pattern"
        $foundTemp = $true
    }
}

if (-not $foundTemp) {
    Write-Host "✅ Sin archivos temporales" -ForegroundColor Green
    $passed++
}

Write-Host ""

# 9. Verificar tamaño del proyecto
Write-Host "📊 Verificando tamaño del proyecto..." -ForegroundColor Yellow
$totalSize = (Get-ChildItem -Recurse -File | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)

if ($totalSizeMB -lt 50) {
    Write-Host "✅ Tamaño del proyecto: $totalSizeMB MB (apropiado para GitHub)" -ForegroundColor Green
    $passed++
} else {
    Write-Host "⚠️  Tamaño del proyecto: $totalSizeMB MB (considerar optimizar)" -ForegroundColor Yellow
    $warnings += "Proyecto grande: $totalSizeMB MB"
}

Write-Host ""

# 10. Resumen final
Write-Host "📋 RESUMEN DE VALIDACIÓN" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host "✅ Checks pasados: $passed" -ForegroundColor Green

if ($warnings.Count -gt 0) {
    Write-Host "⚠️  Advertencias: $($warnings.Count)" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   - $warning" -ForegroundColor Yellow
    }
}

if ($errors.Count -gt 0) {
    Write-Host "❌ Errores: $($errors.Count)" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "   - $error" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "🚨 ACCIÓN REQUERIDA: Corregir errores antes de subir a GitHub" -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "🎉 PROYECTO LISTO PARA GITHUB!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Próximos pasos recomendados:" -ForegroundColor White
    Write-Host "1. Ejecutar: .\init-github.ps1" -ForegroundColor Cyan
    Write-Host "2. Crear repositorio en GitHub" -ForegroundColor Cyan
    Write-Host "3. Conectar y subir código" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🌟 Tu proyecto Azure Monitor Demo está perfectamente preparado!" -ForegroundColor Green
}
