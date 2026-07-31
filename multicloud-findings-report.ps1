$ErrorActionPreference = "Stop"

Write-Host "Pulling AWS Security Hub findings..." -ForegroundColor Cyan
$awsRaw = aws securityhub get-findings `
    --filters '{\"RecordState\":[{\"Value\":\"ACTIVE\",\"Comparison\":\"EQUALS\"}],\"ComplianceStatus\":[{\"Value\":\"FAILED\",\"Comparison\":\"EQUALS\"}]}' `
    --output json | ConvertFrom-Json

$awsFindings = $awsRaw.Findings | ForEach-Object {
    [PSCustomObject]@{
        Cloud    = "AWS"
        Resource = $_.Resources[0].Id
        Title    = $_.Title
        Priority = $_.Severity.Label
    }
}

Write-Host "Pulling Azure Defender for Cloud assessments..." -ForegroundColor Cyan
$azureRaw = az security assessment list --query "[].{displayName:displayName, status:status.code, resourceName:resourceDetails.ResourceName}" --output json | ConvertFrom-Json

$azureFindings = $azureRaw | Where-Object { $_.status -eq "Unhealthy" } | ForEach-Object {
    [PSCustomObject]@{
        Cloud    = "Azure"
        Resource = $_.resourceName
        Title    = $_.displayName
        Priority = "Flagged"
    }
}

$combined = $awsFindings + $azureFindings

Write-Host ""
Write-Host "=== Unified Multi-Cloud Findings Report ===" -ForegroundColor Green
$combined | Format-Table -AutoSize

$combined | Export-Csv -Path "multicloud-findings-report.csv" -NoTypeInformation
Write-Host "Saved to multicloud-findings-report.csv" -ForegroundColor Green