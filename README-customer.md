# the customer — Azure Monitor Demo: Use Cases & Playbook

This document describes the **eight use cases** requested by the customer, maps each one to the assets in this repository, and provides step-by-step instructions you can follow to replay them on your own Azure subscription.

> **Prerequisites** — an Azure subscription, Azure CLI (`az`) logged in, and a deployed instance of this demo (see the [Deployment Guide](docs/DEPLOYMENT.md) or run `pwsh scripts/deploy.ps1`).

---

## Table of Contents

1. [UC-1: Integration of External Services — OTel & Non-OTel Ingestion](#uc-1-integration-of-external-services--otel--non-otel-ingestion)
2. [UC-2: Azure Copilot for Advanced Dashboards & KQL Queries](#uc-2-azure-copilot-for-advanced-dashboards--kql-queries)
3. [UC-3: Dashboard Templates for External Services (Outside Azure)](#uc-3-dashboard-templates-for-external-services-outside-azure)
4. [UC-4: Drill-Down Across Infrastructure / Applications / External Services](#uc-4-drill-down-across-infrastructure--applications--external-services)
5. [UC-5: Cross-Tenant / Multi-Region / Multi-Subscription / RBAC / Quotas](#uc-5-cross-tenant--multi-region--multi-subscription--rbac--quotas)
6. [UC-6: Data Retention & Cost Control by Label (Tenant)](#uc-6-data-retention--cost-control-by-label-tenant)
7. [UC-7: Cost Optimization — Quick Actions to Reduce Costs](#uc-7-cost-optimization--quick-actions-to-reduce-costs)
8. [UC-8: Investigation & Root Cause Analysis (RCA) with Copilot](#uc-8-investigation--root-cause-analysis-rca-with-copilot)

---

## UC-1: Integration of External Services — OTel & Non-OTel Ingestion

### What this demonstrates

How to ingest telemetry from **OTel-instrumented services** (traces, metrics, logs via the OpenTelemetry protocol) and **non-OTel sources** (custom JSON payloads from external fraud APIs, policy management systems, or third-party SaaS) into Azure Monitor / Log Analytics.

### Where to find the code in this repo

| Component | File | Purpose |
|---|---|---|
| **OTel Collector config** | [`src/otel-collector/otel-collector-config.yaml`](src/otel-collector/otel-collector-config.yaml) | Receives OTLP (gRPC/HTTP), enriches with `tenant`/`environment`/`region` attributes, exports to Azure Monitor |
| **Non-OTel ingestion endpoint** | [`src/webapp-simple/server.js`](src/webapp-simple/server.js) — `POST /api/external-ingest` (line ~450) | Accepts JSON from external services, tracks events, traces, metrics, dependencies, and exceptions in Application Insights |
| **Traffic generator (both OTel-like & non-OTel)** | [`scripts/generate-observability-traffic.ps1`](scripts/generate-observability-traffic.ps1) | Sends mixed traffic to both OTel endpoints and the non-OTel `/api/external-ingest` endpoint |
| **OTel ingestion skill (full guide)** | [`.github/skills/otel-ingestion/SKILL.md`](.github/skills/otel-ingestion/SKILL.md) | Step-by-step: SDK bootstrap, OTel Collector setup, DCR for Logs Ingestion API, validation KQL |

### Step-by-step replay

#### A. OTel path (instrumented microservices)

1. **Review the OTel Collector config:**

   ```bash
   cat src/otel-collector/otel-collector-config.yaml
   ```

   Key sections:
   - `receivers.otlp` — accepts gRPC (`:4317`) and HTTP (`:4318`)
   - `processors.resource` — stamps every record with `tenant`, `environment`, `region`
   - `exporters.azuremonitor` — sends to Application Insights via the connection string

2. **Run the Collector** (Docker example):

   ```bash
   docker run --rm \
     -e TENANT_ID="eu-insurer-a" \
     -e ENVIRONMENT="prod" \
     -e REGION="francecentral" \
     -e APPLICATIONINSIGHTS_CONNECTION_STRING="<your-connection-string>" \
     -p 4317:4317 -p 4318:4318 \
     -v $(pwd)/src/otel-collector/otel-collector-config.yaml:/etc/otelcol/config.yaml \
     otel/opentelemetry-collector-contrib:latest
   ```

3. **Point any OTel-instrumented app** at `http://localhost:4317` (gRPC) or `http://localhost:4318` (HTTP).

#### B. Non-OTel path (external HTTP/JSON sources)

1. **Send a non-OTel payload** to the running web app:

   ```bash
   curl -X POST https://<YOUR_APP>.azurewebsites.net/api/external-ingest \
     -H "Content-Type: application/json" \
     -d '{
       "serviceName": "fraud-api",
       "eventType": "FraudCheck",
       "tenant": "eu-insurer-a",
       "region": "francecentral",
       "latencyMs": 342,
       "status": "success"
     }'
   ```

2. **Verify in Log Analytics** (allow 2-5 minutes for ingestion):

   ```kql
   // Non-OTel events
   customEvents
   | where name == "External_Service_Ingested"
   | where customDimensions["sourceType"] == "non-otel"
   | project timestamp, tostring(customDimensions["serviceName"]),
             tostring(customDimensions["tenant"]), tostring(customDimensions["status"])
   | take 20
   ```

#### C. Generate mixed traffic (both paths)

```powershell
pwsh scripts/generate-observability-traffic.ps1 `
  -BaseUrl "https://<YOUR_APP>.azurewebsites.net" `
  -DurationSeconds 300 `
  -Tenant "eu-insurer-a" `
  -Region "francecentral"
```

This sends OTel-like calls (health, claims, fraud-check, load) **and** non-OTel payloads (`/api/external-ingest`) simultaneously.

---

## UC-2: Azure Copilot for Advanced Dashboards & KQL Queries

### What this demonstrates

Using **Microsoft Copilot in Azure** (the portal AI assistant) to interactively generate KQL queries and build dashboards without writing queries from scratch.

### Where to find the reference material

| Asset | File |
|---|---|
| Dashboard customization skill | [`.github/skills/dashboard-customization/SKILL.md`](.github/skills/dashboard-customization/SKILL.md) |
| Reference KQL library | [`.github/skills/dashboard-customization/SKILL.md`](.github/skills/dashboard-customization/SKILL.md) — "Reference KQL library" section |
| Customer KQL queries doc | [`docs/CUSTOMERA-KQL-QUERIES.md`](docs/CUSTOMERA-KQL-QUERIES.md) |

### Step-by-step replay

1. **Generate traffic first** (so you have data to query):

   ```powershell
   pwsh scripts/generate-observability-traffic.ps1 `
     -BaseUrl "https://<YOUR_APP>.azurewebsites.net" `
     -DurationSeconds 300
   ```

2. **Open Azure Portal → Application Insights → Logs** blade.

3. **Use Copilot in Azure** (the chat icon in the top bar) with these tested prompts:

   | Prompt to type in Copilot | What it produces |
   |---|---|
   | "Show me the p95 latency of claims processing over the last hour in a timechart" | A `customMetrics` query with `percentile(value, 95)` |
   | "Create a barchart of fraud flag events grouped by 5-minute windows" | A `customEvents` query filtered on `Fraud_Flag_Raised` |
   | "Show external service dependency health with error rates" | A `dependencies` query with `countif(success==false)` |
   | "Build a dashboard tile for error breakdown by endpoint" | A `requests` query grouped by `name` and `resultCode` |

4. **Verify each query returns data.** Paste these pre-tested queries if Copilot's output needs adjustment:

   ```kql
   // Claims processing latency (p50 / p95)
   customMetrics
   | where name == "Claim_Processing_Duration"
   | summarize p50=percentile(value, 50), p95=percentile(value, 95) by bin(timestamp, 5m)
   | render timechart
   ```

   ```kql
   // Fraud flag events
   customEvents
   | where name == "Fraud_Flag_Raised"
   | summarize FraudFlags=count() by bin(timestamp, 5m)
   | render barchart
   ```

   ```kql
   // External service health (fraud-api, policy-service, etc.)
   dependencies
   | where target in ("fraud-api", "policy-service", "payment-gateway", "partner-claims-api")
   | summarize total=count(), failed=countif(success == false),
       p95_ms=percentile(duration, 95) by target, bin(timestamp, 5m)
   | extend errorRate = round(todouble(failed) / todouble(total) * 100, 2)
   | render timechart
   ```

   ```kql
   // Error breakdown by endpoint
   requests
   | where success == false
   | summarize count() by name, resultCode
   | order by count_ desc
   | render table
   ```

5. **Pin any tile to a dashboard** — click **Pin to dashboard** above the query results chart.

> **Note:** Custom metric names in this demo use underscores (e.g., `Claim_Processing_Duration`, `Fraud_Detection_Latency`). Adjust Copilot-generated queries if they use different naming conventions.

---

## UC-3: Dashboard Templates for External Services (Outside Azure)

### What this demonstrates

Pre-built Azure Portal dashboard templates for monitoring **external (non-Azure) services** such as third-party fraud APIs, partner claims systems, and payment gateways.

### Where to find the template

| Asset | File |
|---|---|
| External services dashboard ARM template | [`infra/external-services-dashboard.template.json`](infra/external-services-dashboard.template.json) |

This template deploys a `Microsoft.Portal/dashboards` resource with three tiles:

| Tile | KQL query | Purpose |
|---|---|---|
| **External Service Health** | `dependencies` filtered by `fraud-api` / `policy-api` | p95 latency and call count over time |
| **External Service Exceptions** | `exceptions` filtered by `sourceSystem == 'external-service'` | Error types and messages from external calls |
| **Drill-down by Operation** | `union requests, dependencies, traces, exceptions` filtered by `operation_Id` | End-to-end trace for a single operation |

### Step-by-step: import the dashboard

#### Option A: Deploy via Azure CLI

```bash
# Get your Application Insights resource ID
APP_INSIGHTS_ID=$(az monitor app-insights component show \
  --app "<your-app-insights-name>" \
  --resource-group "<your-rg>" \
  --query id -o tsv)

# Deploy the dashboard template
az deployment group create \
  --resource-group "<your-rg>" \
  --template-file infra/external-services-dashboard.template.json \
  --parameters applicationInsightsResourceId="$APP_INSIGHTS_ID" \
               dashboardName="customer-external-services"
```

#### Option B: Import via Azure Portal

1. Go to **Azure Portal → Dashboard → + New dashboard → Import from file**.
2. Select `infra/external-services-dashboard.template.json`.
3. When prompted, fill in the `applicationInsightsResourceId` parameter with your Application Insights resource ID.
4. Click **Save**.

#### Verify the dashboard works

1. Generate some external-service traffic first:

   ```powershell
   pwsh scripts/generate-observability-traffic.ps1 `
     -BaseUrl "https://<YOUR_APP>.azurewebsites.net" `
     -DurationSeconds 120
   ```

2. Open the deployed dashboard in Azure Portal. You should see:
   - Time series chart showing external service latency and volume
   - Table of external service exceptions (if any errors were generated)
   - The drill-down tile (enter an `operation_Id` from the other tiles to trace end-to-end)

---

## UC-4: Drill-Down Across Infrastructure / Applications / External Services

### What this demonstrates

A reproducible workflow to **drill down from a high-level symptom to the root cause** across three layers: infrastructure metrics, application telemetry, and external service dependencies.

### Step-by-step replay

#### Step 1: Generate traffic and some errors

```powershell
pwsh scripts/generate-observability-traffic.ps1 `
  -BaseUrl "https://<YOUR_APP>.azurewebsites.net" `
  -DurationSeconds 300
```

The script randomly injects ~10% errors and external service failures.

#### Step 2: Start at the infrastructure layer

Open **Azure Portal → Application Insights → Application Map**.

This shows the topology: your App Service, its SQL dependency, and external services (`fraud-api`, `policy-service`, etc.). Red circles indicate failures.

**KQL — Infrastructure health:**

```kql
// App Service CPU and memory
performanceCounters
| where category == "Process" or category == "Processor"
| where name in ("% Processor Time", "Private Bytes")
| summarize avg(value) by name, bin(timestamp, 5m)
| render timechart
```

#### Step 3: Drill into the application layer

Click on the App Service node in Application Map, or run:

```kql
// Top failing requests
requests
| where success == false
| where timestamp > ago(1h)
| summarize FailCount=count() by name, resultCode
| order by FailCount desc
| render table
```

```kql
// Slowest endpoints (p95)
requests
| where timestamp > ago(1h)
| summarize p95_ms=percentile(duration, 95), count() by name
| order by p95_ms desc
| render table
```

#### Step 4: Drill into external services

```kql
// External dependency failures
dependencies
| where timestamp > ago(1h)
| where target in ("fraud-api", "policy-service", "payment-gateway", "partner-claims-api")
| summarize total=count(), failed=countif(success == false),
    avg_ms=avg(duration), p95_ms=percentile(duration, 95) by target
| extend errorRate = round(todouble(failed) / todouble(total) * 100, 2)
| order by errorRate desc
| render table
```

#### Step 5: Trace a single failing operation end-to-end

Pick an `operation_Id` from a failing request:

```kql
// Get a sample failing operation
requests
| where success == false
| where timestamp > ago(1h)
| project timestamp, operation_Id, name, resultCode, duration
| take 1
```

Then trace it across all telemetry types:

```kql
// Replace <OPERATION_ID> with the value from above
union requests, dependencies, traces, exceptions
| where operation_Id == "<OPERATION_ID>"
| order by timestamp asc
| project timestamp, itemType, name, target, duration, success, message, type
```

This shows the complete timeline: incoming request → dependency calls → traces → exceptions.

#### Step 6: Check exceptions detail

```kql
// Exceptions for that operation
exceptions
| where operation_Id == "<OPERATION_ID>"
| project timestamp, type, outerMessage, innermostMessage, details
```

---

## UC-5: Cross-Tenant / Multi-Region / Multi-Subscription / RBAC / Quotas

### What this demonstrates

How to use **Grafana or Azure Dashboards/Workbooks** to query a **central place** that aggregates information from **different Log Analytics Workspaces (LAW)** and Azure Monitor instances across different regions, subscriptions, or resource groups.

For this example, we show how to query another LAW in a different resource group within the same subscription.

### Where to find the reference material

| Asset | File |
|---|---|
| Multi-tenant KQL skill | [`.github/skills/multi-tenant-kql/SKILL.md`](.github/skills/multi-tenant-kql/SKILL.md) |

### Step-by-step replay

#### Step 1: Identify your workspace resource IDs

```bash
# List all Log Analytics workspaces in the subscription
az monitor log-analytics workspace list \
  --query "[].{Name:name, ResourceGroup:resourceGroup, Id:id}" -o table
```

Note two workspace IDs — your primary (demo) workspace and a secondary workspace in a different resource group.

#### Step 2: Cross-workspace query using the `workspace()` function

Open **Log Analytics → Logs** on your primary workspace and run:

```kql
// Query the local workspace
customEvents
| where timestamp > ago(1h)
| summarize LocalCount=count() by bin(timestamp, 5m)

// Now union with a remote workspace in another resource group
union
  (customEvents | where timestamp > ago(1h)),
  (workspace("/subscriptions/<SUB_ID>/resourceGroups/<OTHER_RG>/providers/Microsoft.OperationalInsights/workspaces/<OTHER_WS_NAME>").customEvents
   | where TimeGenerated > ago(1h))
| extend source_workspace = iif(isempty(_ResourceId), "primary", "secondary")
| summarize EventCount=count() by source_workspace, bin(timestamp, 5m)
| render timechart
```

> **Replace** `<SUB_ID>`, `<OTHER_RG>`, and `<OTHER_WS_NAME>` with your actual values from Step 1.

#### Step 3: Cross-workspace query with tenant isolation

```kql
// Claims events from multiple workspaces, isolated by tenant tag
union
  (customEvents
   | where name in ("Claim_Submitted", "Fraud_Flag_Raised")
   | extend tenant = tostring(customDimensions["tenant"]), ws = "primary"),
  (workspace("<SECONDARY_WS_RESOURCE_ID>").customEvents
   | where name in ("Claim_Submitted", "Fraud_Flag_Raised")
   | extend tenant = tostring(customDimensions["tenant"]), ws = "secondary")
| summarize ClaimCount=count() by tenant, ws, bin(timestamp, 5m)
| render timechart
```

#### Step 4: Create an Azure Workbook with cross-workspace parameter

1. Go to **Azure Portal → Monitor → Workbooks → + New**.
2. Add a **Parameter** step:
   - Name: `SelectedWorkspace`
   - Type: Resource picker
   - Resource type: `microsoft.operationalinsights/workspaces`
   - Allow multi-selection: **Yes**
3. Add a **Query** step using:

   ```kql
   union
     (customEvents | where timestamp > ago(1h)),
     (workspace("{SelectedWorkspace}").customEvents | where TimeGenerated > ago(1h))
   | extend tenant = tostring(customDimensions["tenant"])
   | summarize count() by tenant, bin(timestamp, 5m)
   | render timechart
   ```

4. **Save** the workbook. Users can now select any combination of workspaces from the dropdown.

#### Step 5: Access Azure Managed Grafana and assign required roles

Before running the Grafana part of the demo, assign the following roles to the user who will run the demo:

- **Azure Managed Grafana Workspace Contributor**
- **Azure Monitor Dashboards with Grafana Contributor**
- **Grafana Admin**

Portal navigation and assignment flow:

1. Go to **Azure Portal** → **Resource groups** → open your demo resource group.
2. Open the deployed Azure Managed Grafana resource (name starts with `graf-`).
3. Open **Access control (IAM)** → **Add** → **Add role assignment**.
4. Assign each of the three roles above to the demo operator user or group.
5. Open the Grafana instance via **Overview** → **Endpoint**.

CLI alternative (assign all three roles):

```bash
# Replace values first
PRINCIPAL_OBJECT_ID="<USER_OR_GROUP_OBJECT_ID>"
SCOPE="/subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.Dashboard/grafana/<GRAFANA_NAME>"

for role in \
  "Azure Managed Grafana Workspace Contributor" \
  "Azure Monitor Dashboards with Grafana Contributor" \
  "Grafana Admin"
do
  az role assignment create \
    --assignee-object-id "$PRINCIPAL_OBJECT_ID" \
    --assignee-principal-type User \
    --role "$role" \
    --scope "$SCOPE"
done
```

> If you are assigning to a group, set `--assignee-principal-type Group`.

#### Step 6: Cross-workspace in Azure Managed Grafana

1. In Azure Managed Grafana, add a **Azure Monitor** data source.
2. Configure it with the Log Analytics workspace resource ID of each workspace.
3. Create a new dashboard panel with this query (use the Grafana KQL editor):

   ```kql
   union
     (customEvents),
     (workspace("<SECONDARY_WS_RESOURCE_ID>").customEvents)
   | where $__timeFilter(timestamp)
   | extend tenant = tostring(customDimensions["tenant"])
   | summarize count() by tenant, bin(timestamp, $__interval)
   ```

4. The `$__timeFilter()` and `$__interval` are Grafana macros for the dashboard time picker.

#### Step 7: RBAC — scope reader access per tenant resource group

```bash
# Assign Reader role on a tenant's resource group to their Azure AD group
az role assignment create \
  --role "Reader" \
  --assignee-object-id "<TENANT_AAD_GROUP_OBJECT_ID>" \
  --assignee-principal-type Group \
  --scope "/subscriptions/<SUB_ID>/resourceGroups/<TENANT_RG>"
```

#### Step 8: Per-tenant ingestion quota

```bash
# Set a daily cap (GB) on a workspace to prevent over-spending
az monitor log-analytics workspace update \
  --resource-group "<TENANT_RG>" \
  --workspace-name "<TENANT_WS_NAME>" \
  --quota 5   # GB per day
```

Monitor quota usage:

```kql
Usage
| where TimeGenerated > ago(1d) and IsBillable == true
| summarize DailyGB = sum(Quantity) / 1024
| extend CapGB = 5.0, WarningThreshold = 0.9
| where DailyGB >= CapGB * WarningThreshold
| project DailyGB, CapGB, PctUsed = round(DailyGB / CapGB * 100, 2)
```

---

## UC-6: Data Retention & Cost Control by Label (Tenant)

### What this demonstrates

How to configure **data retention** for logs, metrics, and traces at the table level, and how to create **cost and budget alerts** related to ingestion.

### Where to find the reference material

| Asset | File |
|---|---|
| Log Analytics cost skill | [`.github/skills/log-analytics-cost/SKILL.md`](.github/skills/log-analytics-cost/SKILL.md) |
| ARM template (workspace) | [`infra/main.json`](infra/main.json) — `Microsoft.OperationalInsights/workspaces` resource |

### Step-by-step: change data retention

#### A. Change workspace-level default retention

```bash
# Set default retention to 90 days (from current 30)
az monitor log-analytics workspace update \
  --resource-group "<YOUR_RG>" \
  --workspace-name "<YOUR_WS_NAME>" \
  --retention-time 90
```

#### B. Change retention per table (logs)

```bash
# Set retention for the requests table (application logs/traces)
az monitor log-analytics workspace table update \
  --resource-group "<YOUR_RG>" \
  --workspace-name "<YOUR_WS_NAME>" \
  --name "AppRequests" \
  --retention-time 60 \
  --total-retention-time 365

# Set retention for traces
az monitor log-analytics workspace table update \
  --resource-group "<YOUR_RG>" \
  --workspace-name "<YOUR_WS_NAME>" \
  --name "AppTraces" \
  --retention-time 30 \
  --total-retention-time 90

# Set retention for dependencies (external service calls)
az monitor log-analytics workspace table update \
  --resource-group "<YOUR_RG>" \
  --workspace-name "<YOUR_WS_NAME>" \
  --name "AppDependencies" \
  --retention-time 30 \
  --total-retention-time 90

# Set retention for performance counters (metrics)
az monitor log-analytics workspace table update \
  --resource-group "<YOUR_RG>" \
  --workspace-name "<YOUR_WS_NAME>" \
  --name "AppPerformanceCounters" \
  --retention-time 14 \
  --total-retention-time 30

# Set retention for exceptions
az monitor log-analytics workspace table update \
  --resource-group "<YOUR_RG>" \
  --workspace-name "<YOUR_WS_NAME>" \
  --name "AppExceptions" \
  --retention-time 90 \
  --total-retention-time 365
```

#### C. Recommended retention by data type

| Table | Hot retention (days) | Archive / Total (days) | Rationale |
|---|---|---|---|
| `AppRequests` | 60 | 365 | Request logs for audit |
| `AppTraces` | 30 | 90 | Debug traces, short-lived |
| `AppDependencies` | 30 | 90 | External call logs |
| `AppPerformanceCounters` | 14 | 30 | Infrastructure metrics, volatile |
| `AppExceptions` | 90 | 365 | Error investigation, regulatory |
| `AppEvents` (custom events) | 90 | 365 | Business events (claims, fraud) |
| `AppMetrics` (custom metrics) | 60 | 180 | KPI metrics |

#### D. Verify current retention settings

```bash
az monitor log-analytics workspace table list \
  --resource-group "<YOUR_RG>" \
  --workspace-name "<YOUR_WS_NAME>" \
  --query "[].{Table:name, Retention:retentionInDays, TotalRetention:totalRetentionInDays}" \
  -o table
```

### Step-by-step: create cost and budget alerts

#### A. Create a budget for the resource group

```bash
# Create a monthly budget of $100 for the demo resource group
az consumption budget create \
  --budget-name "customer-monitor-budget" \
  --amount 100 \
  --category Cost \
  --time-grain Monthly \
  --start-date "2025-01-01" \
  --end-date "2026-12-31" \
  --resource-group "<YOUR_RG>"
```

#### B. Create an alert rule for Log Analytics ingestion volume

Open **Azure Portal → Monitor → Alerts → + Create alert rule** and configure:

1. **Scope:** your Log Analytics workspace
2. **Condition:** Custom log search:

   ```kql
   Usage
   | where IsBillable == true and TimeGenerated > ago(1d)
   | summarize DailyGB = sum(Quantity) / 1024
   | where DailyGB > 2
   ```

3. **Threshold:** Greater than 0 (the query already filters for > 2 GB)
4. **Action group:** Email / Teams notification
5. **Alert name:** "Daily ingestion exceeds 2 GB"

#### C. KQL to monitor cost by tenant label

```kql
// Per-tenant ingestion volume (last 7 days)
union customEvents, customMetrics, traces, dependencies
| where TimeGenerated > ago(7d)
| extend tenant = tostring(customDimensions["tenant"])
| summarize RecordCount=count(), EstimatedMB=count() * 0.001 by tenant, bin(TimeGenerated, 1d)
| order by EstimatedMB desc
| render barchart
```

---

## UC-7: Cost Optimization — Quick Actions to Reduce Costs

### What this demonstrates

Best quick-win configurations to optimize Azure Monitor / Log Analytics costs.

### Quick wins checklist

| # | Action | Impact | How to do it |
|---|---|---|---|
| 1 | **Reduce hot retention on debug tables** | High | Set `AppTraces` and `AppDependencies` to 30 days (see UC-6 Step B) |
| 2 | **Reduce performance counter frequency** | Medium | In AMA DCR, change collection interval from 60s to 300s |
| 3 | **Enable adaptive sampling** | High | Already enabled by default in Application Insights SDK. Verify it's not disabled in `server.js` |
| 4 | **Filter health-check noise via DCR** | Medium | Add `transformKql`: `source \| where not(name has "Health_Check" and success == true)` |
| 5 | **Filter verbose traces in production** | Medium | Add `transformKql`: `source \| where severityLevel >= 2` (drops Verbose and Information) |
| 6 | **Set daily ingestion cap** | Safety net | `az monitor log-analytics workspace update --quota 5` (5 GB/day) |
| 7 | **Use Basic Logs tier for high-volume tables** | High | Switch debug/trace tables to Basic Logs (lower cost, limited query) |
| 8 | **Archive instead of delete** | Low cost | Use archive tier for compliance data beyond hot retention |

### Step-by-step: apply the top 3 quick wins

#### Quick Win 1: Reduce retention on debug tables

```bash
az monitor log-analytics workspace table update \
  --resource-group "<YOUR_RG>" --workspace-name "<YOUR_WS_NAME>" \
  --name "AppTraces" --retention-time 30 --total-retention-time 90

az monitor log-analytics workspace table update \
  --resource-group "<YOUR_RG>" --workspace-name "<YOUR_WS_NAME>" \
  --name "AppDependencies" --retention-time 30 --total-retention-time 90
```

#### Quick Win 2: Set a daily ingestion cap

```bash
az monitor log-analytics workspace update \
  --resource-group "<YOUR_RG>" --workspace-name "<YOUR_WS_NAME>" \
  --quota 5
```

#### Quick Win 3: Switch high-volume tables to Basic Logs

```bash
# Basic Logs costs ~$0.65/GB vs. $2.76/GB for Analytics Logs
az monitor log-analytics workspace table update \
  --resource-group "<YOUR_RG>" --workspace-name "<YOUR_WS_NAME>" \
  --name "AppTraces" --plan "Basic"
```

### Cost visibility dashboards

Run these KQL queries in **Log Analytics → Logs** to see where money is going:

```kql
// Daily spend trend (last 30 days)
Usage
| where IsBillable == true and TimeGenerated > ago(30d)
| summarize DailyGB = sum(Quantity) / 1024 by bin(TimeGenerated, 1d)
| extend DailyCostUSD = round(DailyGB * 2.76, 2)
| render timechart
```

```kql
// Top 10 most expensive tables (last 7 days)
Usage
| where TimeGenerated > ago(7d) and IsBillable == true
| summarize TotalGB = sum(Quantity) / 1024 by DataType
| top 10 by TotalGB
| extend EstimatedCostUSD = round(TotalGB * 2.76, 2)
| render barchart
```

```kql
// Tables exceeding 1 GB/day — immediate action needed
Usage
| where IsBillable == true and TimeGenerated > ago(1d)
| summarize DailyGB = sum(Quantity) / 1024 by DataType
| where DailyGB > 1
| extend Action = "Review sampling or retention for this table"
| project DataType, DailyGB, Action
| render table
```

> **Pricing note:** The $2.76/GB rate is the Pay-As-You-Go rate as of 2024. Verify current pricing at https://azure.microsoft.com/en-us/pricing/details/monitor/

---

## UC-8: Investigation & Root Cause Analysis (RCA) with Copilot

### What this demonstrates

How to use **Microsoft Copilot in Azure** and pre-built KQL queries to investigate incidents and find root causes across application layers.

### Step-by-step replay

#### Step 1: Generate errors for investigation

```powershell
# Generate 5 minutes of traffic including ~10% errors
pwsh scripts/generate-observability-traffic.ps1 `
  -BaseUrl "https://<YOUR_APP>.azurewebsites.net" `
  -DurationSeconds 300
```

#### Step 2: Open Copilot in Azure

Navigate to **Azure Portal → Application Insights resource → Overview**. Click the **Copilot** icon (chat button) in the top bar.

#### Step 3: Use these Copilot prompts for RCA

| # | Prompt | What Copilot does |
|---|---|---|
| 1 | "Summarize the health of this application in the last 30 minutes" | Overview of request volume, error rate, latency |
| 2 | "What are the top errors in the last hour?" | Lists exceptions grouped by type and count |
| 3 | "Investigate the root cause of fraud-api failures" | Drills into dependency failures for `fraud-api` |
| 4 | "Show me the slowest requests and their dependencies" | Correlates slow requests with dependency latency |
| 5 | "Are there any anomalies in the last hour?" | Detects latency spikes or error rate changes |

#### Step 4: Manual RCA queries (if Copilot is not available or for validation)

**A. Identify the problem — error spike:**

```kql
// Error rate over time
requests
| where timestamp > ago(1h)
| summarize Total=count(), Failed=countif(success == false) by bin(timestamp, 5m)
| extend ErrorRate = round(todouble(Failed) / todouble(Total) * 100, 2)
| render timechart
```

**B. Find the failing endpoints:**

```kql
// Which endpoints are failing?
requests
| where success == false and timestamp > ago(1h)
| summarize FailCount=count() by name, resultCode
| order by FailCount desc
```

**C. Check if the problem is in a dependency:**

```kql
// Dependency failure correlation
dependencies
| where success == false and timestamp > ago(1h)
| summarize FailCount=count(), AvgDuration=avg(duration) by target, name
| order by FailCount desc
```

**D. Find the root cause — trace a specific failing operation:**

```kql
// Get a failing operation ID
let failedOp = requests
| where success == false and timestamp > ago(1h)
| top 1 by timestamp desc
| project operation_Id;
// Trace the full operation
union requests, dependencies, traces, exceptions
| where operation_Id in (failedOp)
| order by timestamp asc
| project timestamp, itemType, name, target, duration, success, message, type, outerMessage
```

**E. Exception details for the failing operation:**

```kql
// Detailed exception info
exceptions
| where timestamp > ago(1h)
| summarize count() by type, outerMessage
| order by count_ desc
```

**F. Impact assessment:**

```kql
// How many users / tenants are affected?
requests
| where success == false and timestamp > ago(1h)
| extend tenant = tostring(customDimensions["tenant"])
| summarize AffectedRequests=count() by tenant
| order by AffectedRequests desc
```

---

## Quick Reference: File Map

| Use Case | Key Files |
|---|---|
| UC-1: OTel ingestion | [`src/otel-collector/otel-collector-config.yaml`](src/otel-collector/otel-collector-config.yaml), [`src/webapp-simple/server.js`](src/webapp-simple/server.js) |
| UC-1: Non-OTel ingestion | [`src/webapp-simple/server.js`](src/webapp-simple/server.js) (`POST /api/external-ingest`), [`scripts/generate-observability-traffic.ps1`](scripts/generate-observability-traffic.ps1) |
| UC-2: Copilot + KQL | [`.github/skills/dashboard-customization/SKILL.md`](.github/skills/dashboard-customization/SKILL.md), [`docs/CUSTOMERA-KQL-QUERIES.md`](docs/CUSTOMERA-KQL-QUERIES.md) |
| UC-3: Dashboard templates | [`infra/external-services-dashboard.template.json`](infra/external-services-dashboard.template.json) |
| UC-4: Drill-down | Application Map in Azure Portal + KQL queries in this doc |
| UC-5: Cross-tenant / RBAC | [`.github/skills/multi-tenant-kql/SKILL.md`](.github/skills/multi-tenant-kql/SKILL.md) |
| UC-6: Retention / cost alerts | [`.github/skills/log-analytics-cost/SKILL.md`](.github/skills/log-analytics-cost/SKILL.md), [`infra/main.json`](infra/main.json) |
| UC-7: Cost optimization | [`.github/skills/log-analytics-cost/SKILL.md`](.github/skills/log-analytics-cost/SKILL.md) |
| UC-8: RCA with Copilot | KQL queries in this doc, [`scripts/generate-observability-traffic.ps1`](scripts/generate-observability-traffic.ps1) |

---

## Generating Traffic for All Use Cases

Before replaying any use case, generate telemetry data:

```powershell
# Quick (2 minutes) — enough for most demos
pwsh scripts/generate-observability-traffic.ps1 `
  -BaseUrl "https://<YOUR_APP>.azurewebsites.net" `
  -DurationSeconds 120

# Full demo (5 minutes) — recommended for all use cases
pwsh scripts/generate-observability-traffic.ps1 `
  -BaseUrl "https://<YOUR_APP>.azurewebsites.net" `
  -DurationSeconds 300 `
  -Tenant "eu-insurer-a" `
  -Region "francecentral"
```

Wait **2-5 minutes** after traffic generation for data to appear in Application Insights / Log Analytics.
