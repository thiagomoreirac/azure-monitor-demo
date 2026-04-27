# Azure Monitor Demo Guide (Microsoft Copilot in Azure)

This version focuses on a live demo where Microsoft Copilot in Azure is used for advanced dashboards, KQL, and RCA.

## 1) Fix deployment so app page is not the default App Service page

Use:
```powershell
scripts/deploy.ps1 -ResourceGroupName "customera-monitor-demo" -Location "France Central" -SubscriptionId "<subscription-id>"
```

The deployment script now:
- enables App Service publishing policies needed for zip deploy,
- configures Node runtime (`WEBSITE_NODE_DEFAULT_VERSION=~20`),
- deploys `src/webapp-simple` package.

Validate app:
```bash
curl -I https://<app-name>.azurewebsites.net/
curl https://<app-name>.azurewebsites.net/health
```

## 2) Generate real-time OTel-like and non-OTel telemetry

Run traffic generator:
```powershell
pwsh -File scripts/generate-observability-traffic.ps1 -BaseUrl "https://<app-name>.azurewebsites.net" -DurationSeconds 600
```

What it generates:
- OTel-like distributed traces/requests via `traceparent` headers and business endpoints
- Non-OTel external payloads via `POST /api/external-ingest`
- Metrics, traces, events, dependencies, and occasional failures for RCA

## 3) Coverage of required use cases

1. External service ingestion (OTel + non-OTel)
- OTel collector config: `src/otel-collector/otel-collector-config.yaml`
- Non-OTel endpoint: `src/webapp-simple/server.js` (`/api/external-ingest`)

2. Advanced dashboards and KQL with Microsoft Copilot in Azure
- Use Microsoft Copilot in Azure (Portal) prompt examples below.

3. Dashboard templates for external services
- Template: `infra/external-services-dashboard.template.json`

4. Drill-down across infra/app/external services (metrics, logs, traces)
- Use `operation_Id` drill-down query and dependency/error tiles from the template.

5. Cross-tenant, multi-region, multi-subscription, RBAC, quotas per tenant
- Patterns and onboarding workflow:
   - `.github/skills/multi-tenant-kql/SKILL.md`
   - `.github/prompts/add-tenant.prompt.md`

6. Retention and cost controls by tenant label
- Strategy and queries:
   - `.github/skills/log-analytics-cost/SKILL.md`
   - `.github/prompts/cost-optimization.prompt.md`

7. Cost optimization visualizations + quick actions
- Use cost trend, top tables, and quick-action tables from log-analytics-cost skill.

8. Investigation and RCA with Microsoft Copilot in Azure
- RCA workflow prompts and drill-down sequence:
   - `.github/prompts/rca-investigation.prompt.md`

## 4) Microsoft Copilot in Azure prompt pack

Use these in Microsoft Copilot in Azure:

1. Advanced dashboard creation
```text
Create an advanced Azure Monitor dashboard for the last 30 minutes for this Application Insights resource. Include tiles for external dependency p95 latency, failed dependency rate, exceptions by type, and tenant-level throughput. Add drill-down by operation_Id.
```

2. KQL for external-service observability
```text
Generate KQL queries to correlate requests, dependencies, traces, and exceptions for fraud-api and policy-service. Include tenant and region filters and a 5-minute time bin.
```

3. RCA workflow
```text
Run an RCA for elevated failures in the last 20 minutes. Identify blast radius by tenant, top failing endpoints, degraded dependencies, probable root cause, and recommended mitigations.
```

4. Cost optimization with actions
```text
Analyze Log Analytics ingestion cost by tenant and table for the last 30 days. Provide quick actions with expected savings: retention changes, DCR filtering, sampling, and quota recommendations.
```

## 5) Suggested 20-minute live demo flow

1. Show app and live telemetry generation (4 min)
2. Show external-service dashboard template and drill-down (4 min)
3. Ask Microsoft Copilot in Azure for advanced KQL and dashboard enhancements (4 min)
4. Ask Microsoft Copilot in Azure for RCA summary on injected failures (4 min)
5. Ask Microsoft Copilot in Azure for cost optimization actions by tenant label (4 min)
