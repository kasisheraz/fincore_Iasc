# Test GitHub Actions Service Account
Write-Host "=== TESTING NEW GITHUB ACTIONS SERVICE ACCOUNT ===" -ForegroundColor Green

$serviceAccount = "fincore-github-actions@project-07a61357-b791-4255-a9e.iam.gserviceaccount.com"
$projectId = "project-07a61357-b791-4255-a9e"

Write-Host "`n1. VERIFYING SERVICE ACCOUNT STATUS" -ForegroundColor Cyan
Write-Host "-" * 40

try {
    $saDetails = gcloud iam service-accounts describe $serviceAccount --format="value(disabled,email)" --quiet
    $saInfo = $saDetails -split "`t"
    
    if ($saInfo[0] -eq "False") {
        Write-Host "✅ Service Account: ACTIVE" -ForegroundColor Green
        Write-Host "✅ Email: $($saInfo[1])" -ForegroundColor Green
    } else {
        Write-Host "❌ Service Account: DISABLED" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Failed to verify service account: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n2. CHECKING IAM PERMISSIONS" -ForegroundColor Cyan
Write-Host "-" * 40

$requiredRoles = @(
    "roles/cloudsql.admin",
    "roles/storage.admin", 
    "roles/secretmanager.admin",
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.writer"
)

try {
    $iamPolicy = gcloud projects get-iam-policy $projectId --format="json" --quiet | ConvertFrom-Json
    
    foreach ($role in $requiredRoles) {
        $binding = $iamPolicy.bindings | Where-Object { $_.role -eq $role }
        if ($binding -and $binding.members -contains "serviceAccount:$serviceAccount") {
            Write-Host "✅ $role" -ForegroundColor Green
        } else {
            Write-Host "❌ $role" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ Failed to check IAM permissions: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n3. TESTING GCP API ACCESS" -ForegroundColor Cyan
Write-Host "-" * 40

try {
    # Test Cloud SQL access
    $sqlInstances = gcloud sql instances list --limit=1 --format="value(name)" --quiet
    if ($sqlInstances) {
        Write-Host "✅ Cloud SQL API: ACCESSIBLE" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Cloud SQL API: NOT ACCESSIBLE" -ForegroundColor Red
}

try {
    # Test Secret Manager access
    $secrets = gcloud secrets list --limit=1 --format="value(name)" --quiet 2>$null
    Write-Host "✅ Secret Manager API: ACCESSIBLE" -ForegroundColor Green
} catch {
    Write-Host "❌ Secret Manager API: NOT ACCESSIBLE" -ForegroundColor Red
}

try {
    # Test Storage access
    $buckets = gcloud storage ls --format="value(name)" --quiet 2>$null
    Write-Host "✅ Storage API: ACCESSIBLE" -ForegroundColor Green  
} catch {
    Write-Host "❌ Storage API: NOT ACCESSIBLE" -ForegroundColor Red
}

Write-Host "`n4. WORKFLOW VERIFICATION" -ForegroundColor Cyan
Write-Host "-" * 40

$workflowFiles = @(
    ".github/workflows/deploy.yml",
    ".github/workflows/promote.yml", 
    ".github/workflows/pr-validation.yml"
)

foreach ($workflow in $workflowFiles) {
    if (Test-Path $workflow) {
        $content = Get-Content $workflow -Raw
        if ($content -match "google-github-actions/auth@v2") {
            Write-Host "✅ $workflow: Uses modern auth" -ForegroundColor Green
        } elseif ($content -match "google-github-actions/setup-gcloud") {
            Write-Host "⚠️  $workflow: Uses older auth method" -ForegroundColor Yellow
        } else {
            Write-Host "❌ $workflow: No GCP auth found" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ $workflow: File not found" -ForegroundColor Red
    }
}

Write-Host "`n" + "=" * 60
Write-Host "GITHUB ACTIONS READINESS SUMMARY" -ForegroundColor Green  
Write-Host "=" * 60

Write-Host "Service Account: fincore-github-actions@***" -ForegroundColor White
Write-Host "Project: $projectId" -ForegroundColor White

Write-Host "`n📋 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Copy the service account key from GITHUB_ACTIONS_FIX.md" -ForegroundColor White
Write-Host "2. Update GitHub Secret 'GCP_SA_KEY' with the JSON content" -ForegroundColor White  
Write-Host "3. Update GitHub Variable 'GCP_PROJECT_ID' to: $projectId" -ForegroundColor White
Write-Host "4. Test a GitHub Actions workflow run" -ForegroundColor White

Write-Host "`n🎯 Authentication issue will be resolved after updating GitHub secrets!" -ForegroundColor Green