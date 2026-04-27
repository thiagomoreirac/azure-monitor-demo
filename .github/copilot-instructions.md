# GitHub Copilot Instructions – Azure Monitor Demo (Shift Technology)

## Customer context

This demo is being customized for **Shift Technology**, an AI-driven insurance claims and fraud-detection company.  
The two reference documents in `docs/` describe their observability platform requirements:

- `docs/Shift-Technology-Observability-Platform-v7-Main.pdf` — high-level platform requirements
- `docs/Shift-Technology-Observability-Platform-v7-Annex-B-Technical.pdf` — technical architecture details

When generating code, names, labels, dashboard titles, alert descriptions, KQL queries, or any user-facing strings, align them with Shift Technology's domain (insurance, claims processing, fraud detection, policy management) and the observability requirements described in those documents.

---

## Project structure

```
azure-monitor-demo/
├── infra/
│   ├── main.json                  # ARM template – all Azure resources
│   └── main.parameters.json       # Deployment parameters (env name, location, credentials)
├── src/
│   ├── webapp-simple/             # PRIMARY app: Node.js + Express + Application Insights SDK
│   │   ├── server.js              # All endpoints, telemetry, custom events & metrics
│   │   ├── package.json
│   │   └── web.config
│   ├── web/                       # .NET alternative app (secondary)
│   └── loadtest/                  # Azure Functions – automatic traffic generator
├── scripts/
│   ├── deploy.ps1                 # Full infra + app deployment (PowerShell + Azure CLI)
│   ├── demo-final.ps1             # Pre-demo traffic generator
│   └── generate-traffic.ps1      # On-demand load generator
├── docs/                          # Customer PDFs + demo guides
└── .github/
    ├── workflows/
    │   ├── copilot-setup-steps.yml  # Pre-installs tools for Copilot cloud agent
    │   └── validate.yml
    └── copilot-instructions.md    # ← this file
```

---

## How to customize the demo for Shift Technology

### 1. Rename resources and labels

- Change `environmentName` default in `infra/main.parameters.json` to something like `shift-monitor`.
- Update resource-naming prefixes in `infra/main.json` (search for `demo-monitor`, `app-`, `log-`, `appi-`).
- Update displayed app title and endpoint descriptions in `src/webapp-simple/server.js`.

### 2. Add customer-specific telemetry

In `src/webapp-simple/server.js`, add custom events and metrics that mirror Shift Technology's business domain:

- **Custom Events**: `ClaimSubmitted`, `FraudFlagRaised`, `PolicyQueried`, `DetectionModelCalled`
- **Custom Metrics**: `ClaimProcessingTime`, `FraudDetectionLatency`, `ModelInferenceTime`
- **Simulated Errors**: database timeout during claim lookup, fraud API 5xx

### 3. Tailor alerts

In `infra/main.json`, update the three alert rules to reflect Shift Technology SLAs:

| Alert | Recommended threshold |
|---|---|
| High Response Time | > 1500 ms (stricter than default 2000 ms) |
| Error Rate | > 5 % (stricter than default 10 %) |
| High CPU Usage | > 75 % (stricter than default 80 %) |

### 4. KQL queries for the demo

Use these in the Log Analytics / Application Insights Logs blade during the demo:

```kql
// Claims processing latency over time
customMetrics
| where name == "ClaimProcessingTime"
| summarize avg(value), percentile(value, 95) by bin(timestamp, 5m)
| render timechart

// Fraud flag events
customEvents
| where name == "FraudFlagRaised"
| summarize count() by bin(timestamp, 5m)
| render barchart

// Error breakdown by endpoint
requests
| where success == false
| summarize count() by name, resultCode
| order by count_ desc
```

### 5. Deploy to Azure

```powershell
# 1. Log in
az login
az account set --subscription "<SUBSCRIPTION_ID>"

# 2. Edit parameters
# Update infra/main.parameters.json: environmentName, location, administratorLogin, administratorPassword

# 3. Deploy everything
pwsh -File scripts/deploy.ps1 -ResourceGroupName "shift-monitor-rg" -Location "North Europe"
```

---

## Coding conventions

- **Node.js app** (`src/webapp-simple/`): CommonJS modules, Express 4.x, `applicationinsights` npm package.
  - Track custom events with `client.trackEvent({ name: "...", properties: { ... } })`.
  - Track custom metrics with `client.trackMetric({ name: "...", value: ... })`.
  - Always flush at the end of important handlers: `client.flush()`.
- **ARM templates** (`infra/main.json`): ARM JSON (not Bicep). Use `[uniqueString(...)]` for resource names.
- **Scripts** (`scripts/`): PowerShell 7+ with Azure CLI (`az` commands). Avoid `Invoke-RestMethod` in favor of `az rest`.
- Do **not** commit real credentials. Use `.env` (gitignored) locally; use GitHub Actions secrets / the `copilot` environment for CI.

---

## Environment variables

| Variable | Where set | Purpose |
|---|---|---|
| `AZURE_SUBSCRIPTION_ID` | `copilot` GitHub env secret | Target Azure subscription |
| `AZURE_TENANT_ID` | `copilot` GitHub env secret | Azure AD tenant |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | App Service config / `.env` | SDK connection |
| `SQL_CONNECTION_STRING` | App Service config / `.env` | Database connection |

---

## Demo flow (15 min – Shift Technology version)

1. **Architecture overview** (2 min) – show the resource group in Azure Portal.
2. **Live Metrics** (3 min) – open Application Insights → Live Metrics, trigger `/api/load-test`.
3. **Claims & fraud events** (3 min) – show custom events in the Logs blade with the KQL queries above.
4. **Alerts** (2 min) – show the three alert rules; explain how they map to Shift Technology SLAs.
5. **Application Map** (2 min) – show dependencies (SQL, external fraud API simulation).
6. **Q&A** (3 min).
