# 📋 Azure Monitor Demo - Quick Start Guide

This document will help you set up the demo environment in less than 15 minutes.

## ⚡ Express Setup (TL;DR)

```powershell
# 1. Clone and configure
git clone https://github.com/your-username/azure-monitor-demo.git
cd azure-monitor-demo

# 2. Configure Azure CLI
az login
az account set --subscription "your-subscription-id"

# 3. Deploy everything
.\scripts\deploy.ps1

# 4. Verify operation
.\scripts\demo-final.ps1

# 5. Open demo
# URL: Will be shown at the end of deployment
# Azure Portal: portal.azure.com > Resource Groups > demo-monitor-rg
```

## 🎯 For the Demo

### Important URLs
- **Web App**: `https://app-[unique-id].azurewebsites.net`
- **Health Check**: `https://app-[unique-id].azurewebsites.net/health`
- **Products API**: `https://app-[unique-id].azurewebsites.net/api/products`
- **Generate Error**: `https://app-[unique-id].azurewebsites.net/error`

### Azure Portal
1. **Application Insights** → Live Metrics (impressive live)
2. **Application Map** → Shows visual dependencies
3. **Performance** → Latency analysis
4. **Failures** → Error tracking
5. **Alerts** → 3 preconfigured alerts

### Traffic Script
```powershell
# Generate traffic during demo
.\scripts\generate-traffic.ps1
```

## 🚨 If Something Goes Wrong

```powershell
# Restart application
az webapp restart --name app-[unique-id] --resource-group demo-monitor-rg

# View logs
az webapp log tail --name app-[unique-id] --resource-group demo-monitor-rg

# Clean everything
az group delete --name demo-monitor-rg --yes --no-wait
```

## 💰 Costs
- **Estimated total**: ~$0.76/day
- **For 1-hour demo**: ~$0.03

## 📞 Support
- 📖 [Complete documentation](docs/)
- 🐛 [Report issues](../../issues)
- 💬 [Discussions](../../discussions)

---
🎉 **In 15 minutes you'll have an impressive Azure Monitor demo!**
