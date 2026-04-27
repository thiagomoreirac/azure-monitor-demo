param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [Parameter(Mandatory = $false)]
    [int]$DurationSeconds = 300,

    [Parameter(Mandatory = $false)]
    [int]$DelayMs = 800,

    [Parameter(Mandatory = $false)]
    [string]$Tenant = "customerA",

    [Parameter(Mandatory = $false)]
    [string]$Region = "francecentral"
)

$ErrorActionPreference = "Continue"

function New-Hex([int]$length) {
    $chars = "0123456789abcdef"
    $out = ""
    for ($i = 0; $i -lt $length; $i++) {
        $out += $chars[(Get-Random -Minimum 0 -Maximum 16)]
    }
    return $out
}

function New-TraceParent() {
    $version = "00"
    $traceId = New-Hex 32
    $spanId = New-Hex 16
    $flags = "01"
    return "$version-$traceId-$spanId-$flags"
}

$base = $BaseUrl.TrimEnd('/')
$deadline = (Get-Date).AddSeconds($DurationSeconds)
$otelCalls = 0
$nonOtelCalls = 0
$errors = 0

Write-Host "Generating telemetry for $DurationSeconds seconds against $base"
Write-Host "OTel-like traffic: /health, /api/claims, /api/submit-claim, /fraud-check, /load"
Write-Host "Non-OTel traffic: /api/external-ingest"

while ((Get-Date) -lt $deadline) {
    $traceParent = New-TraceParent
    $headers = @{
        "traceparent" = $traceParent
        "x-tenant" = $Tenant
    }

    try { Invoke-RestMethod -Uri "$base/health" -Headers $headers -Method Get -TimeoutSec 10 | Out-Null; $otelCalls += 1 } catch { $errors += 1 }
    try { Invoke-RestMethod -Uri "$base/api/claims" -Headers $headers -Method Get -TimeoutSec 10 | Out-Null; $otelCalls += 1 } catch { $errors += 1 }
    try { Invoke-RestMethod -Uri "$base/fraud-check?claimId=$((Get-Random -Minimum 1 -Maximum 6))" -Headers $headers -Method Get -TimeoutSec 10 | Out-Null; $otelCalls += 1 } catch { $errors += 1 }
    try { Invoke-RestMethod -Uri "$base/load?iterations=$((Get-Random -Minimum 1000 -Maximum 5000))" -Headers $headers -Method Get -TimeoutSec 15 | Out-Null; $otelCalls += 1 } catch { $errors += 1 }

    $claimPayload = @{
        source = "otel-demo"
        tenant = $Tenant
        region = $Region
        amount = Get-Random -Minimum 1000 -Maximum 25000
    } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri "$base/api/submit-claim" -Headers $headers -Method Post -ContentType "application/json" -Body $claimPayload -TimeoutSec 10 | Out-Null
        $otelCalls += 1
    } catch {
        $errors += 1
    }

    # Occasionally trigger an application error signal for RCA.
    if ((Get-Random -Minimum 1 -Maximum 100) -le 10) {
        try { Invoke-RestMethod -Uri "$base/error" -Headers $headers -Method Get -TimeoutSec 10 | Out-Null } catch { }
    }

    try {
        $status = if ((Get-Random -Minimum 1 -Maximum 100) -le 80) { "success" } else { "failed" }
        $externalPayload = @{
            tenant = $Tenant
            region = $Region
            serviceName = (Get-Random -InputObject @("fraud-api", "policy-service", "payment-gateway", "partner-claims-api"))
            eventType = (Get-Random -InputObject @("QuoteRequested", "PolicyValidated", "FraudCheck", "PaymentAuthorization", "ClaimExport"))
            latencyMs = Get-Random -Minimum 80 -Maximum 2500
            status = $status
            severity = if ($status -eq "success") { 1 } else { 3 }
            traceId = New-Hex 32
        } | ConvertTo-Json

        Invoke-RestMethod -Uri "$base/api/external-ingest" -Method Post -ContentType "application/json" -Body $externalPayload -TimeoutSec 10 | Out-Null
        $nonOtelCalls += 1
    }
    catch {
        $errors += 1
    }

    Start-Sleep -Milliseconds $DelayMs
}

Write-Host ""
Write-Host "Telemetry generation finished."
Write-Host "OTel-like calls sent: $otelCalls"
Write-Host "Non-OTel payloads sent: $nonOtelCalls"
Write-Host "Request errors: $errors"
Write-Host ""
Write-Host "Suggested Azure Copilot follow-up prompts:"
Write-Host "1) In Microsoft Copilot in Azure, analyze the last 15 minutes for this App Insights resource and summarize top latency contributors."
Write-Host "2) Create an advanced dashboard for external services using dependencies, traces, and exceptions grouped by tenant and region."
Write-Host "3) Run RCA for fraud-api failures and provide root cause with mitigation actions."
