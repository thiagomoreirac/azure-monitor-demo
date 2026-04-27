---
description: >-
  Onboard a new tenant into the existing the customer observability
  platform. Creates resource group, updates ARM parameters, assigns RBAC,
  sets ingestion quota, and verifies data isolation.
---

You are the `azure-monitor-architect` agent. Use the `multi-tenant-kql` skill.

## Required inputs

Ask the user for:

1. **Tenant slug** (e.g., `eu-insurer-b`) — used in resource names and tags
2. **Cost center code** (e.g., `CC-CUST-OBS-002`)
3. **Azure region** for this tenant's resources
4. **Azure AD group Object ID** — for RBAC role assignment
5. **Daily ingestion quota (GB)** — default 5 GB if not specified
6. **Subscription ID** — can be the same as the main subscription

## Steps

### 1 — Create tenant resource group
```powershell
az group create `
  --name "customer-<tenant-slug>-rg" `
  --location "<region>" `
  --tags tenant="<tenant-slug>" environment="prod" cost-center="<cost-center>"
```

### 2 — Deploy ARM template for the tenant
```powershell
pwsh -File scripts/deploy.ps1 `
  -ResourceGroupName "customer-<tenant-slug>-rg" `
  -Location "<region>"
# Also pass: -TenantSlug "<tenant-slug>" -CostCenter "<cost-center>"
```

### 3 — Assign RBAC Reader role to the tenant's AD group
Add a `Microsoft.Authorization/roleAssignments` resource to `infra/main.json`
(see `.github/skills/multi-tenant-kql/SKILL.md`, step 2) or run ad-hoc:
```powershell
az role assignment create `
  --assignee-object-id "<AAD_GROUP_OBJECT_ID>" `
  --assignee-principal-type Group `
  --role "Reader" `
  --scope "/subscriptions/<SUB>/resourceGroups/customer-<tenant-slug>-rg"
```

### 4 — Set daily ingestion cap
```powershell
az monitor log-analytics workspace update `
  --resource-group "customer-<tenant-slug>-rg" `
  --workspace-name "<workspace-name>" `
  --quota <daily-gb-cap>
```

### 5 — Add tenant to OTel Collector
In `src/otel-collector/otel-collector-config.yaml`, ensure the `resource`
processor sets `tenant = "<tenant-slug>"` for this collector instance
(deploy a separate collector pod or update the environment variable).

### 6 — Verify data isolation
Run these KQL queries after the first traffic generation:

```kql
// Confirm tenant tag appears on records
customEvents
| where customDimensions["tenant"] == "<tenant-slug>"
| take 10

// Confirm no cross-tenant data leakage
customEvents
| where customDimensions["tenant"] != "<tenant-slug>"
| summarize count() by tenant = tostring(customDimensions["tenant"])
// ↑ Should return 0 rows if isolation is correct
```

### 7 — Update workbook parameter drop-down
Add the new tenant slug to the `tenant` parameter list in the Azure Monitor
Workbook (or the ARM `Microsoft.Portal/dashboards` tile definition).

### 8 — Document the new tenant
Append a row to the tenant table in `docs/DEMO-GUIDE.md`:

| Tenant slug | Region | Cost center | Resource group | Quota |
|---|---|---|---|---|
| `<tenant-slug>` | `<region>` | `<cost-center>` | `customer-<tenant-slug>-rg` | `<quota> GB/day` |
