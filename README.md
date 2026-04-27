# 🚀 Azure Monitor & Application Insights Demo — the customer

A complete demonstration environment for Azure Monitor and Application Insights, customized for **the customer**'s observability requirements (insurance claims processing, fraud detection, policy management, and external-service monitoring).

## 📋 Project Description

This project demonstrates the complete capabilities of Azure Monitor and Application Insights through:

- **Infrastructure as Code (ARM Templates)**: Automated deployment of all Azure resources
- **Web Application with Telemetry**: Node.js + Express with integrated Application Insights (insurance/claims domain)
- **OTel & Non-OTel Ingestion**: OpenTelemetry Collector config + REST endpoint for external service data
- **External Services Dashboard**: Pre-built dashboard template for non-Azure dependencies
- **Automatic Load Generation**: Azure Functions + traffic scripts for mixed OTel/non-OTel telemetry
- **Alerts and Monitoring**: Complete proactive alerts configuration
- **Demo Scripts**: Automation for live presentations
- **Copilot Skills**: Reusable skills for dashboards, cost optimization, multi-tenant KQL, and OTel ingestion

> **the customer use-case playbook:** see [README-customer.md](README-customer.md) for the full list of 8 use cases with step-by-step replay instructions.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   App Service   │    │ Application     │    │  Log Analytics  │
│   (Node.js)     │───▶│   Insights      │───▶│   Workspace     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  SQL Database   │    │   Azure         │    │  Storage        │
│                 │    │   Functions     │    │  Account        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│  OTel Collector │    │ External Svc    │
│  (OTLP→AzMon)  │    │ Ingestion API   │
└─────────────────┘    └─────────────────┘
```


## ✨ Features

### 🎯 Demo Application
- **Interactive Dashboard**: Modern interface with real-time insurance claims metrics
- **RESTful API**: Endpoints for claims, fraud detection, and telemetry generation
- **Error Simulation**: Controlled exception generation (policy lookup, fraud API, DB)
- **Load Testing**: Performance testing endpoints
- **Health Checks**: Automatic health monitoring
- **Non-OTel Ingestion**: `POST /api/external-ingest` for external service data

### 📊 Complete Telemetry
- **Request Tracking**: All HTTP requests with timing
- **Exception Tracking**: Error capture and analysis
- **Dependency Tracking**: External calls monitoring (fraud-api, policy-service, etc.)
- **Custom Metrics**: Business KPIs (Claim_Processing_Duration, Fraud_Detection_Latency, etc.)
- **Custom Events**: Domain events (Claim_Submitted, Fraud_Flag_Raised, etc.)
- **OTel Collector**: Pre-configured for OTLP → Azure Monitor with tenant/region enrichment

### 📈 Dashboard Templates
- **External Services Dashboard**: ARM template for monitoring non-Azure dependencies
  - Located at `infra/external-services-dashboard.template.json`
  - Includes: service health, exceptions, and drill-down tiles

### 🚨 Configured Alerts
- **High Response Time**: Latency > 2000ms
- **Error Rate**: Error rate > 10%
- **High CPU Usage**: CPU > 80%

## 🚀 Quick Start

### Prerequisites
- Azure CLI installed and configured
- PowerShell 5.1 or higher
- Active Azure subscription

### 1. Clone Repository
```bash
git clone <repository-url>
cd azure-monitor-demo
```

### 2. Configure Variables
```powershell
# Edit parameters in infra/main.parameters.json
$resourceGroup = "demo-monitor-rg"
$location = "North Europe"
```

### 3. Deploy Infrastructure
```powershell
# Run deployment script
.\scripts\deploy.ps1
```

### 4. Verify Operation
```powershell
# Run environment tests
.\scripts\demo-final.ps1
```

## 📁 Project Structure

```
azure-monitor-demo/
├── 📁 infra/                     # Infrastructure as Code
│   ├── main.json                 # Main ARM Template
│   ├── main.parameters.json      # Configuration parameters
│   └── external-services-dashboard.template.json  # Dashboard for external services
├── 📁 src/                       # Source code
│   ├── 📁 webapp-simple/         # Node.js Application (claims & fraud domain)
│   │   ├── server.js             # Express server with App Insights + non-OTel ingestion
│   │   ├── package.json          # Node.js dependencies
│   │   └── web.config            # IIS configuration
│   ├── 📁 otel-collector/        # OpenTelemetry Collector
│   │   └── otel-collector-config.yaml  # OTel → Azure Monitor pipeline config
│   ├── 📁 web/                   # .NET Application (alternative)
│   └── 📁 loadtest/              # Azure Functions for load
├── 📁 scripts/                   # Utility scripts
│   ├── deploy.ps1                # Deployment script
│   ├── demo-final.ps1            # Demo preparation script
│   ├── generate-traffic.ps1      # Basic traffic generator
│   └── generate-observability-traffic.ps1  # Mixed OTel + non-OTel traffic
├── 📁 docs/                      # Documentation
│   ├── DEMO-GUIDE.md             # Demo guide
│   ├── DEPLOYMENT.md             # Deployment guide
│   └── CUSTOMERA-KQL-QUERIES.md  # KQL query reference
├── 📁 .github/
│   ├── 📁 skills/                # Copilot skills
│   │   ├── dashboard-customization/  # KQL & dashboard generation
│   │   ├── otel-ingestion/           # OTel & non-OTel pipeline setup
│   │   ├── log-analytics-cost/       # Cost optimization & retention
│   │   └── multi-tenant-kql/         # Cross-tenant RBAC & queries
│   ├── 📁 prompts/               # Reusable prompt workflows
│   └── copilot-instructions.md   # Copilot project instructions
└── README-customer.md               # the customer use-case playbook (8 use cases)
```

## 🎯 Application Endpoints

### API Endpoints
- **GET /** — Main dashboard (insurance claims platform UI)
- **GET /health** — Health check with system metrics
- **GET /api/claims** — Claims API (list all claims)
- **GET|POST /api/submit-claim** — Submit a new insurance claim
- **GET /fraud-check?claimId=N** — Run fraud detection on a claim
- **POST /api/external-ingest** — Non-OTel ingestion endpoint for external service data
- **GET /error** — Controlled error generation (simulates policy, fraud, DB failures)
- **GET /load?iterations=N** — CPU load test
- **GET /memory?size=N** — Memory consumption test
- **GET /dependencies** — External dependencies simulation

### Generated Telemetry
Each endpoint generates specific telemetry:
- Request timing and response codes
- Custom events for business analysis
- Custom metrics for KPIs
- Exception tracking with full context
- Simulated dependency tracking

## 📊 Monitoring and Alerts

### Automatic Metrics
- **HTTP Requests**: Count and timing of all requests
- **Response Times**: Application latency
- **Error Rates**: 4xx/5xx error percentage
- **CPU/Memory**: Server resource usage
- **Dependencies**: External calls performance

### Custom Metrics
- `Claims_API_Duration`: Claims API latency
- `Claim_Processing_Duration`: Claim submission processing time
- `Fraud_Detection_Latency`: Fraud model inference time
- `Fraud_Risk_Score`: Risk score per claim
- `External_Service_Latency`: External (non-OTel) service latency
- `Health_Check_Duration`: Health checks timing
- `Load_Test_Duration`: Load tests duration

### Custom Events
- `Claim_Submitted`: New claim submission
- `Fraud_Flag_Raised`: Fraud detected on a claim
- `Fraud_Check_Started`: Fraud detection initiated
- `External_Service_Ingested`: Non-OTel external data received
- `Claims_API_Called`: Claims list API calls
- `HomePage_Visited`: Dashboard visits
- `Application_Started`: Application startup

## 🎪 Demo Guide

### Preparation (5 minutes)
1. Verify all resources are deployed
2. Run `.\demo-final.ps1` to generate initial traffic
3. Open Azure Portal in Application Insights

### Live Demo (15 minutes)
1. **Show application working** (3 min)
   - Navigate through dashboard
   - Test different endpoints
   - Generate errors and load

2. **Real-time Application Insights** (5 min)
   - Live Metrics Stream
   - Application Map
   - Performance metrics

3. **Telemetry analysis** (4 min)
   - Exception tracking
   - Custom events and metrics
   - Log Analytics queries

4. **Alerts and monitoring** (3 min)
   - Show configured alerts
   - Explain thresholds and actions

## 💰 Cost Estimation

For a demo environment (24 hours):
- **App Service (B1)**: ~$0.50/day
- **Application Insights**: ~$0.10/day  
- **SQL Database (Basic)**: ~$0.15/day
- **Storage Account**: ~$0.01/day
- **Total**: ~$0.76/day

## 🧹 Resource Cleanup

To delete all resources after demo:
```powershell
az group delete --name demo-monitor-rg --yes --no-wait
```

## 🔧 Troubleshooting

### Application not responding
```powershell
# Check status
az webapp show --name <app-name> --resource-group <rg> --query "state"

# Restart if needed
az webapp restart --name <app-name> --resource-group <rg>
```

### No data in Application Insights
```powershell
# Generate test traffic
.\scripts\demo-final.ps1

# Verify connection string
az webapp config appsettings list --name <app-name> --resource-group <rg>
```

## 📖 Additional Documentation

- [the customer Use-Case Playbook](README-customer.md) — 8 use cases with step-by-step replay instructions
- [Demo Guide](docs/DEMO-GUIDE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [KQL Query Reference](docs/CUSTOMERA-KQL-QUERIES.md)
- [Final Summary](docs/DEMO-READY-FINAL.md)
- [Contributing Guide](CONTRIBUTING.md)

## 🤝 Contributing

Contributions are welcome. Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is under the MIT License. See [LICENSE](LICENSE) for more details.

## 🏷️ Tags

`azure` `monitor` `application-insights` `telemetry` `demo` `arm-templates` `nodejs` `express` `infrastructure-as-code` `devops` `opentelemetry` `otel` `insurance` `claims` `fraud-detection`

---

**Built with ❤️ to demonstrate Azure Monitor capabilities**
