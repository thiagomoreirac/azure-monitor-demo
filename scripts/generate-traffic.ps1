# Script to generate test traffic to the application
param(
    [Parameter(Mandatory=$false)]
    [string]$AppUrl = "https://app-bwkinh757hlog.azurewebsites.net"
)

Write-Host "🚀 Generating traffic to: $AppUrl" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Available endpoints once the app is running
$endpoints = @(
    @{Name="Home/Swagger"; Path="/"},
    @{Name="Health Check"; Path="/api/health"},
    @{Name="Products API"; Path="/api/products"},
    @{Name="Simulate Error"; Path="/api/simulate-error"},
    @{Name="Load Test"; Path="/api/load-test"},
    @{Name="Memory Test"; Path="/api/memory-test"}
)

Write-Host "`n🔍 Checking if application is available..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri $AppUrl -Method GET -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Application available!" -ForegroundColor Green
        
        # Generate test traffic
        Write-Host "`n🔄 Generating test traffic..." -ForegroundColor Yellow
        
        for ($i = 1; $i -le 30; $i++) {
            $endpoint = $endpoints | Get-Random
            $url = "$AppUrl$($endpoint.Path)"
            
            try {
                $response = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 10
                Write-Host "  [$i/30] $($endpoint.Name) - Status: $($response.StatusCode)" -ForegroundColor Green
            }
            catch {
                Write-Host "  [$i/30] $($endpoint.Name) - Error: $($_.Exception.Message)" -ForegroundColor Yellow
            }
            
            Start-Sleep -Milliseconds 500
        }
        
        Write-Host "`n✅ Traffic generated successfully!" -ForegroundColor Green
        Write-Host "`n📊 You can now:" -ForegroundColor Cyan
        Write-Host "1. Open Azure Portal → Resource Group: demo-monitor-rg" -ForegroundColor White
        Write-Host "2. Go to Application Insights" -ForegroundColor White
        Write-Host "3. View Live Metrics" -ForegroundColor White
        Write-Host "4. Explore metrics and logs" -ForegroundColor White
        
    } else {
        Write-Host "⚠️ Application responded with status code: $($response.StatusCode)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ Application is not available yet: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`n💡 Possible reasons:" -ForegroundColor Yellow
    Write-Host "1. Deployment is still in progress" -ForegroundColor White
    Write-Host "2. The application is starting up" -ForegroundColor White
    Write-Host "3. Build issues" -ForegroundColor White
    
    Write-Host "`n🔧 In the meantime, you can:" -ForegroundColor Cyan
    Write-Host "1. Check logs in Azure Portal → App Service → Log stream" -ForegroundColor White
    Write-Host "2. Review basic infrastructure metrics" -ForegroundColor White
    Write-Host "3. Configure Application Insights" -ForegroundColor White
}

Write-Host "`n🌐 URLs for your demo:" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "App URL: $AppUrl" -ForegroundColor White
Write-Host "Swagger: $AppUrl/swagger" -ForegroundColor White
Write-Host "Health: $AppUrl/api/health" -ForegroundColor White
Write-Host "Products: $AppUrl/api/products" -ForegroundColor White
Write-Host "Errors: $AppUrl/api/simulate-error" -ForegroundColor White
Write-Host "Load Test: $AppUrl/api/load-test" -ForegroundColor White
Write-Host "Memory Test: $AppUrl/api/memory-test" -ForegroundColor White

Write-Host "`n🎯 To open Azure Portal:" -ForegroundColor Cyan
Write-Host "https://portal.azure.com/#@/resource/subscriptions//resourceGroups/demo-monitor-rg/overview" -ForegroundColor White
