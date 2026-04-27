# 📖 Deployment Guide - Azure Monitor Demo

This guide provides detailed instructions for deploying the Azure Monitor and Application Insights demo environment.

## 📋 Prerequisites

### Required Software
- **Azure CLI** 2.40.0 or higher
- **PowerShell** 5.1 or higher (Windows) / PowerShell Core 7.0+ (Cross-platform)
- **Git** (to clone the repository)

### Azure Configuration
- Active Azure subscription
- Contributor permissions on the subscription
- Azure CLI authenticated (`az login`)

### Prerequisites Verification
```powershell
# Verify Azure CLI
az --version

# Verify authentication
az account show

# Verify PowerShell
$PSVersionTable.PSVersion
```

## 🚀 Deployment Steps

### 1. Environment Preparation

#### Clone Repository
```bash
git clone https://github.com/your-username/azure-monitor-demo.git
cd azure-monitor-demo
```

#### Configure Variables (Optional)
Edit `infra/main.parameters.json` to customize:
- **Azure Region**: `location`
- **Resource Prefix**: `resourcePrefix`
- **SKU Configuration**: To optimize costs

### 2. Parameters Configuration

#### main.parameters.json File
```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "location": {
            "value": "North Europe"
        },
        "resourcePrefix": {
            "value": "demo"
        },
        "sqlAdminLogin": {
            "value": "sqladmin"
        },
        "sqlAdminPassword": {
            "value": "ComplexPassword123!"
        }
    }
}
```

### 3. Run the Deployment

#### Option A: Automated Script (Recommended)
```powershell
# Deployment with default values
.\deploy.ps1

# Deployment with custom parameters
.\deploy.ps1 -ResourceGroupName "my-demo-rg" -Location "West Europe"
```

#### Option B: Manual Commands
```powershell
# Define variables
$resourceGroup = "demo-monitor-rg"
$location = "North Europe"

# Create resource group
az group create --name $resourceGroup --location $location

# Deploy ARM template
az deployment group create `
    --resource-group $resourceGroup `
    --template-file "infra/main.json" `
    --parameters "infra/main.parameters.json"
```

### 4. Post-Deployment

#### Configure the Application
```powershell
# Get deployment information
$appName = az deployment group show --resource-group $resourceGroup --name "main" --query "properties.outputs.appServiceName.value" --output tsv

# Configure App Service for Node.js
az webapp config appsettings set --name $appName --resource-group $resourceGroup --settings WEBSITE_NODE_DEFAULT_VERSION=18.12.0

# Deploy application
az webapp deployment source config-zip --name $appName --resource-group $resourceGroup --src "webapp-simple-deploy.zip"
```

#### Verify Deployment
```powershell
# Run verification script
.\demo-final.ps1
```

## 🔧 Advanced Configurations

### Alert Customization

#### Modify Thresholds in ARM Template
In `infra/main.json`, locate the alert sections:

```json
{
    "name": "High Response Time Alert",
    "properties": {
        "criteria": {
            "allOf": [{
                "threshold": 2000,  // Change threshold here
                "timeAggregation": "Average"
            }]
        }
    }
}
```

### Application Insights Configuration

#### Custom Environment Variables
```powershell
# Configure sampling rate
az webapp config appsettings set --name $appName --resource-group $resourceGroup --settings APPINSIGHTS_SAMPLING_PERCENTAGE=50

# Configure log level
az webapp config appsettings set --name $appName --resource-group $resourceGroup --settings APPINSIGHTS_LOG_LEVEL=Information
```

### Scalability Configuration

#### Auto-scaling Rules
```powershell
# Configure CPU-based auto-scaling
az monitor autoscale create --resource-group $resourceGroup --resource $appName --resource-type Microsoft.Web/serverfarms --name autoscale-$appName --min-count 1 --max-count 3 --count 1

# Add scale-out rule
az monitor autoscale rule create --resource-group $resourceGroup --autoscale-name autoscale-$appName --condition "Percentage CPU > 70 avg 5m" --scale out 1
```

## 📊 Deployment Validation

### Verification Checklist

#### ✅ Deployed Resources
- [ ] Resource Group created
- [ ] App Service running
- [ ] Application Insights configured
- [ ] SQL Database online
- [ ] Log Analytics Workspace active
- [ ] Storage Account available
- [ ] Azure Functions deployed
- [ ] Alerts configured

#### ✅ Application Running
```powershell
# Verify main endpoints
$baseUrl = "https://$appName.azurewebsites.net"

# Health check
Invoke-RestMethod -Uri "$baseUrl/health"

# Products API
Invoke-RestMethod -Uri "$baseUrl/api/products"

# Generate error (should return 500)
try { Invoke-RestMethod -Uri "$baseUrl/error" } catch { "Error generated successfully" }
```

#### ✅ Telemetry Working
1. Open Azure Portal → Application Insights
2. Verify Live Metrics Stream
3. Generate traffic and verify metrics
4. Confirm logs are appearing

### Validation Scripts

#### Full Health Check Script
```powershell
# Archivo: validate-deployment.ps1
param(
    [string]$ResourceGroupName = "demo-monitor-rg",
    [string]$AppName
)

Write-Host "🔍 Validating deployment..." -ForegroundColor Yellow

# Verify resources
$resources = az resource list --resource-group $ResourceGroupName --query "[].{name:name, type:type, provisioningState:properties.provisioningState}" --output table
Write-Host "✅ Deployed resources:" -ForegroundColor Green
$resources

# Verify application
if ($AppName) {
    $appUrl = "https://$AppName.azurewebsites.net"
    try {
        $health = Invoke-RestMethod -Uri "$appUrl/health" -TimeoutSec 10
        Write-Host "✅ Application running: $($health.status)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Application error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "🎯 Validation completed" -ForegroundColor Green
```

## 🚨 Troubleshooting

### Common Errors

#### Error: Resource Group already exists
```powershell
# Check existing resources
az resource list --resource-group $resourceGroup --output table

# Delete if needed
az group delete --name $resourceGroup --yes --no-wait
```

#### Error: Deployment timeout
```powershell
# Check deployment status
az deployment group show --resource-group $resourceGroup --name "main" --query "properties.provisioningState"

# Review specific errors
az deployment group show --resource-group $resourceGroup --name "main" --query "properties.error"
```

#### Error: App Service is not responding
```powershell
# Check logs
az webapp log tail --name $appName --resource-group $resourceGroup

# Restart if needed
az webapp restart --name $appName --resource-group $resourceGroup
```

#### Error: No data in Application Insights
```powershell
# Verify connection string
az webapp config appsettings list --name $appName --resource-group $resourceGroup --query "[?name=='APPLICATIONINSIGHTS_CONNECTION_STRING']"

# Generate test traffic
for ($i=1; $i -le 10; $i++) {
    Invoke-RestMethod -Uri "https://$appName.azurewebsites.net/health" | Out-Null
    Start-Sleep 1
}
```

### Logs and Diagnostics

#### Enable Detailed Logging
```powershell
# Enable application logging
az webapp log config --name $appName --resource-group $resourceGroup --application-logging filesystem

# Enable web server logging
az webapp log config --name $appName --resource-group $resourceGroup --web-server-logging filesystem

# View logs in real time
az webapp log tail --name $appName --resource-group $resourceGroup
```

#### Download Logs
```powershell
# Download deployment logs
az webapp deployment source show --name $appName --resource-group $resourceGroup

# Download application logs
az webapp log download --name $appName --resource-group $resourceGroup --log-file app-logs.zip
```

## 🧹 Resource Cleanup

### Delete Full Environment
```powershell
# Delete resource group and all resources
az group delete --name $resourceGroup --yes --no-wait

# Verify deletion
az group exists --name $resourceGroup
```

### Delete Specific Resources
```powershell
# Delete only the application
az webapp delete --name $appName --resource-group $resourceGroup

# Delete only Application Insights
az monitor app-insights component delete --app $appInsightsName --resource-group $resourceGroup
```

## 📈 Optimizations

### Performance
- Configure CDN for static content
- Implement caching strategies
- Optimizar queries de Application Insights

### Costs
- Use basic tiers for demos
- Configure appropriate retention policies
- Implement auto-shutdown for temporary environments

### Security
- Configurar managed identities
- Implement network security groups
- Configure private endpoints for production

---

## 📞 Support

For deployment issues:
1. Verify prerequisites
2. Review Azure CLI logs
3. Check Azure documentation
4. Create an issue in the project repository

---

**The environment will be ready for the demo in 10-15 minutes!** 🚀
