# NPE Infrastructure Testing Script
# Tests VPC, Cloud SQL, Storage, IAM, and Cloud Run connectivity
# Usage: .\test-npe-infrastructure.ps1

param(
    [string]$ProjectId = "project-07a61357-b791-4255-a9e",
    [string]$Region = "europe-west2",
    [string]$Environment = "npe"
)

# Colors for output
$SuccessColor = "Green"
$ErrorColor = "Red"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

function Write-TestHeader {
    param([string]$Title)
    Write-Host "`n" + ("=" * 60) -ForegroundColor $InfoColor
    Write-Host "TEST: $Title" -ForegroundColor $InfoColor
    Write-Host ("=" * 60) -ForegroundColor $InfoColor
}

function Write-Success {
    param([string]$Message)
    Write-Host "SUCCESS: $Message" -ForegroundColor $SuccessColor
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor $ErrorColor
}

function Write-Info {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor $InfoColor
}

function Test-Command {
    param([string]$Command, [string]$Description)
    Write-Info "Testing: $Description"
    try {
        $result = Invoke-Expression $Command 2>&1
        if ($LASTEXITCODE -eq 0 -or $result) {
            Write-Success $Description
            return $result
        } else {
            Write-ErrorMsg "$Description failed"
            return $null
        }
    } catch {
        Write-ErrorMsg "$Description - Exception: $_"
        return $null
    }
}

# ===== MAIN TESTS =====

Write-Host "`nFincore NPE Infrastructure Test Suite" -ForegroundColor $InfoColor
Write-Host "Project: $ProjectId | Region: $Region" -ForegroundColor $InfoColor

# Test 1: VPC Network
Write-TestHeader "VPC Network Configuration"

Test-Command `
    "gcloud compute networks describe fincore-$environment-vpc --project=$ProjectId --format='value(name,selfLink)'" `
    "Verify VPC network exists"

Test-Command `
    "gcloud compute networks subnets list --network=fincore-$environment-vpc --project=$ProjectId --format='table(name,ipCidrRange,region)'" `
    "List VPC subnets"

Test-Command `
    "gcloud compute firewall-rules list --filter=network:fincore-$environment-vpc --project=$ProjectId --format='table(name,sourceRanges)'" `
    "List firewall rules"

Test-Command `
    "gcloud compute vpc-access connectors describe npe-connector --region=$Region --project=$ProjectId --format='value(name,state)'" `
    "Verify Serverless VPC Connector"

# Test 2: Cloud SQL
Write-TestHeader "Cloud SQL Database"

$SqlInstance = Test-Command `
    "gcloud sql instances describe fincore-$environment-db --project=$ProjectId --format='value(connectionName,databaseVersion,settings.tier)'" `
    "Describe Cloud SQL instance"

if ($SqlInstance) {
    Write-Info "Instance Details: $SqlInstance"
    
    Test-Command `
        "gcloud sql databases list --instance=fincore-$environment-db --project=$ProjectId --format='table(name)'" `
        "List databases"
    
    Test-Command `
        "gcloud sql users list --instance=fincore-$environment-db --project=$ProjectId --format='table(name)'" `
        "List database users"
    
    Test-Command `
        "gcloud sql backups list --instance=fincore-$environment-db --project=$ProjectId --limit=3 --format='table(name,windowStartTime)'" `
        "List recent backups"
}

# Test 3: Cloud Storage
Write-TestHeader "Cloud Storage Buckets"

$Buckets = @(
    "fincore-$environment-terraform-state",
    "fincore-$environment-artifacts",
    "fincore-$environment-uploads"
)

foreach ($Bucket in $Buckets) {
    Write-Info "Testing bucket: $Bucket"
    Test-Command `
        "gcloud storage buckets describe gs://$Bucket --project=$ProjectId --format='value(name,location,uniformBucketLevelAccess.enabled)'" `
        "Verify bucket $Bucket exists"
}

# Test 4: Service Accounts and IAM
Write-TestHeader "Service Accounts and IAM Roles"

Test-Command `
    "gcloud iam service-accounts list --project=$ProjectId --format='table(email,displayName)'" `
    "List service accounts"

Test-Command `
    "gcloud projects get-iam-policy $ProjectId --flatten='bindings[].members' --filter='bindings.members:fincore-npe-cloudrun' --format='table(bindings.role)'" `
    "Check Cloud Run service account roles"

Test-Command `
    "gcloud secrets list --project=$ProjectId --format='table(name,created)'" `
    "List secrets in Secret Manager"

# Test 5: Monitoring and Logging
Write-TestHeader "Monitoring and Logging"

Test-Command `
    "gcloud alpha monitoring policies list --project=$ProjectId --format='table(displayName,enabled)'" `
    "List alert policies"

Test-Command `
    "gcloud logging sinks list --project=$ProjectId --format='table(name,destination)'" `
    "List logging sinks"

# Test 6: Cloud Run Services
Write-TestHeader "Cloud Run Services"

$CloudRunServices = Test-Command `
    "gcloud run services list --region=$Region --project=$ProjectId --format='table(metadata.name,status.url)'" `
    "List Cloud Run services"

if ($CloudRunServices) {
    Write-Info "Attempting to retrieve service URLs..."
    
    try {
        $ApiUrl = gcloud run services describe fincore-$environment-api --region=$Region --project=$ProjectId --format='value(status.url)' 2>/dev/null
        if ($ApiUrl) {
            Write-Success "API Service URL: $ApiUrl"
        }
    } catch {
        Write-ErrorMsg "Could not retrieve API service URL"
    }
    
    try {
        $FrontendUrl = gcloud run services describe fincore-$environment-frontend --region=$Region --project=$ProjectId --format='value(status.url)' 2>/dev/null
        if ($FrontendUrl) {
            Write-Success "Frontend Service URL: $FrontendUrl"
        }
    } catch {
        Write-ErrorMsg "Could not retrieve Frontend service URL"
    }
} else {
    Write-Host "`nCloud Run services not yet deployed." -ForegroundColor $WarningColor
    Write-Info "Push container images to continue:"
    Write-Info "  docker build -t gcr.io/$ProjectId/fincore-api:latest ./api"
    Write-Info "  docker push gcr.io/$ProjectId/fincore-api:latest"
    Write-Info "  docker build -t gcr.io/$ProjectId/fincore-frontend:latest ./frontend"
    Write-Info "  docker push gcr.io/$ProjectId/fincore-frontend:latest"
    Write-Info "Then run: terraform apply -var-file=environments/npe/terraform.tfvars -auto-approve"
}

# Test 7: Logs Check
Write-TestHeader "Recent Logs and Errors"

Write-Info "Checking Cloud SQL error logs (last 30 minutes)..."
Test-Command `
    "gcloud logging read 'resource.type=cloudsql_database AND severity=ERROR' --limit=5 --format='table(timestamp)' --project=$ProjectId" `
    "Cloud SQL error logs"

Write-Info "Checking Cloud Run error logs (last 30 minutes)..."
Test-Command `
    "gcloud logging read 'resource.type=cloud_run_revision AND severity=ERROR' --limit=5 --format='table(timestamp)' --project=$ProjectId" `
    "Cloud Run error logs"

# Summary
Write-Host "`n" + ("=" * 60) -ForegroundColor $InfoColor
Write-Host "TEST SUITE COMPLETE" -ForegroundColor $InfoColor
Write-Host ("=" * 60) -ForegroundColor $InfoColor

Write-Host "`nNext Steps:" -ForegroundColor $WarningColor
Write-Host "1. If Cloud Run services not deployed:"
Write-Host "   - Build and push Docker images"
Write-Host "   - Run terraform apply to deploy services"
Write-Host ""
Write-Host "2. Once Cloud Run deployed:"
Write-Host "   - Test API endpoints with curl or Postman"
Write-Host "   - Verify Cloud SQL connectivity in logs"
Write-Host ""
Write-Host "3. Monitor costs:"
Write-Host "   - GCP Console: Billing section"
Write-Host "   - Expected: approximately 22 USD per month"
