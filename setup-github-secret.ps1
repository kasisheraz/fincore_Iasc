#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Setup GitHub Secret for GCP Service Account Key
    
.DESCRIPTION
    This script helps you add the GCP service account key as a GitHub secret
    for use in GitHub Actions workflows.
    
.NOTES
    Prerequisites:
    - gcloud CLI installed and authenticated
    - GitHub CLI (gh) installed and authenticated
    - Owner/Admin access to the GitHub repository
#>

$ErrorActionPreference = "Stop"

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  GitHub Secret Setup for Fincore Infrastructure Deployment  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Configuration
$PROJECT_ID = "project-07a61357-b791-4255-a9e"
$SA_NAME = "fincore-github-actions"
$SA_EMAIL = "$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
$KEY_FILE = "gcp-sa-key.json"
$REPO = "kasisheraz/fincore_Iasc"

# Step 1: Check if gcloud is installed
Write-Host "🔍 Checking gcloud CLI..." -ForegroundColor Yellow
try {
    $gcloudVersion = gcloud version --format="value(version)" 2>$null
    Write-Host "   ✅ gcloud CLI found (version: $gcloudVersion)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ gcloud CLI not found. Please install it first:" -ForegroundColor Red
    Write-Host "      https://cloud.google.com/sdk/docs/install" -ForegroundColor White
    exit 1
}

# Step 2: Check if GitHub CLI is installed
Write-Host "`n🔍 Checking GitHub CLI..." -ForegroundColor Yellow
try {
    $ghVersion = gh --version 2>$null | Select-String "gh version" | ForEach-Object { $_.ToString() }
    Write-Host "   ✅ GitHub CLI found ($ghVersion)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ GitHub CLI not found. Please install it first:" -ForegroundColor Red
    Write-Host "      https://cli.github.com/" -ForegroundColor White
    Write-Host "`n   Or install via winget:" -ForegroundColor Yellow
    Write-Host "      winget install GitHub.cli" -ForegroundColor White
    exit 1
}

# Step 3: Check GitHub authentication
Write-Host "`n🔍 Checking GitHub authentication..." -ForegroundColor Yellow
try {
    $ghAuth = gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ GitHub CLI authenticated" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Not authenticated. Running 'gh auth login'..." -ForegroundColor Yellow
        gh auth login
    }
} catch {
    Write-Host "   ❌ GitHub authentication failed" -ForegroundColor Red
    exit 1
}

# Step 4: Check if service account key exists
Write-Host "`n📁 Checking for service account key..." -ForegroundColor Yellow
if (Test-Path $KEY_FILE) {
    Write-Host "   ✅ Found existing key: $KEY_FILE" -ForegroundColor Green
    $useExisting = Read-Host "`n   Use existing key? (y/n)"
    if ($useExisting -ne 'y') {
        Write-Host "   Creating new key..." -ForegroundColor Yellow
        Remove-Item $KEY_FILE -Force
        gcloud iam service-accounts keys create $KEY_FILE `
            --iam-account=$SA_EMAIL `
            --project=$PROJECT_ID
        Write-Host "   ✅ New key created" -ForegroundColor Green
    }
} else {
    Write-Host "   ⚠️  Key not found. Creating new key..." -ForegroundColor Yellow
    
    # Check if service account exists
    $saExists = gcloud iam service-accounts list --project=$PROJECT_ID --format="value(email)" | Select-String $SA_EMAIL
    
    if (-not $saExists) {
        Write-Host "`n   Creating service account: $SA_NAME" -ForegroundColor Yellow
        
        gcloud iam service-accounts create $SA_NAME `
            --display-name="Fincore GitHub Actions" `
            --project=$PROJECT_ID
        
        Write-Host "   ✅ Service account created" -ForegroundColor Green
        
        Write-Host "`n   Granting IAM roles..." -ForegroundColor Yellow
        
        # Grant roles
        gcloud projects add-iam-policy-binding $PROJECT_ID `
            --member="serviceAccount:$SA_EMAIL" `
            --role="roles/cloudsql.admin" `
            --condition=None
        
        gcloud projects add-iam-policy-binding $PROJECT_ID `
            --member="serviceAccount:$SA_EMAIL" `
            --role="roles/secretmanager.admin" `
            --condition=None
        
        gcloud projects add-iam-policy-binding $PROJECT_ID `
            --member="serviceAccount:$SA_EMAIL" `
            --role="roles/compute.networkAdmin" `
            --condition=None
        
        Write-Host "   ✅ IAM roles granted" -ForegroundColor Green
    }
    
    # Create key
    Write-Host "`n   Creating service account key..." -ForegroundColor Yellow
    gcloud iam service-accounts keys create $KEY_FILE `
        --iam-account=$SA_EMAIL `
        --project=$PROJECT_ID
    
    Write-Host "   ✅ Key created: $KEY_FILE" -ForegroundColor Green
}

# Step 5: Read the key file
Write-Host "`n📖 Reading service account key..." -ForegroundColor Yellow
$keyContent = Get-Content $KEY_FILE -Raw
Write-Host "   ✅ Key loaded ($(($keyContent.Length)) characters)" -ForegroundColor Green

# Step 6: Add secret to GitHub
Write-Host "`n🔐 Adding secret to GitHub repository..." -ForegroundColor Yellow
Write-Host "   Repository: $REPO" -ForegroundColor White
Write-Host "   Secret name: GCP_SA_KEY" -ForegroundColor White

try {
    # Use gh secret set command
    $keyContent | gh secret set GCP_SA_KEY --repo $REPO
    Write-Host "   ✅ Secret 'GCP_SA_KEY' added successfully!" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to add secret: $_" -ForegroundColor Red
    Write-Host "`n   You can manually add the secret:" -ForegroundColor Yellow
    Write-Host "   1. Go to: https://github.com/$REPO/settings/secrets/actions" -ForegroundColor White
    Write-Host "   2. Click 'New repository secret'" -ForegroundColor White
    Write-Host "   3. Name: GCP_SA_KEY" -ForegroundColor White
    Write-Host "   4. Value: [Copy content from $KEY_FILE]" -ForegroundColor White
    exit 1
}

# Step 7: Verify secret was added
Write-Host "`n✅ Verifying secret..." -ForegroundColor Yellow
$secrets = gh secret list --repo $REPO
if ($secrets -match "GCP_SA_KEY") {
    Write-Host "   ✅ Secret verified in repository" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Could not verify secret (but it may have been added)" -ForegroundColor Yellow
}

# Step 8: Check for GCP_PROJECT_ID variable
Write-Host "`n🔍 Checking GCP_PROJECT_ID variable..." -ForegroundColor Yellow
try {
    $vars = gh variable list --repo $REPO 2>&1
    if ($vars -match "GCP_PROJECT_ID") {
        Write-Host "   ✅ Variable GCP_PROJECT_ID already exists" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Variable GCP_PROJECT_ID not found. Adding..." -ForegroundColor Yellow
        gh variable set GCP_PROJECT_ID --body $PROJECT_ID --repo $REPO
        Write-Host "   ✅ Variable GCP_PROJECT_ID added" -ForegroundColor Green
    }
} catch {
    Write-Host "   ℹ️  Could not verify variable (may need manual setup)" -ForegroundColor Cyan
}

# Completion
Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    Setup Complete! ✅                        ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Re-run your GitHub Actions workflow" -ForegroundColor White
Write-Host "   2. Monitor deployment: https://github.com/$REPO/actions" -ForegroundColor White
Write-Host "`n⚠️  Security Note:" -ForegroundColor Yellow
Write-Host "   - The key file '$KEY_FILE' contains sensitive credentials" -ForegroundColor White
Write-Host "   - It is gitignored and should NEVER be committed to git" -ForegroundColor White
Write-Host "   - Store it securely or delete it after setup" -ForegroundColor White

Write-Host "`n✨ Your GitHub Actions workflow can now authenticate to GCP!" -ForegroundColor Green
Write-Host ""
