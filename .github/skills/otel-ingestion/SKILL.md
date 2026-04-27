---
name: otel-ingestion
description: >-
  Configure OpenTelemetry (OTel) and non-OTel ingestion pipelines into Azure
  Monitor / Log Analytics. Use when wiring up an OTel Collector, a
  Data Collection Rule (DCR), or a non-OTel source (Syslog, custom JSON,
  external SaaS APIs) to funnel data into the customer observability
  platform.
---

## Purpose

Set up end-to-end telemetry ingestion so that **both OTel-instrumented
microservices and non-OTel external sources** (fraud-model APIs, policy
management systems, third-party SaaS) feed data into the shared
Log Analytics workspace.

## Procedure

### 1 — Identify the ingestion source

| Source type | Recommended path |
|---|---|
| OTel-instrumented app (Node.js, Java, Python) | OTel Collector → Azure Monitor Exporter |
| Non-OTel app (custom JSON / HTTP) | Logs Ingestion API + DCR |
| Infrastructure (VM, container) | Azure Monitor Agent (AMA) + DCR |
| External SaaS / third-party API | Logic App or Function → Logs Ingestion API |
| Syslog / CEF | AMA Syslog DCR |

### 2 — OTel Collector path (preferred for customer microservices)

**a. Add the OpenTelemetry SDK to the Node.js app**

Install:
```bash
npm install @opentelemetry/sdk-node \
            @opentelemetry/auto-instrumentations-node \
            @azure/monitor-opentelemetry-exporter
```

Bootstrap in `src/webapp-simple/server.js` **before** any other `require`:
```js
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { AzureMonitorTraceExporter } = require('@azure/monitor-opentelemetry-exporter');

const sdk = new NodeSDK({
  traceExporter: new AzureMonitorTraceExporter({
    connectionString: process.env.APPLICATIONINSIGHTS_CONNECTION_STRING,
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});
sdk.start();
```

**b. OTel Collector configuration (otel-collector-config.yaml)**

Create `src/otel-collector/otel-collector-config.yaml`:
```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: "0.0.0.0:4317"
      http:
        endpoint: "0.0.0.0:4318"

processors:
  batch:
    timeout: 10s
  resource:
    attributes:
      - key: tenant
        value: "${TENANT_ID}"
        action: upsert
      - key: environment
        value: "${ENVIRONMENT}"
        action: upsert

exporters:
  azuremonitor:
    connection_string: "${APPLICATIONINSIGHTS_CONNECTION_STRING}"
  logging:
    verbosity: detailed

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch, resource]
      exporters: [azuremonitor]
    metrics:
      receivers: [otlp]
      processors: [batch, resource]
      exporters: [azuremonitor]
    logs:
      receivers: [otlp]
      processors: [batch, resource]
      exporters: [azuremonitor]
```

### 3 — Non-OTel path: Logs Ingestion API + DCR

**a. Create a Data Collection Rule (DCR)** in `infra/main.json`:
```json
{
  "type": "Microsoft.Insights/dataCollectionRules",
  "apiVersion": "2022-06-01",
  "name": "[concat('dcr-customer-', variables('resourceToken'))]",
  "location": "[parameters('location')]",
  "tags": "[variables('tags')]",
  "properties": {
    "dataFlows": [
      {
        "streams": ["Custom-CustomerClaimsLogs_CL"],
        "destinations": ["logAnalyticsWorkspace"],
        "transformKql": "source | extend tenant = tostring(customDimensions['tenant'])"
      }
    ],
    "destinations": {
      "logAnalytics": [
        {
          "workspaceResourceId": "[resourceId('Microsoft.OperationalInsights/workspaces', variables('logAnalyticsWorkspaceName'))]",
          "name": "logAnalyticsWorkspace"
        }
      ]
    }
  }
}
```

**b. Send data from a non-OTel source** (PowerShell example):
```powershell
$body = @{
  claimId    = "CLM-20240101-001"
  tenant     = "eu-insurer-a"
  eventType  = "ClaimSubmitted"
  latency_ms = 342
  timestamp  = (Get-Date -Format o)
} | ConvertTo-Json

az rest --method POST `
  --url "https://<DCE_ENDPOINT>/dataCollectionRules/<DCR_ID>/streams/Custom-CustomerClaimsLogs_CL?api-version=2023-01-01" `
  --body $body `
  --headers "Content-Type=application/json"
```

### 4 — Validate pipeline

```kql
// Confirm OTel traces are arriving
traces
| where timestamp > ago(15m)
| summarize count() by cloud_RoleName, sdkVersion
| order by count_ desc

// Confirm custom DCR table is receiving data
CustomerClaimsLogs_CL
| where TimeGenerated > ago(15m)
| take 10

// Check for ingestion errors
_LogOperation
| where Level == "Warning" or Level == "Error"
| where TimeGenerated > ago(1h)
| project TimeGenerated, Operation, Detail
```

### 5 — Tag all ingested data with tenant label

Every ingestion path must attach `tenant`, `environment`, and `region` attributes
so the cost-by-label and RBAC skills can isolate data per tenant.
In the OTel Collector, use the `resource` processor (step 2b).
In DCRs, use `transformKql` to extract these from the payload.
