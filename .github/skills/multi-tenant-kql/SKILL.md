---
name: multi-tenant-kql
description: >-
  Generate KQL patterns and ARM configurations for cross-tenant, multi-region,
  multi-subscription, and RBAC-controlled observability. Use when onboarding a
  new tenant, setting up cross-subscription queries, configuring per-tenant
  RBAC roles, or enforcing ingestion quotas.
---

## Purpose

Enable the customer to observe **multiple insurance company tenants**
in a single Azure Monitor workspace while enforcing isolation through RBAC,
resource tags, and per-tenant data views.

## Concepts

| Concept | Implementation |
|---|---|
| Tenant isolation | Resource tags (`tenant=<id>`) + RBAC on resource groups |
| Cross-subscription query | Azure Resource Graph / `workspace()` KQL function |
| Multi-region | Separate workspaces per region linked to a central workspace |
| Per-tenant quotas | Log Analytics Daily Cap per workspace or DCR filtering |
| RBAC | Custom role scoped to specific resource group per tenant |

## Procedure

### 1 — Tag convention

Every resource and every log record must carry these four tags:

```
tenant      = <tenant-slug>   e.g., "eu-insurer-a"
environment = <prod|staging|dev>
region      = <northeurope|westeurope|eastus>
cost-center = <budget-code>
```

In `infra/main.json`, add them to `variables.tags`:
```json
"tags": {
  "azd-env-name": "[parameters('environmentName')]",
  "purpose": "azure-monitor-demo",
  "tenant":      "[parameters('tenantSlug')]",
  "environment": "[parameters('environmentName')]",
  "region":      "[parameters('location')]",
  "cost-center": "[parameters('costCenter')]"
}
```

Add the corresponding parameters to `infra/main.parameters.json`:
```json
"tenantSlug":  { "value": "eu-insurer-a" },
"costCenter":  { "value": "CC-CUST-OBS-001" }
```

### 2 — Per-tenant RBAC role (ARM)

Add a role assignment that limits a tenant team to Reader access on their
own resource group only:

```json
{
  "type": "Microsoft.Authorization/roleAssignments",
  "apiVersion": "2022-04-01",
  "name": "[guid(resourceGroup().id, parameters('tenantPrincipalId'), 'Reader')]",
  "properties": {
    "roleDefinitionId": "[subscriptionResourceId('Microsoft.Authorization/roleDefinitions','acdd72a7-3385-48ef-bd42-f606fba81ae7')]",
    "principalId": "[parameters('tenantPrincipalId')]",
    "principalType": "Group"
  }
}
```

### 3 — Cross-subscription KQL patterns

```kql
// ── Query a remote workspace by resource ID ────────────────────────────────
// Useful for aggregating data from multiple tenant workspaces
workspace("/subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.OperationalInsights/workspaces/<WS_NAME>")
| union (workspace("/subscriptions/<SUB_ID_2>/.../<WS_NAME_2>"))
| where TimeGenerated > ago(1h)
| where customDimensions["tenant"] in ("eu-insurer-a", "eu-insurer-b")
| summarize ClaimCount = count() by tenant = tostring(customDimensions["tenant"]),
    bin(TimeGenerated, 5m)
| render timechart
```

```kql
// ── Azure Resource Graph: list all Monitor workspaces by tenant tag ────────
resources
| where type =~ "microsoft.operationalinsights/workspaces"
| where tags["tenant"] != ""
| project name, tenant=tags["tenant"], region=location, rg=resourceGroup,
          subscription=subscriptionId
| order by tenant asc
```

### 4 — Per-tenant query isolation (row-level security proxy)

When a single shared workspace is used, add a `tenant` filter to every query
executed on behalf of a specific user / group. Build this into workbook parameters:

```kql
// Parameterised workbook query — {tenant} is a workbook parameter
customEvents
| where customDimensions["tenant"] == "{tenant}"
| where name in ("ClaimSubmitted", "FraudFlagRaised", "PolicyQueried")
| summarize count() by name, bin(timestamp, 5m)
| render barchart
```

### 5 — Per-tenant ingestion quota (PowerShell)

Set a daily cap (GB) on a workspace to prevent one tenant from over-spending:

```powershell
az monitor log-analytics workspace update `
  --resource-group $ResourceGroupName `
  --workspace-name $WorkspaceName `
  --quota 5   # GB per day; adjust per tenant SLA
```

Monitor quota breaches:
```kql
// Alert when daily ingestion is within 90 % of cap
Usage
| where TimeGenerated > ago(1d) and IsBillable == true
| summarize DailyGB = sum(Quantity) / 1024
| extend CapGB = 5.0,  WarningThreshold = 0.9
| where DailyGB >= CapGB * WarningThreshold
| project DailyGB, CapGB, PctUsed = DailyGB / CapGB * 100
```

### 6 — Multi-region aggregation dashboard

```kql
// ── Claim throughput per region (using resource tag) ─────────────────────
customEvents
| where name == "ClaimSubmitted"
| extend region = tostring(customDimensions["region"])
| summarize Claims = count() by region, bin(timestamp, 1h)
| render timechart

// ── Fraud detection latency per region ────────────────────────────────────
customMetrics
| where name == "FraudDetectionLatency"
| extend region = tostring(customDimensions["region"])
| summarize p95_ms = percentile(value, 95) by region, bin(timestamp, 1h)
| render timechart
```

### 7 — Onboarding checklist for a new tenant

- [ ] Create resource group `customer-<tenant-slug>-rg`.
- [ ] Deploy ARM template with `tenantSlug`, `costCenter`, `location` parameters.
- [ ] Assign `Reader` role to tenant's Azure AD group on their resource group.
- [ ] Add tenant slug to OTel Collector `resource` processor environment variable.
- [ ] Add tenant to workbook parameter drop-down list.
- [ ] Verify `tenant` tag appears on records via the KQL in step 3.
- [ ] Set daily ingestion cap via step 5.
