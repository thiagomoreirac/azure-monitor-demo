# Azure Monitor Demo Deployment Script
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$Location = "France Central",
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId
)

# Set subscription if provided
if ($SubscriptionId) {
    Write-Host "Setting subscription to: $SubscriptionId"
    az account set --subscription $SubscriptionId
}

if (-not $SubscriptionId) {
    $SubscriptionId = az account show --query "id" -o tsv
}

# Create resource group
Write-Host "Creating resource group: $ResourceGroupName in $Location"
az group create --name $ResourceGroupName --location $Location

# Resolve Microsoft Entra principal for SQL AAD admin (required by policy)
$accountType = az account show --query "user.type" -o tsv
$accountName = az account show --query "user.name" -o tsv

if ($accountType -eq "servicePrincipal") {
    $sqlAdAdminSid = az ad sp show --id $accountName --query "id" -o tsv
    $sqlAdAdminLogin = $accountName
    $sqlAdAdminPrincipalType = "Application"
} else {
    $sqlAdAdminSid = az ad signed-in-user show --query "id" -o tsv
    $sqlAdAdminLogin = az ad signed-in-user show --query "userPrincipalName" -o tsv
    $sqlAdAdminPrincipalType = "User"
}

if (-not $sqlAdAdminSid) {
    Write-Host "❌ Could not resolve SQL Entra admin object ID from current account." -ForegroundColor Red
    Write-Host "Sign in with 'az login' and ensure Microsoft Graph permissions are available." -ForegroundColor Yellow
    exit 1
}

# Deploy ARM template
Write-Host "Deploying ARM template..."
$deploymentResult = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "infra/main.json" `
    --parameters "infra/main.parameters.json" `
    --parameters sqlAdAdminSid="$sqlAdAdminSid" sqlAdAdminLogin="$sqlAdAdminLogin" sqlAdAdminPrincipalType="$sqlAdAdminPrincipalType" `
    --verbose

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Infrastructure deployment completed successfully!" -ForegroundColor Green
    
    # Parse deployment outputs
    $outputs = $deploymentResult | ConvertFrom-Json
    $webAppUrl = $outputs.properties.outputs.webAppUrl.value
    $appInsightsName = $outputs.properties.outputs.applicationInsightsName.value
    $logWorkspaceName = $outputs.properties.outputs.logAnalyticsWorkspaceName.value
    $grafanaName = $outputs.properties.outputs.grafanaName.value
    
    Write-Host "`n📊 Deployment Information:" -ForegroundColor Cyan
    Write-Host "Web App URL: $webAppUrl" -ForegroundColor Yellow
    Write-Host "Application Insights: $appInsightsName" -ForegroundColor Yellow
    Write-Host "Log Analytics Workspace: $logWorkspaceName" -ForegroundColor Yellow
    Write-Host "Azure Managed Grafana: $grafanaName" -ForegroundColor Yellow
    
    # Deploy web app from Node.js source (customer-customized app)
    Write-Host "`n🚀 Deploying web application package..." -ForegroundColor Cyan
    $webAppName = $outputs.properties.outputs.webAppUrl.value.Replace("https://", "").Replace(".azurewebsites.net", "")
    $webAppResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$webAppName"

    # Enable publishing policies required by zip deploy in locked-down tenants
    az resource update --ids "$webAppResourceId/basicPublishingCredentialsPolicies/scm" --api-version 2022-03-01 --set properties.allow=true | Out-Null
    az resource update --ids "$webAppResourceId/basicPublishingCredentialsPolicies/ftp" --api-version 2022-03-01 --set properties.allow=true | Out-Null

    # Ensure Node runtime is configured for the web app
    az webapp config appsettings set --resource-group $ResourceGroupName --name $webAppName --settings WEBSITE_NODE_DEFAULT_VERSION="~20" SCM_DO_BUILD_DURING_DEPLOYMENT="true" | Out-Null

    Set-Location "src/webapp-simple"
    if (Test-Path "deploy.zip") { Remove-Item "deploy.zip" -Force }
    Write-Host "📦 Installing Node.js dependencies..." -ForegroundColor Cyan
    npm install --production --silent
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ npm install failed." -ForegroundColor Red
        Set-Location "../../"
        exit 1
    }
    Compress-Archive -Path "*" -DestinationPath "deploy.zip" -Force
    az webapp deployment source config-zip --resource-group $ResourceGroupName --name $webAppName --src "deploy.zip"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Web app code deployment failed." -ForegroundColor Red
        Set-Location "../../"
        exit 1
    }

    az webapp restart --resource-group $ResourceGroupName --name $webAppName | Out-Null

    Set-Location "../../"

    # Build and deploy load test function (best effort)
    Write-Host "`n⚡ Building and deploying load test function..." -ForegroundColor Cyan
    $functionName = az functionapp list --resource-group $ResourceGroupName --query "[?contains(name, 'func-load-')].name | [0]" -o tsv

    if (-not $functionName) {
        Write-Host "⚠️ No load test Function App found in resource group; skipping function code deployment." -ForegroundColor Yellow
    } else {
        Set-Location "src/loadtest"
        dotnet publish -c Release -o bin/Release/publish

        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️ Function project build failed; infrastructure remains deployed, but function code deployment was skipped." -ForegroundColor Yellow
            Set-Location "../../"
        } else {
            if (Test-Path "deploy.zip") { Remove-Item "deploy.zip" -Force }
            Compress-Archive -Path "bin/Release/publish/*" -DestinationPath "deploy.zip" -Force
            az functionapp deployment source config-zip --resource-group $ResourceGroupName --name $functionName --src "deploy.zip"

            if ($LASTEXITCODE -ne 0) {
                Write-Host "⚠️ Function zip deployment failed; web app and infrastructure are still deployed." -ForegroundColor Yellow
            }

            Set-Location "../../"
        }
    }
    
    Write-Host "`n🎉 Deployment completed successfully!" -ForegroundColor Green
    Write-Host "`n📖 Next Steps for your demo:" -ForegroundColor Cyan
    Write-Host "1. Open the web application: $webAppUrl" -ForegroundColor White
    Write-Host "2. Navigate to different endpoints to generate metrics:" -ForegroundColor White
    Write-Host "   - $webAppUrl/health" -ForegroundColor Gray
    Write-Host "   - $webAppUrl/api/claims" -ForegroundColor Gray
    Write-Host "   - $webAppUrl/error" -ForegroundColor Gray
    Write-Host "   - $webAppUrl/load" -ForegroundColor Gray
    Write-Host "   - $webAppUrl/fraud-check" -ForegroundColor Gray
    Write-Host "3. Open Application Insights in Azure Portal to view metrics" -ForegroundColor White
    Write-Host "4. In Azure Managed Grafana IAM, assign these roles to the demo operator: Azure Managed Grafana Workspace Contributor, Azure Monitor Dashboards with Grafana Contributor, Grafana Admin" -ForegroundColor White
    Write-Host "5. Open Azure Managed Grafana (Overview -> Endpoint) and use the built-in Azure Monitor data source to query Azure Monitor and the Log Analytics workspace" -ForegroundColor White
    Write-Host "6. Check Azure Monitor for alerts and dashboards" -ForegroundColor White
    Write-Host "7. Generate live telemetry: pwsh -File scripts/generate-observability-traffic.ps1 -BaseUrl $webAppUrl" -ForegroundColor White
    
} else {
    Write-Host "❌ Infrastructure deployment failed!" -ForegroundColor Red
    exit 1
}
