# CustomerA Insurance Claims Platform - KQL Queries

This document contains KQL queries for monitoring claims processing, fraud detection, and platform health for the CustomerA observability platform.

## 1. Claims Processing Latency Over Time

```kql
customMetrics
| where name == "Claim_Processing_Duration"
| where properties.tenant == "customerA"
| summarize 
    AvgLatency = avg(value),
    P95Latency = percentile(value, 95),
    P99Latency = percentile(value, 99),
    MaxLatency = max(value),
    Count = count()
    by bin(timestamp, 5m)
| render timechart
```

**Explanation:** Tracks average, 95th percentile, and 99th percentile claim processing time. Use this to monitor whether claims are being processed within SLA thresholds.

---

## 2. Fraud Flags Raised - Real-time Alerts

```kql
customEvents
| where name == "Fraud_Flag_Raised"
| where properties.tenant == "customerA"
| extend RiskScore = todouble(properties.riskScore)
| summarize 
    FraudCount = count(),
    AvgRiskScore = avg(RiskScore)
    by bin(timestamp, 5m), tostring(properties.claimId)
| order by timestamp desc
| render barchart
```

**Explanation:** Shows the number and frequency of fraud flags raised. Each spike indicates suspicious claims detected by the fraud detection model.

---

## 3. Claim Submissions vs Fraudulent Claims Ratio

```kql
union
    (customEvents 
     | where name == "Claim_Submitted"
     | where properties.tenant == "customerA"
     | summarize SubmissionCount = count() by bin(timestamp, 1h)),
    (customEvents
     | where name == "Fraud_Flag_Raised"
     | where properties.tenant == "customerA"
     | summarize FraudCount = count() by bin(timestamp, 1h))
| summarize 
    TotalSubmissions = sum(SubmissionCount),
    TotalFraud = sum(FraudCount)
| extend FraudRate = round((TotalFraud * 100 / TotalSubmissions), 2)
```

**Explanation:** Calculates the percentage of submitted claims flagged for fraud. High fraud rates may indicate model drift or changing claim patterns.

---

## 4. Claims API Performance - Response Time & Error Rate

```kql
requests
| where name == "Claims_API_Called" or url contains "/api/claims"
| summarize 
    AvgResponseTime = avg(duration),
    MaxResponseTime = max(duration),
    RequestCount = count(),
    FailedCount = countif(success == false)
    by bin(timestamp, 5m)
| extend ErrorRate = round((FailedCount * 100 / RequestCount), 2)
| render timechart
```

**Explanation:** Monitors Claims API health metrics: response time and error rate. If error rate exceeds 5%, alert should trigger.

---

## 5. Error Analysis - Claims Processing Errors by Type

```kql
customEvents
| where name == "Claim_Processing_Error_Count"
| where properties.tenant == "customerA"
| summarize ErrorCount = count() by tostring(properties.errorType)
| order by ErrorCount desc
| render piechart
```

**Explanation:** Breaks down claim processing errors by category (policy lookup failed, fraud API timeout, database connection, etc.). Helps identify systemic issues.

---

## 6. Fraud Detection Model Performance - Latency Distribution

```kql
customMetrics
| where name == "Fraud_Detection_Latency"
| where properties.tenant == "customerA"
| summarize 
    AvgLatency = avg(value),
    P50Latency = percentile(value, 50),
    P95Latency = percentile(value, 95),
    P99Latency = percentile(value, 99),
    MaxLatency = max(value)
| render table
```

**Explanation:** Shows fraud detection model response time distribution. Use to identify performance bottlenecks or degradation.

---

## 7. Claim Amount Analysis - Potential Risk Indicators

```kql
customMetrics
| where name == "Claim_Submission_Amount"
| where properties.tenant == "customerA"
| summarize 
    AvgAmount = avg(value),
    MaxAmount = max(value),
    MinAmount = min(value),
    SubmissionCount = count()
    by bin(timestamp, 1h)
| order by timestamp desc
```

**Explanation:** Tracks claim submission amounts over time. Sudden spikes in claim amounts may indicate fraudulent activity.

---

## 8. System Health - Application Uptime & Memory Usage

```kql
customMetrics
| where name in ("Memory_Heap_Used", "Memory_RSS")
| where properties.tenant == "customerA"
| summarize 
    AvgHeapUsed = avg(iif(name == "Memory_Heap_Used", value, 0)),
    AvgRSS = avg(iif(name == "Memory_RSS", value, 0))
    by bin(timestamp, 5m), name
| render timechart
```

**Explanation:** Monitors application memory consumption. Use to detect memory leaks or capacity issues.

---

## 9. High-Value Claims Alert - Track Claims Above Threshold

```kql
customMetrics
| where name == "Claim_Submission_Amount"
| where properties.tenant == "customerA"
| where value > 10000
| join kind=left (
    customEvents
    | where name == "Fraud_Flag_Raised"
    | project claimId = tostring(properties.claimId)
) on $left.properties.policyNumber == $right.claimId
| summarize Count = count() by bin(timestamp, 1h)
| render barchart
```

**Explanation:** Highlights high-value claims (above $10,000) for additional scrutiny, especially those with fraud flags.

---

## 10. Dependency Performance - External Service Latencies

```kql
dependencies
| where properties.tenant == "customerA"
| summarize 
    AvgDuration = avg(duration),
    MaxDuration = max(duration),
    FailureCount = countif(success == false),
    SuccessCount = countif(success == true)
    by name, resultCode
| order by AvgDuration desc
```

**Explanation:** Tracks latency and reliability of external dependencies (fraud detection API, policy lookup service, database). Use to identify bottlenecks.

---

## Demo Scenario Queries

### Scenario A: High Fraud Detection During Peak Hours

```kql
let PeakHours = range(14, 17, 1); // 2 PM - 5 PM
customEvents
| where name == "Fraud_Flag_Raised"
| where properties.tenant == "customerA"
| extend Hour = tohour(timestamp)
| where Hour in (PeakHours)
| summarize FraudCount = count() by Hour, bin(timestamp, 30m)
| render barchart
```

### Scenario B: Claims Processing SLA Compliance

```kql
customMetrics
| where name == "Claim_Processing_Duration"
| where properties.tenant == "customerA"
| extend SLAMet = iif(value <= 2000, "✅ Within SLA", "❌ Exceeded SLA")
| summarize 
    SLACompliance = (todouble(countif(value <= 2000)) / count()) * 100,
    AvgTime = avg(value),
    Percentile95 = percentile(value, 95)
| render table
```

### Scenario C: Fraud Model Accuracy & Precision

```kql
union
    (customEvents
     | where name == "Fraud_Flag_Raised"
     | where properties.tenant == "customerA"
     | summarize FlaggedCount = count()),
    (customEvents
     | where name == "Claim_Submitted"
     | where properties.tenant == "customerA"
     | summarize SubmittedCount = count())
| summarize 
    TotalFlags = sum(FlaggedCount),
    TotalSubmissions = sum(SubmittedCount)
| extend PrecisionRate = round((TotalFlags * 100 / TotalSubmissions), 2)
```

---

## Dashboard Tiles Configuration

### Tile 1: Claims API Performance
- **Query:** Query #4 above
- **Visual:** Line chart
- **Alert:** Error rate > 5% or Avg Response Time > 2000 ms

### Tile 2: Fraud Detection Activity
- **Query:** Query #2 above
- **Visual:** Bar chart
- **Alert:** Fraud flags > 20 in a 5-minute window

### Tile 3: System Health
- **Query:** Query #8 above
- **Visual:** Line chart
- **Alert:** Memory heap > 500 MB

### Tile 4: Claims Processing Latency
- **Query:** Query #1 above
- **Visual:** Time series
- **SLA Threshold:** 2000 ms (P95 should be below this)

### Tile 5: Fraud Rate Trends
- **Query:** Query #3 above
- **Visual:** Card/metric
- **Target:** Keep fraud rate < 10%
