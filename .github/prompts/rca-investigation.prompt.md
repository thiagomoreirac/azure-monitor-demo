---
description: >-
  Perform a guided Root Cause Analysis (RCA) for an incident in the Shift
  Technology observability platform. Works through a structured drill-down
  from alert → service → operation → dependency → code.
---

You are the `azure-monitor-architect` agent. Use the `dashboard-customization`
skill to generate drill-down queries.

## Required inputs

Ask the user for:

1. **Incident description** — what symptom was observed (high latency, error spike,
   fraud model timeout, …)
2. **Time window** — start and end time (ISO 8601 or relative, e.g., `ago(2h)`)
3. **Affected tenant** (if known) — e.g., `eu-insurer-a`
4. **Affected service or endpoint** (if known) — e.g., `/api/claims`, `FraudDetectionModel`

## RCA workflow

### Step 1 — Reproduce the signal
```kql
// Confirm the anomaly in the time window
requests
| where timestamp between(datetime(<START>) .. datetime(<END>))
| where customDimensions["tenant"] == "<TENANT>"
| summarize total=count(), failed=countif(success==false),
    p95_ms=percentile(duration,95) by name, bin(timestamp, 1m)
| where failed > 0 or p95_ms > 1500
| order by timestamp asc
| render timechart
```

### Step 2 — Identify the blast radius
```kql
// How many tenants / services were affected?
requests
| where timestamp between(datetime(<START>) .. datetime(<END>))
| where success == false
| summarize FailedRequests = count() by
    tenant = tostring(customDimensions["tenant"]),
    name,
    resultCode
| order by FailedRequests desc
```

### Step 3 — Trace a failing operation end-to-end
```kql
// Pick the operation_Id of a failing request, then trace all telemetry for it
// Replace <OPERATION_ID> with the id from Step 2
union requests, dependencies, traces, exceptions, customEvents
| where operation_Id == "<OPERATION_ID>"
| order by timestamp asc
| project timestamp, itemType, name, duration, success,
    message, type, outerMessage, target
```

### Step 4 — Check downstream dependencies
```kql
// Were external calls (fraud API, SQL, policy service) degraded?
dependencies
| where timestamp between(datetime(<START>) .. datetime(<END>))
| where customDimensions["tenant"] == "<TENANT>"
| summarize total=count(), failed=countif(success==false),
    avg_ms=avg(duration), p95_ms=percentile(duration,95)
    by target, name
| where failed > 0 or p95_ms > 500
| order by failed desc
```

### Step 5 — Inspect exceptions
```kql
// What exceptions were thrown?
exceptions
| where timestamp between(datetime(<START>) .. datetime(<END>))
| where customDimensions["tenant"] == "<TENANT>"
| summarize count() by type, outerMessage, method
| order by count_ desc
```

### Step 6 — Check infrastructure health
```kql
// Was there a CPU / memory spike at the same time?
performanceCounters
| where timestamp between(datetime(<START>) .. datetime(<END>))
| where counter in ("% Processor Time", "Available MBytes")
| summarize avg_value=avg(value) by counter, cloud_RoleInstance,
    bin(timestamp, 1m)
| render timechart
```

### Step 7 — Correlate with deployment / change events
```kql
// Were there any deployments or config changes?
customEvents
| where timestamp between(datetime(<START>) .. datetime(<END>))
| where name in ("Application_Started", "ConfigChanged", "DeploymentCompleted")
| project timestamp, name, customDimensions
| order by timestamp asc
```

## RCA summary template

After completing the investigation, fill in this template and save it as a
comment on the incident issue:

```
## RCA Summary

**Incident**: <description>
**Time window**: <start> → <end>
**Affected tenants**: <list>
**Root cause**: <e.g., "FraudDetectionModel dependency returned 503 due to upstream quota breach">
**Blast radius**: <N requests failed, M tenants affected>
**Timeline**:
- <time>: <event>
- <time>: <event>

**Remediation**:
- Short-term: <e.g., "increased upstream API quota">
- Long-term: <e.g., "add circuit-breaker pattern to fraud-api client">

**Prevention**:
- Alert added: <name and threshold>
- Runbook updated: <link>
```
