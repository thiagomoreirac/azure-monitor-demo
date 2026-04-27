---
name: log-analytics-cost
description: >-
  Analyze and reduce Log Analytics ingestion costs. Use when reviewing table
  retention settings, adding per-tenant cost visibility, recommending sampling
  or filtering rules, or generating the cost-optimization dashboard.
---

## Purpose

Help Shift Technology control and visualize Log Analytics costs at the **tenant**
and **table** level, using Azure resource tags and workspace-level controls.

## Procedure

### 1 — Baseline: measure current ingestion volume

```kql
// Daily ingestion volume by table (GB)
Usage
| where TimeGenerated > ago(30d)
| where IsBillable == true
| summarize IngestedGB = sum(Quantity) / 1024 by DataType, bin(TimeGenerated, 1d)
| order by IngestedGB desc
| render timechart
```

```kql
// Top 10 most expensive tables (last 7 days)
Usage
| where TimeGenerated > ago(7d) and IsBillable == true
| summarize TotalGB = sum(Quantity) / 1024 by DataType
| top 10 by TotalGB
| extend EstimatedCostUSD = TotalGB * 2.76   // $2.76/GB is the default Pay-As-You-Go rate
| render barchart
```

### 2 — Cost by tenant label

```kql
// Ingestion cost breakdown per tenant (requires tenant tag on resources)
// Run this in Azure Resource Graph or via Monitor Cost Analysis filtered by tag
resources
| where type =~ "microsoft.operationalinsights/workspaces"
| where tags["tenant"] != ""
| project name, tenant = tags["tenant"], costCenter = tags["cost-center"],
          location, resourceGroup
```

```kql
// Per-tenant custom event / metric volume proxy
union customEvents, customMetrics, traces
| where TimeGenerated > ago(7d)
| extend tenant = tostring(customDimensions["tenant"])
| summarize RecordCount = count() by tenant, itemType, bin(TimeGenerated, 1d)
| order by RecordCount desc
| render barchart
```

### 3 — Apply table-level retention (ARM)

Add or update table retention inside the `Microsoft.OperationalInsights/workspaces`
resource in `infra/main.json`. Example for the custom claims table:

```json
{
  "type": "Microsoft.OperationalInsights/workspaces/tables",
  "apiVersion": "2022-10-01",
  "name": "[concat(variables('logAnalyticsWorkspaceName'), '/ShiftClaimsLogs_CL')]",
  "dependsOn": [
    "[resourceId('Microsoft.OperationalInsights/workspaces', variables('logAnalyticsWorkspaceName'))]"
  ],
  "properties": {
    "retentionInDays": 90,
    "totalRetentionInDays": 365
  }
}
```

Recommended retention settings for Shift Technology:

| Table | Hot (days) | Archive (days) | Reason |
|---|---|---|---|
| `ShiftClaimsLogs_CL` | 90 | 365 | Regulatory |
| `ShiftFraudEvents_CL` | 180 | 365 | Fraud investigation |
| `traces` | 30 | 90 | Debugging only |
| `dependencies` | 30 | 90 | Debugging only |
| `performanceCounters` | 14 | 30 | Short-lived infra data |

### 4 — Sampling and filtering recommendations

Add a DCR `transformKql` to drop high-volume noise before ingestion:

```kql
// Drop health-check pings (high volume, low value)
source
| where not(name has "Health_Check" and success == true)
```

For traces, filter below WARN in production:
```kql
source
| where severityLevel >= 2   // 0=Verbose,1=Info,2=Warning,3=Error,4=Critical
```

### 5 — Cost optimization dashboard tiles

Add these tiles to the Azure Monitor Workbook or dashboard:

```kql
// ── Daily spend trend (last 30 days) ──────────────────────────────────────
Usage
| where IsBillable == true and TimeGenerated > ago(30d)
| summarize DailyGB = sum(Quantity)/1024 by bin(TimeGenerated,1d)
| extend DailyCostUSD = DailyGB * 2.76
| render timechart

// ── Quick-action: tables exceeding 1 GB/day ───────────────────────────────
Usage
| where IsBillable == true and TimeGenerated > ago(1d)
| summarize DailyGB = sum(Quantity)/1024 by DataType
| where DailyGB > 1
| extend Action = "Review sampling or retention for this table"
| project DataType, DailyGB, Action
| render table

// ── Month-to-date cost estimate ───────────────────────────────────────────
Usage
| where IsBillable == true
| where TimeGenerated >= startofmonth(now())
| summarize MTD_GB = sum(Quantity)/1024
| extend MTD_CostUSD = MTD_GB * 2.76
| project MTD_GB, MTD_CostUSD
```

### 6 — Quick actions checklist

After reviewing the output of step 5, take these actions if thresholds are breached:

- [ ] **Table over 1 GB/day**: reduce hot retention to ≤ 30 days or add DCR filter.
- [ ] **`traces` table > 500 MB/day**: enable sampling (Application Insights adaptive
      sampling is on by default; verify it is not disabled in `server.js`).
- [ ] **`performanceCounters` volume high**: reduce collection frequency in AMA DCR
      from 60s to 300s.
- [ ] **No tenant tag on records**: add `resource` processor to OTel Collector config
      or `transformKql` in DCR (see `otel-ingestion` skill).
