# Database Migration Runner - NPE Environment
# Purpose: Execute database migration from my_auth_db to fincore_db
# Target: fincore-npe-db Cloud SQL instance

param(
    [string]$Project = "project-07a61357-b791-4255-a9e",
    [string]$Instance = "fincore-npe-db",
    [string]$RootPassword = "TempRoot2024!",
    [switch]$DryRun = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Database Migration to fincore_db" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verify prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check if gcloud is installed
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Error "gcloud CLI is not installed. Please install it first."
    exit 1
}

# Check if Cloud SQL Proxy is needed
$cloudSqlProxy = Get-Command cloud-sql-proxy -ErrorAction SilentlyContinue
$cloudSqlProxyV2 = Get-Command cloud_sql_proxy -ErrorAction SilentlyContinue

if (-not $cloudSqlProxy -and -not $cloudSqlProxyV2) {
    Write-Host "Cloud SQL Proxy not found. You can:" -ForegroundColor Yellow
    Write-Host "1. Install it: https://cloud.google.com/sql/docs/mysql/sql-proxy" -ForegroundColor Yellow
    Write-Host "2. Or use direct IP connection (requires authorized network)" -ForegroundColor Yellow
    Write-Host ""
}

# Get the Cloud SQL instance public IP
Write-Host "Fetching Cloud SQL instance information..." -ForegroundColor Yellow
$instanceInfo = gcloud sql instances describe $Instance --project=$Project --format=json | ConvertFrom-Json
$publicIp = $instanceInfo.ipAddresses | Where-Object { $_.type -eq "PRIMARY" } | Select-Object -ExpandProperty ipAddress

Write-Host "Instance: $Instance" -ForegroundColor Green
Write-Host "Public IP: $publicIp" -ForegroundColor Green
Write-Host ""

# Check if mysql client is available
$mysqlCmd = Get-Command mysql -ErrorAction SilentlyContinue

if (-not $mysqlCmd) {
    Write-Host "MySQL client not found. Installing portable version..." -ForegroundColor Yellow
    
    # Download MySQL client
    $tempDir = Join-Path $env:TEMP "mysql_temp_$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    $zipUrl = "https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.33-winx64.zip"
    $zipPath = Join-Path $tempDir "mysql.zip"
    
    Write-Host "Downloading MySQL client..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    
    Write-Host "Extracting MySQL client..." -ForegroundColor Yellow
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
    
    $mysqlExe = Get-ChildItem -Path $tempDir -Recurse -Filter "mysql.exe" | Select-Object -First 1
    $mysqlCmd = $mysqlExe.FullName
    
    Write-Host "MySQL client ready: $mysqlCmd" -ForegroundColor Green
} else {
    $mysqlCmd = $mysqlCmd.Source
    Write-Host "MySQL client found: $mysqlCmd" -ForegroundColor Green
}

Write-Host ""

# Display migration plan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Migration Plan" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Drop database: my_auth_db" -ForegroundColor Yellow
Write-Host "Create database: fincore_db" -ForegroundColor Yellow
Write-Host "  - Charset: utf8mb4" -ForegroundColor Gray
Write-Host "  - Collation: utf8mb4_general_ci (case-insensitive)" -ForegroundColor Gray
Write-Host "Grant permissions to fincore_app" -ForegroundColor Yellow
Write-Host "Grant permissions to fincore_admin" -ForegroundColor Yellow
Write-Host "Test case-insensitive behavior" -ForegroundColor Yellow
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Magenta
    Write-Host "Migration script location: scripts/migrate-to-fincore-db.sql" -ForegroundColor Cyan
    exit 0
}

# Confirm execution
Write-Host "WARNING: This will DROP the my_auth_db database!" -ForegroundColor Red
Write-Host "All data in my_auth_db will be permanently deleted!" -ForegroundColor Red
Write-Host ""
$confirmation = Read-Host "Type 'MIGRATE' to proceed"

if ($confirmation -ne "MIGRATE") {
    Write-Host "Migration cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Starting migration..." -ForegroundColor Green

# Execute migration script
$scriptPath = Join-Path $PSScriptRoot "migrate-to-fincore-db.sql"

if (-not (Test-Path $scriptPath)) {
    Write-Error "Migration script not found: $scriptPath"
    exit 1
}

try {
    Write-Host "Executing migration script..." -ForegroundColor Yellow
    Write-Host "Connecting to: $publicIp" -ForegroundColor Gray
    Write-Host ""
    
    # Execute the SQL script
    Get-Content $scriptPath | & $mysqlCmd -h $publicIp -u root -p"$RootPassword" --verbose
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Migration Completed Successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Update application connection strings to use fincore_db" -ForegroundColor White
    Write-Host "2. Deploy updated Terraform configuration to NPE" -ForegroundColor White
    Write-Host "3. Test application connectivity" -ForegroundColor White
    Write-Host "4. Verify case-insensitive DDL operations" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Error "Migration failed: $_"
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Verify root password is correct" -ForegroundColor White
    Write-Host "2. Check if IP is accessible" -ForegroundColor White
    Write-Host "3. Ensure authorized networks allow your IP" -ForegroundColor White
    Write-Host "4. Review the migration script in scripts folder" -ForegroundColor White
    exit 1
} finally {
    # Cleanup temp directory if we created one
    if ($tempDir -and (Test-Path $tempDir)) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
