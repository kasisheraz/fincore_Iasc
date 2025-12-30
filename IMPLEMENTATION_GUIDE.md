# Implementation Steps for Fincore Infrastructure with Database Permissions

## 🚀 Step-by-Step Implementation Guide

### Prerequisites Check ✅

Before proceeding, ensure you have:

- [ ] **Google Cloud CLI** installed and authenticated
- [ ] **Terraform** >= 1.6.0 installed
- [ ] **Git** repository access
- [ ] **GCP Project** with billing enabled
- [ ] **Required APIs** enabled in GCP

### Step 1: Initialize Your Environment

```powershell
# Set environment variables
$env:PROJECT_ID = "project-07a61357-b791-4255-a9e"
$env:REGION = "europe-west2"
$env:ENVIRONMENT = "npe"  # or "prod"

# Authenticate with GCP
gcloud auth application-default login
gcloud config set project $env:PROJECT_ID
```

### Step 2: Enable Required GCP APIs

```powershell
# Enable all required APIs
$apis = @(
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "secretmanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com",
    "run.googleapis.com"
)

foreach ($api in $apis) {
    Write-Host "Enabling $api..." -ForegroundColor Cyan
    gcloud services enable $api --project=$env:PROJECT_ID
}
```

### Step 3: Create Terraform State Buckets

```powershell
# Create state storage buckets (if they don't exist)
Write-Host "Creating Terraform state buckets..." -ForegroundColor Green

# NPE environment
gsutil mb gs://fincore-npe-terraform-state 2>$null
gsutil versioning set on gs://fincore-npe-terraform-state

# Production environment (when ready)
gsutil mb gs://fincore-prod-terraform-state 2>$null
gsutil versioning set on gs://fincore-prod-terraform-state

Write-Host "State buckets created and versioning enabled." -ForegroundColor Green
```

### Step 4: Deploy NPE Environment

```powershell
# Navigate to terraform directory
cd "c:\Development\git\fincore_Iasc\terraform"

# Initialize Terraform with NPE backend
Write-Host "Initializing Terraform for NPE environment..." -ForegroundColor Green
terraform init -backend-config="environments/npe/backend.tf"

# Plan the deployment
Write-Host "Creating deployment plan..." -ForegroundColor Cyan
terraform plan -var-file="environments/npe/terraform.tfvars" -out=npe-plan

# Apply the deployment (will prompt for confirmation)
Write-Host "Applying infrastructure..." -ForegroundColor Yellow
terraform apply npe-plan
```

### Step 5: Verify Database Permissions

After successful deployment, verify the database permissions:

```powershell
# Get Cloud SQL connection info
$INSTANCE_CONNECTION_NAME = gcloud sql instances describe fincore-npe-db --format="value(connectionName)" --project=$env:PROJECT_ID

Write-Host "Cloud SQL Instance: $INSTANCE_CONNECTION_NAME" -ForegroundColor Green

# Connect to database and verify permissions (requires Cloud SQL Proxy or direct access)
Write-Host "To verify database permissions, connect to Cloud SQL:" -ForegroundColor Cyan
Write-Host "gcloud sql connect fincore-npe-db --user=root --project=$env:PROJECT_ID"
Write-Host ""
Write-Host "Then run these SQL commands:" -ForegroundColor Yellow
Write-Host "SHOW GRANTS FOR 'fincore_app'@'%';"
Write-Host "SHOW GRANTS FOR 'fincore_app'@'cloudsqlproxy~%';"
```

### Step 6: Set Up GitHub Actions

```powershell
# Set up GitHub repository secrets (do this in GitHub UI)
Write-Host "GitHub Actions Setup Required:" -ForegroundColor Magenta
Write-Host "1. Go to your GitHub repository settings"
Write-Host "2. Navigate to Secrets and variables > Actions"
Write-Host "3. Add the following secrets:"
Write-Host ""
Write-Host "   GCP_SA_KEY: Service account JSON key with required permissions"
Write-Host "   (Create service account with Cloud SQL Admin, Compute Admin, etc.)"
Write-Host ""
Write-Host "4. Add the following variables:"
Write-Host "   GCP_PROJECT_ID: $env:PROJECT_ID"
Write-Host ""
Write-Host "5. Set up environment protection rules for 'prod' environment"
```

### Step 7: Test GitHub Actions Workflow

```powershell
# Commit and push your changes to trigger workflows
Write-Host "Committing infrastructure changes..." -ForegroundColor Green

# Stage all changes
git add .

# Commit changes
git commit -m "🚀 Implement database permissions and GitHub Actions CI/CD

✅ Features:
- Relaxed database permission model for schema evolution
- Environment-specific configurations (NPE/Production)
- Complete GitHub Actions CI/CD pipeline
- Manual deployment controls with approval gates
- Database user management (app, admin, readonly)
- Terraform modules for infrastructure as code

🔐 Security:
- SSL-enforced database connections  
- Cloud SQL Proxy support
- Secret Manager integration
- Environment protection rules"

# Push to repository
git push origin main

Write-Host "Changes pushed! Check GitHub Actions tab for workflow execution." -ForegroundColor Green
```

### Step 8: Deploy to Production (When Ready)

```powershell
# Use GitHub Actions workflow dispatch for production deployment
Write-Host "Production Deployment:" -ForegroundColor Red
Write-Host "1. Go to GitHub Actions tab"
Write-Host "2. Select 'Promote NPE to Production' workflow"
Write-Host "3. Click 'Run workflow'"
Write-Host "4. Type 'PROMOTE' in confirmation field"
Write-Host "5. Configure options and click 'Run workflow'"
Write-Host ""
Write-Host "OR deploy manually:"
Write-Host ""
Write-Host "terraform init -backend-config=\"environments/prod/backend.tf\" -reconfigure"
Write-Host "terraform plan -var-file=\"environments/prod/terraform.tfvars\" -out=prod-plan"
Write-Host "terraform apply prod-plan"
```

### Step 9: Verify Deployment

```powershell
# Run infrastructure tests
Write-Host "Testing infrastructure..." -ForegroundColor Green
./test-npe-infrastructure.ps1

# Check all resources are created
Write-Host "Verifying resources..." -ForegroundColor Cyan

# VPC
gcloud compute networks describe fincore-npe-vpc --project=$env:PROJECT_ID

# Cloud SQL
gcloud sql instances describe fincore-npe-db --project=$env:PROJECT_ID

# Storage buckets
gcloud storage buckets list | Select-String "fincore-npe"

# Service accounts
gcloud iam service-accounts list | Select-String "fincore"
```

### Step 10: Next Steps - Application Deployment

Once infrastructure is ready:

```powershell
Write-Host "Next Steps for Application Deployment:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Build and push User Management API container:"
Write-Host "   cd c:\Development\git\userManagementApi"
Write-Host "   docker build -t gcr.io/$env:PROJECT_ID/fincore-api:latest ."
Write-Host "   docker push gcr.io/$env:PROJECT_ID/fincore-api:latest"
Write-Host ""
Write-Host "2. Enable Cloud Run in terraform/environments/npe/terraform.tfvars:"
Write-Host "   enable_cloud_run = true"
Write-Host ""
Write-Host "3. Apply the configuration:"
Write-Host "   terraform apply -var-file=\"environments/npe/terraform.tfvars\""
Write-Host ""
Write-Host "4. Test the deployed API:"
Write-Host "   curl https://your-api-url/actuator/health"
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions:

**1. Authentication Issues**
```powershell
# Re-authenticate if needed
gcloud auth application-default login --force
gcloud config set project $env:PROJECT_ID
```

**2. API Not Enabled Errors**
```powershell
# Enable missing API (replace with actual API name from error)
gcloud services enable [API_NAME] --project=$env:PROJECT_ID
```

**3. Permission Denied Errors**
```powershell
# Check current user permissions
gcloud auth list
gcloud projects get-iam-policy $env:PROJECT_ID
```

**4. Terraform State Lock**
```powershell
# If deployment fails with lock error
terraform force-unlock [LOCK_ID]
```

**5. Database Connection Issues**
```powershell
# Test database connectivity
gcloud sql connect fincore-npe-db --user=root --project=$env:PROJECT_ID
```

---

## 📋 Verification Checklist

After successful deployment, verify:

- [ ] ✅ All GCP APIs are enabled
- [ ] ✅ VPC network is created
- [ ] ✅ Cloud SQL instance is running
- [ ] ✅ Database permissions are configured
- [ ] ✅ Storage buckets are created
- [ ] ✅ Service accounts have correct roles
- [ ] ✅ GitHub Actions workflows are set up
- [ ] ✅ Environment protection rules are configured
- [ ] ✅ Infrastructure tests pass

---

## 🎉 Success!

Your Fincore infrastructure with relaxed database permissions is now ready for development and production use. The GitHub Actions CI/CD pipeline will handle future deployments with proper approval gates and testing.

**Database Permission Model Applied:**
- ✅ **Relaxed permissions** for schema evolution
- ✅ **DDL operations** allowed in both NPE and Production
- ✅ **Cloud SQL Proxy** support for secure connections
- ✅ **Environment-specific** configurations
- ✅ **Admin and readonly users** for operational needs