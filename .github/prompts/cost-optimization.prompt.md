---
description: >-
  Analyze the current Log Analytics ingestion costs, identify the highest-cost
  tables, and generate quick-action recommendations to reduce spend while
  maintaining observability for the customer.
---

You are the `azure-monitor-architect` agent. Use the `log-analytics-cost` skill.

## Required inputs

Ask the user for (or use defaults):

1. **Log Analytics workspace name** — from `infra/main.parameters.json`
2. **Resource group name**
3. **Target monthly budget (USD)** — default $500 if not provided
4. **Analysis window** — default `last 30 days`

## Steps

### 1 — Run the cost baseline queries

Paste these queries in the Log Analytics Logs blade and share the results:

```kql
// A. Top tables by ingestion volume (last 30 days)
Usage
| where TimeGenerated > ago(30d) and IsBillable == true
| summarize TotalGB = sum(Quantity)/1024 by DataType
| top 15 by TotalGB desc
| extend EstimatedCostUSD = round(TotalGB * 2.76, 2)
| render barchart

// B. Daily spend trend
Usage
| where TimeGenerated > ago(30d) and IsBillable == true
| summarize DailyGB = sum(Quantity)/1024 by bin(TimeGenerated,1d)
| extend DailyCostUSD = round(DailyGB * 2.76, 2)
| render timechart

// C. Per-tenant volume (proxy via customDimensions)
union customEvents, customMetrics, traces
| where TimeGenerated > ago(7d)
| extend tenant = tostring(customDimensions["tenant"])
| summarize RecordCount = count() by tenant, itemType
| order by RecordCount desc
```

### 2 — Identify quick wins

Based on query A, apply these rules:

| Table volume | Recommended action |
|---|---|
| `traces` > 500 MB/day | Enable adaptive sampling in `server.js` (verify not disabled) |
| `performanceCounters` > 200 MB/day | Reduce AMA collection interval from 60s → 300s |
| `AppDependencies` / `dependencies` > 300 MB/day | Filter successful fast calls (< 50 ms) via DCR |
| Any custom `_CL` table > 1 GB/day | Add `transformKql` filter to drop noisy events |
| Retention > 90 days on debug tables | Reduce hot retention; move to archive tier |

### 3 — Implement sampling in server.js (if needed)

Verify adaptive sampling is NOT disabled in `src/webapp-simple/server.js`:
```js
// ✅ Good — adaptive sampling is on by default when you call .setup()
appInsights.setup(process.env.APPLICATIONINSIGHTS_CONNECTION_STRING)
  // Do NOT add .setAutoCollectPerformance(false) unless intentional
  .start();
```

To add explicit sampling for high-volume endpoints:
```js
// Throttle dependency tracking for fast health-check calls
appInsights.defaultClient.addTelemetryProcessor((envelope) => {
  if (envelope.data.baseType === 'RemoteDependencyData' &&
      envelope.data.baseData.duration < 10 &&
      envelope.data.baseData.name === 'health_check') {
    return false; // drop from telemetry pipeline
  }
  return true;
});
```

### 4 — Add DCR noise filter (if a table is over budget)

Add to the relevant DCR in `infra/main.json`:
```json
"transformKql": "source | where not(name has 'Health_Check' and success == true) | where severityLevel >= 2"
```

### 5 — Update table retention in infra/main.json

Use the retention table from `.github/skills/log-analytics-cost/SKILL.md` (step 3)
and add/update `Microsoft.OperationalInsights/workspaces/tables` resources for each
high-volume table.

### 6 — Set a daily cap alert

```powershell
# Set workspace daily cap
az monitor log-analytics workspace update `
  --resource-group $ResourceGroupName `
  --workspace-name $WorkspaceName `
  --quota <daily-gb>

# Create an alert rule that fires when the daily cap stops data collection
az monitor scheduled-query create `
  --name "LogAnalytics-DailyCap-Alert" `
  --resource-group $ResourceGroupName `
  --scopes "/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.OperationalInsights/workspaces/<WS>" `
  --condition "count > 0" `
  --condition-query "_LogOperation | where Detail has 'data collection stopped'" `
  --evaluation-frequency 5m `
  --window-size 5m `
  --severity 2 `
  --description "Daily ingestion cap has been reached — data collection stopped"
```

### 7 — Cost optimization summary

After applying changes, re-run query B and compare the daily cost trend.
Report:
- Estimated monthly savings (USD)
- Tables modified and what changed
- Any observability gaps introduced (and how they are mitigated)
