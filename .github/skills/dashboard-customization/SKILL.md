---
name: dashboard-customization
description: >-
  Customize Azure Monitor / Application Insights dashboards and generate KQL
  queries for a specific customer context. Use when dashboards, workbooks, or
  KQL queries need to be created, adapted, or updated — including drill-down
  across infrastructure, applications, and external services.
---

## Purpose

Generate or update Azure Monitor dashboard tiles and Log Analytics KQL queries
tailored to Shift Technology's observability requirements: insurance claims,
fraud detection, policy management, and external-service dependencies.

## Procedure

### 1 — Discover existing dashboard assets

- Look for dashboard JSON files under `infra/` (ARM `Microsoft.Portal/dashboards`
  resources) and KQL snippets in `docs/`.
- Identify which metrics and custom events are already emitted in
  `src/webapp-simple/server.js`.

### 2 — Determine scope

Ask (or infer from context) which of the following tiles are needed:

| Tile type | Data source |
|---|---|
| Claims throughput | `customEvents \| where name == "ClaimSubmitted"` |
| Fraud flag rate | `customEvents \| where name == "FraudFlagRaised"` |
| Detection model latency | `customMetrics \| where name == "ModelInferenceTime"` |
| Error breakdown by endpoint | `requests \| where success == false` |
| Infra health (CPU / memory) | `performanceCounters` |
| External service latency | `dependencies \| where target == "fraud-api"` |
| Cost by tenant | `Usage \| where IsBillable == true \| summarize by Tags["tenant"]` |

### 3 — Generate KQL queries

Follow this template for every query:

```kql
// <Plain-English description of what this query shows>
// Scope: <claims | fraud | policy | infra | cost>
<table>
| where <filter>
| summarize <aggregation> by <dimension>, bin(timestamp, <window>)
| order by <field> desc
| render <timechart|barchart|table>
```

Always:
- Use `bin(timestamp, 5m)` for real-time tiles, `bin(timestamp, 1h)` for trend tiles.
- Add `| where isnotempty(customDimensions["tenant"])` for multi-tenant scoping.
- Include `| extend p95 = percentile(value, 95)` for latency metrics.

### 4 — Drill-down pattern

Every dashboard should have three linked levels:

1. **Summary tile** — aggregated by environment / region.
2. **Service tile** — filtered by service name / dependency target.
3. **Instance tile** — filtered by `cloud_RoleInstance` or `operation_Id`.

Use `| extend drilldown = strcat("/subscriptions/", _SubscriptionId, "...")` to
generate portal deep-links in workbook markdown tiles.

### 5 — Add to ARM template (if persisting the dashboard)

Add a `Microsoft.Portal/dashboards` resource to `infra/main.json` with the
generated tile JSON. Use `[variables('applicationInsightsName')]` as the data
source reference so the name resolves at deploy time.

### 6 — Validate

- Run `az deployment group validate --template-file infra/main.json ...` to
  ensure the ARM template is still valid after any changes.
- Paste each KQL query into the Log Analytics query editor and verify it returns
  data before including it in a dashboard.

## Reference KQL library (Shift Technology)

```kql
// ── Claims processing latency (p50 / p95 over time) ──────────────────────
customMetrics
| where name == "ClaimProcessingTime"
| summarize p50=percentile(value,50), p95=percentile(value,95) by bin(timestamp,5m)
| render timechart

// ── Fraud flag rate per 5-minute window ───────────────────────────────────
customEvents
| where name == "FraudFlagRaised"
| summarize FraudFlags=count() by bin(timestamp,5m)
| render barchart

// ── Detection model call volume and latency ───────────────────────────────
customMetrics
| where name == "ModelInferenceTime"
| summarize calls=count(), avg_ms=avg(value), p95_ms=percentile(value,95)
    by bin(timestamp,5m)
| render timechart

// ── External fraud-API dependency health ──────────────────────────────────
dependencies
| where target has "fraud-api" or name has "DetectionModel"
| summarize total=count(), failed=countif(success==false),
    avg_duration_ms=avg(duration) by bin(timestamp,5m)
| extend errorRate = todouble(failed)/todouble(total)*100
| render timechart

// ── Error breakdown by endpoint ───────────────────────────────────────────
requests
| where success == false
| summarize count() by name, resultCode
| order by count_ desc
| render table

// ── Drill-down: single claim trace ────────────────────────────────────────
// Replace <CLAIM_ID> with the actual claim identifier from customDimensions
union requests, dependencies, traces, exceptions
| where customDimensions["claimId"] == "<CLAIM_ID>"
| order by timestamp asc
| project timestamp, itemType, name, duration, success, message
```
