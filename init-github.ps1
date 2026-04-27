# 🚀 Script de Inicialización para GitHub
# Ejecutar este script después de instalar Git

Write-Host "🎯 Inicializando repositorio Git para Azure Monitor Demo..." -ForegroundColor Cyan
Write-Host ""

# Verificar que Git esté instalado
try {
    git --version | Out-Null
    Write-Host "✅ Git detectado" -ForegroundColor Green
} catch {
    Write-Host "❌ Git no está instalado. Por favor instalar Git primero:" -ForegroundColor Red
    Write-Host "   https://git-scm.com/download/windows" -ForegroundColor Yellow
    exit 1
}

# Inicializar repositorio si no existe
if (-not (Test-Path ".git")) {
    Write-Host "📂 Inicializando repositorio Git..." -ForegroundColor Yellow
    git init
    Write-Host "✅ Repositorio inicializado" -ForegroundColor Green
} else {
    Write-Host "✅ Repositorio Git ya existe" -ForegroundColor Green
}

# Configurar usuario si no está configurado
$userName = git config user.name
$userEmail = git config user.email

if (-not $userName) {
    $name = Read-Host "Introduce tu nombre para Git"
    git config user.name $name
    Write-Host "✅ Nombre configurado: $name" -ForegroundColor Green
}

if (-not $userEmail) {
    $email = Read-Host "Introduce tu email para Git"
    git config user.email $email
    Write-Host "✅ Email configurado: $email" -ForegroundColor Green
}

# Agregar archivos
Write-Host "📦 Agregando archivos al repositorio..." -ForegroundColor Yellow
git add .

# Verificar estado
Write-Host "📊 Estado del repositorio:" -ForegroundColor Yellow
git status --short

# Hacer commit inicial
Write-Host "💾 Creando commit inicial..." -ForegroundColor Yellow
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

Write-Host "✅ Commit inicial creado" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 Repositorio preparado para GitHub!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Próximos pasos:" -ForegroundColor White
Write-Host "1. Crear repositorio en GitHub:" -ForegroundColor Cyan
Write-Host "   https://github.com/new" -ForegroundColor Blue
Write-Host ""
Write-Host "2. Conectar repositorio local con GitHub:" -ForegroundColor Cyan
Write-Host "   git remote add origin https://github.com/tu-usuario/azure-monitor-demo.git" -ForegroundColor Blue
Write-Host ""
Write-Host "3. Configurar rama main como predeterminada:" -ForegroundColor Cyan
Write-Host "   git branch -M main" -ForegroundColor Blue
Write-Host ""
Write-Host "4. Subir código a GitHub:" -ForegroundColor Cyan
Write-Host "   git push -u origin main" -ForegroundColor Blue
Write-Host ""
Write-Host "5. (Opcional) Configurar GitHub Actions:" -ForegroundColor Cyan
Write-Host "   - Ir a Settings > Secrets and variables > Actions" -ForegroundColor Blue
Write-Host "   - Agregar AZURE_CREDENTIALS para validación automática" -ForegroundColor Blue
Write-Host ""
Write-Host "🔗 El proyecto incluye:" -ForegroundColor Yellow
Write-Host "   ✅ README.md completo con instrucciones" -ForegroundColor Green
Write-Host "   ✅ Documentación organizada en /docs" -ForegroundColor Green
Write-Host "   ✅ Scripts organizados en /scripts" -ForegroundColor Green
Write-Host "   ✅ Código fuente limpio sin información sensible" -ForegroundColor Green
Write-Host "   ✅ .gitignore configurado apropiadamente" -ForegroundColor Green
Write-Host "   ✅ Licencia MIT incluida" -ForegroundColor Green
Write-Host "   ✅ GitHub Actions para validación" -ForegroundColor Green
Write-Host "   ✅ Guías de contribución" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 ¡Tu proyecto está listo para impresionar en GitHub!" -ForegroundColor Green
