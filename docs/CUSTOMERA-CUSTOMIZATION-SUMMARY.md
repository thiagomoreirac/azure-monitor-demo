# CustomerA Insurance Claims Platform - Customization Summary

## Overview

The Azure Monitor demo has been successfully customized for **CustomerA**, an insurance company focused on claims processing and fraud detection. This document summarizes all changes made, deployment instructions, and demo scenarios.

---

## Customer Profile

| Field | Value |
|-------|-------|
| **Customer Name** | CustomerA |
| **Business Domain** | Insurance / Claims Processing |
| **Tenants** | 1 (Single Tenant) |
| **Azure Region** | France Central |
| **Deployment Environment** | Production-ready |
| **Subscription ID** | `ea8e0b7d-7a3a-47fe-b921-beaec58ec6aa` |

---

## Files Changed

### 1. Infrastructure Configuration

#### `infra/main.parameters.json`
- ✅ Updated `environmentName`: `demo-monitor` → `customera-monitor`
- ✅ Updated `location`: `North Europe` → `France Central`
- ✅ Updated `administratorLogin`: `demoAdmin` → `customeraAdmin`
- ✅ Updated `administratorPassword`: New secure credential
- **Why:** Reflects customer branding and deployment region

#### `infra/main.json`
- ✅ Updated metadata description to reference insurance/claims
- ✅ Enhanced tags with customer, domain, environment, and region information
- **Example tags:**
  ```json
  "tags": {
    "azd-env-name": "customera-monitor",
    "purpose": "azure-monitor-demo",
    "customer": "customerA",
    "domain": "insurance-claims",
    "environment": "demo",
    "region": "France Central"
  }
  ```

### 2. Application Telemetry

#### `src/webapp-simple/server.js`
Comprehensive customization for insurance domain:

**Data Model Changes:**
- ✅ Replaced generic "products" with insurance "claims" data model
- ✅ Each claim includes: policyNumber, claimType, amount, status, submittedDate

**New Insurance-Specific Endpoints:**

1. **POST `/api/submit-claim`**
   - Simulates claim submission workflow
   - Generates custom event: `Claim_Submitted`
   - Tracks custom metric: `Claim_Submission_Amount`
   - Tracks metric: `Claim_Processing_Duration`

2. **GET `/fraud-check?claimId=<id>`**
   - Simulates fraud detection model
   - Generates event: `Fraud_Check_Started` → `Fraud_Flag_Raised` (if fraud detected)
   - Tracks metrics: `Fraud_Detection_Latency`, `Fraud_Risk_Score`
   - Returns recommendation: "Auto Approve" or "Manual Review Required"

**Enhanced Telemetry Context:**
- ✅ All telemetry events include `tenant: "customerA"` in properties
- ✅ All telemetry includes `domain: "insurance-claims"` where applicable
- ✅ Error types updated to insurance domain: `policy_lookup_failed`, `fraud_api_timeout`, `database_connection`, `payment_processing`, `document_storage`

**Updated Endpoints:**
- `/api/claims` - List all claims with processing metrics
- `/health` - System health with tenant context
- `/load` - CPU load testing for performance validation
- `/memory` - Memory utilization tracking
- `/error` - Insurance-specific error simulation

**Home Page:**
- ✅ Title: "CustomerA Insurance Claims Platform"
- ✅ Subtitle: "Observability & Monitoring for Claims Processing & Fraud Detection"
- ✅ Updated features list to reflect insurance domain

### 3. Dashboards & KQL Queries

#### `docs/CUSTOMERA-KQL-QUERIES.md` (NEW FILE)
Created comprehensive KQL query repository with 10 core queries + scenario queries:

**Core Queries:**
1. **Claims Processing Latency** - P95 and P99 latency over time
2. **Fraud Flags Raised** - Real-time fraud alert frequency
3. **Fraud Rate** - Submitted claims vs fraudulent ratio
4. **Claims API Performance** - Response time and error rate
5. **Error Analysis by Type** - Break down failure causes
6. **Fraud Detection Model Latency** - Model performance distribution
7. **Claim Amount Analysis** - Track high-value claims
8. **System Health** - Memory and resource usage
9. **High-Value Claims Alert** - Claims >$10K with fraud flags
10. **Dependency Performance** - External service latencies

**Demo Scenarios:**
- High Fraud Detection During Peak Hours
- Claims Processing SLA Compliance
- Fraud Model Accuracy & Precision

**Dashboard Tiles Configuration:**
- 5 configured tiles for the primary dashboard
- Alert thresholds included (e.g., error rate > 5%, fraud flags > 20/5min)

### 4. Deployment Scripts

#### `scripts/deploy.ps1`
- ✅ Updated default location parameter from `North Europe` to `France Central`
- Maintains compatibility with existing deployment automation

---

## Deployment Instructions

### Prerequisites
- Azure CLI (`az`) installed and configured
- PowerShell 7+ installed
- Git configured with credentials
- Access to subscription: `ea8e0b7d-7a3a-47fe-b921-beaec58ec6aa`

### Step 1: Authenticate to Azure

```bash
az login
az account set --subscription ea8e0b7d-7a3a-47fe-b921-beaec58ec6aa
```

### Step 2: Deploy Infrastructure

```powershell
cd /workspaces/azure-monitor-demo

# Deploy all resources to France Central region
pwsh -File scripts/deploy.ps1 `
    -ResourceGroupName "customera-monitor-rg" `
    -Location "France Central" `
    -SubscriptionId "ea8e0b7d-7a3a-47fe-b921-beaec58ec6aa"
```

**Expected Output:**
```
✅ Infrastructure deployment completed successfully!

📊 Deployment Information:
Web App URL: https://app-<unique-token>.azurewebsites.net
Application Insights: appi-<unique-token>
Log Analytics Workspace: log-<unique-token>
```

### Step 3: Build and Deploy Web Application

```bash
cd src/webapp-simple

# Install dependencies
npm install

# Configure Application Insights connection string
# (The deployment script should have already set this in App Service config)
```

### Step 4: Generate Demo Traffic

```powershell
# Run the demo traffic generator
pwsh -File scripts/demo-final.ps1
```

---

## Demo Walkthrough (15 Minutes)

### 1. Architecture Overview (2 min)
- Show resource group in Azure Portal
- Point out: Web App, Application Insights, Log Analytics Workspace, SQL Database
- Highlight resource tags: `customer: customerA`, `domain: insurance-claims`

### 2. Live Metrics (3 min)
- Open Application Insights → Live Metrics
- Trigger `/api/submit-claim` endpoint to generate claim submissions
- Show real-time request throughput, response times
- Point out custom events: `Claim_Submitted`, `Fraud_Check_Started`

### 3. Claims & Fraud Events (3 min)
- Navigate to Logs blade
- Run Query #2: **Fraud Flags Raised - Real-time Alerts**
  ```kql
  customEvents
  | where name == "Fraud_Flag_Raised"
  | where properties.tenant == "customerA"
  ```
- Run Query #1: **Claims Processing Latency**
  ```kql
  customMetrics
  | where name == "Claim_Processing_Duration"
  ```
- Explain SLA: P95 should be < 2000ms

### 4. Performance & Alerts (2 min)
- Show alert rules configured in the template
- Explain thresholds:
  - Error rate > 5% triggers alert
  - Response time > 2000ms triggers alert
  - CPU usage > 80% triggers alert

### 5. Application Map (3 min)
- Show dependency tracking between:
  - Web app → Claims database
  - Web app → Fraud detection API (simulated)
  - Web app → Policy lookup service (simulated)
- Highlight latency by service
- Point out failure rates (if any)

### 6. Q&A (2 min)
- How does the fraud detection work? (Machine learning model simulation)
- How are claims tracked end-to-end? (Telemetry with claimId)
- What about multi-tenant support? (Structure is ready; can onboard new tenants)

---

## Key KQL Queries for Demo

### Query 1: Claims Processing SLA Compliance
```kql
customMetrics
| where name == "Claim_Processing_Duration"
| where properties.tenant == "customerA"
| extend SLAMet = iif(value <= 2000, "✅ Within SLA", "❌ Exceeded SLA")
| summarize 
    SLACompliance = (todouble(countif(value <= 2000)) / count()) * 100,
    AvgTime = avg(value),
    Percentile95 = percentile(value, 95)
```
**Result:** Shows % of claims processed within 2000ms SLA

### Query 2: Top Fraud Risk Claims
```kql
customEvents
| where name == "Fraud_Flag_Raised"
| where properties.tenant == "customerA"
| summarize 
    FraudCount = count(),
    AvgRiskScore = avg(todouble(properties.riskScore))
    by tostring(properties.claimId)
| order by FraudCount desc
| limit 10
```
**Result:** Shows top 10 claims with most fraud flags

### Query 3: Claims Volume Trend
```kql
customEvents
| where name == "Claim_Submitted"
| where properties.tenant == "customerA"
| summarize ClaimCount = count() by bin(timestamp, 1h)
| render timechart
```
**Result:** Claims submission volume over time

### Query 4: Error Rate by Type
```kql
customEvents
| where name == "Claim_Processing_Error_Count"
| where properties.tenant == "customerA"
| summarize ErrorCount = count() by tostring(properties.errorType)
| order by ErrorCount desc
```
**Result:** Breakdown of failure modes

### Query 5: Fraud Detection Model Performance
```kql
customMetrics
| where name == "Fraud_Detection_Latency"
| where properties.tenant == "customerA"
| summarize 
    AvgLatency = avg(value),
    P95Latency = percentile(value, 95),
    P99Latency = percentile(value, 99),
    MaxLatency = max(value)
```
**Result:** Model response time distribution (target < 500ms)

---

## Testing Endpoints

### 1. Submit a Claim
```bash
curl -X POST http://localhost:3000/api/submit-claim \
  -H "Content-Type: application/json"
```
**Response:** New claim with ID and processing time

### 2. List All Claims
```bash
curl http://localhost:3000/api/claims
```
**Response:** Array of all claims with statuses

### 3. Run Fraud Detection Check
```bash
curl "http://localhost:3000/fraud-check?claimId=1"
```
**Response:** Fraud risk score and recommendation

### 4. Generate Load Test
```bash
curl "http://localhost:3000/load?iterations=5000"
```
**Response:** Load test metrics and results

### 5. Check System Health
```bash
curl http://localhost:3000/health
```
**Response:** System uptime, memory, version info

### 6. Simulate Error
```bash
curl http://localhost:3000/error
```
**Response:** 500 error with domain-specific error code

---

## Monitoring & Alerting Configuration

### Alert 1: High Response Time
- **Metric:** Average response time (Claims API)
- **Threshold:** > 2000 ms (for P95)
- **Window:** 5 minutes
- **Action:** Send notification

### Alert 2: High Error Rate
- **Metric:** Failed request percentage
- **Threshold:** > 5%
- **Window:** 5 minutes
- **Action:** Send notification

### Alert 3: High CPU Usage
- **Metric:** CPU percentage
- **Threshold:** > 80%
- **Window:** 5 minutes
- **Action:** Send notification

### Alert 4: Fraud Spike (Optional)
- **Metric:** Fraud flag count
- **Threshold:** > 20 flags per 5 minutes
- **Window:** 5 minutes
- **Action:** Send high-priority notification

---

## Cost Optimization Notes

- **Log Retention:** Set to 30 days (manageable for demo)
- **Application Insights SKU:** Pay-As-You-Go
- **Log Analytics SKU:** Per GB (PerGB2018)
- **Estimated Monthly Cost:** ~$50-150 depending on data volume

For production use, consider:
- Longer retention for compliance
- Sampling for high-volume events
- Reserved capacity for predictable workloads

---

## Next Steps

### For CustomerA:
1. ✅ Customize demo to their domain (COMPLETED)
2. Set up alert recipients (email/SMS/webhooks)
3. Configure RBAC for team access
4. Set up continuous monitoring dashboard
5. Create runbooks for common incident scenarios
6. Plan multi-tenant onboarding (if needed)

### For Additional Tenants:
- Use `/add-tenant` prompt to onboard new insurance companies
- Leverage role-based access control (RBAC) for isolation
- Create per-tenant dashboards using KQL filters

---

## Support & Documentation

- **ARM Template Reference:** `infra/main.json`
- **KQL Queries:** `docs/CUSTOMERA-KQL-QUERIES.md`
- **Application Code:** `src/webapp-simple/server.js`
- **Deployment Script:** `scripts/deploy.ps1`

For detailed troubleshooting, refer to the Azure Monitor documentation and the ARM template outputs.

---

**Generated:** April 27, 2026  
**Environment:** Production-Ready Demo  
**Status:** ✅ Fully Customized and Validated
