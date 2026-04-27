---
description: >-
  Adapt the entire Azure Monitor demo repository for a new customer. Covers
  resource renaming, customer-specific telemetry, alert thresholds, OTel
  ingestion, dashboards, multi-tenant setup, and deployment.
---

You are the `azure-monitor-architect` agent. Read `.github/copilot-instructions.md`
and the customer PDF documents in `docs/` before proceeding.

## Inputs needed

Before starting, confirm the following with the user (use defaults if already
set in `infra/main.parameters.json`):

1. **Customer name / slug** (e.g., `shift-technology`)
2. **Azure region** (e.g., `northeurope`)
3. **Number of tenants** and their slugs
4. **Subscription ID(s)**
5. **Key business domains** (claims, fraud, policy — already known for Shift Technology)
6. **SLA thresholds** (response time, error rate, CPU)

## Customization checklist

### 1 · Infrastructure (infra/main.parameters.json + infra/main.json)
- [ ] Set `environmentName` to `<customer-slug>-monitor`
- [ ] Set `location` to target region
- [ ] Add `tenantSlug` and `costCenter` parameters
- [ ] Update resource tags to include `tenant`, `environment`, `region`, `cost-center`
- [ ] Tighten alert thresholds to customer SLAs

### 2 · Application telemetry (src/webapp-simple/server.js)
- [ ] Update the HTML page title and description to reference the customer
- [ ] Add customer-specific custom events (e.g., `ClaimSubmitted`, `FraudFlagRaised`)
- [ ] Add customer-specific custom metrics (e.g., `ClaimProcessingTime`)
- [ ] Add simulated error scenarios relevant to the customer domain
- [ ] Ensure every telemetry call includes `tenant` in `properties`

### 3 · Dashboards and KQL (use dashboard-customization skill)
- [ ] Generate KQL queries for all key business metrics
- [ ] Add drill-down queries (summary → service → instance)
- [ ] Add a `Microsoft.Portal/dashboards` ARM resource with the generated tiles

### 4 · OTel ingestion (use otel-ingestion skill)
- [ ] Add OTel SDK bootstrap to `server.js` (or confirm App Insights SDK is sufficient)
- [ ] Create `src/otel-collector/otel-collector-config.yaml` with tenant labeling
- [ ] Add DCR resource to `infra/main.json` for non-OTel sources

### 5 · Multi-tenant / RBAC (use multi-tenant-kql skill)
- [ ] Add `tenantSlug` + `costCenter` ARM parameters
- [ ] Add role assignment ARM resource per tenant
- [ ] Document tenant onboarding steps in `docs/DEMO-GUIDE.md`

### 6 · Cost optimization (use log-analytics-cost skill)
- [ ] Set table-level retention per the retention policy
- [ ] Add DCR `transformKql` to filter noise
- [ ] Add cost dashboard tiles

### 7 · Deployment
- [ ] Validate ARM template: `az deployment group validate ...`
- [ ] Deploy: `pwsh -File scripts/deploy.ps1 -ResourceGroupName "<customer>-rg" -Location "<region>"`
- [ ] Run traffic generator to confirm telemetry: `pwsh -File scripts/demo-final.ps1`

## Output

After completing all steps, provide:
1. A summary of every file changed and why.
2. The exact deployment command.
3. 3–5 KQL queries to run during the demo, with plain-English explanations.
