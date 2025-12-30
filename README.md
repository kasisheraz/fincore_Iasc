# Fincore Infrastructure as Code

Infrastructure as Code for deploying Fincore application database on Google Cloud Platform (GCP).

## 🚀 Quick Start

### Prerequisites
- GCP Project: `project-07a61357-b791-4255-a9e`
- Terraform ~1.6.0
- gcloud CLI authenticated

### Current Status
✅ **Deployed to NPE Environment:**
- Cloud SQL Instance: `fincore-npe-db` (MySQL 8.0)
- Database: `fincore_db` with case-insensitive collation
- Users: `fincore_app`, `fincore_admin`
- Passwords stored in Secret Manager

## 📋 Overview

This repository manages database infrastructure for the Fincore application using Terraform.

**Environments:**
- **NPE**: europe-west2 (London)
- **Production**: europe-west2 (manual deployment)

**Database Configuration:**
- Instance: `fincore-npe-db` (MySQL 8.0.41)
- Database: `fincore_db`
- Character Set: `utf8mb4`
- Collation: `utf8mb4_general_ci` (case-insensitive)
- Lower case table names: Enabled (`lower_case_table_names=1`)

**Database Users:**
- `fincore_app@%`: Application user with full DML/DDL privileges
- `fincore_admin@%`: Admin user with all database privileges
- Passwords: Securely stored in GCP Secret Manager
  - `fincore-npe-app-password`
  - `fincore-npe-admin-password`

## 🏗️ Infrastructure

### Project Structure
```
fincore_Iasc/
├── terraform/
│   ├── main.tf                    # Main configuration
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── versions.tf                # Provider versions
│   ├── environments/
│   │   ├── npe/
│   │   │   ├── terraform.tfvars   # NPE configuration
│   │   │   └── backend.tf         # State backend
│   │   └── prod/
│   │       ├── terraform.tfvars   # Production configuration
│   │       └── backend.tf         # State backend
│   └── modules/
│       ├── database-permissions/  # User & grant management
│       ├── cloud-sql/            # Cloud SQL instance
│       ├── vpc/                  # Network configuration
│     GitHub Actions Workflows

### Deployment Workflow (`deploy.yml`)
**Triggers:**
- Push to `develop` branch → Auto-deploy to NPE
- Push to `main` branch → Deploy to Production (manual approval)
- Paths: `terraform/**`, `.github/workflows/**`

**Jobs:**
1. Validate - Terraform format, init, and validate
2. Plan - Generate execution plan
3. Apply - Deploy infrastructure
4. Deploy Permissions - Create database users and grants

### Production Promotion (`promote.yml`)
- Manual workflow with approval required
- Backup before deployment
- Confirmation step required

### PR Validation (`pr-validation.yml`)
- Runs on PRs to `main` or `develop`
- Validates Terraform configuration
- No infrastructure changes applied

> **Note:** Due to authentication issues with GitHub Actions, current deployments are done locally using service account credentials.base users
5. 🧪 Test - Run infrastructure tests

### Production Promotion (`promote.yml`)
- Manual workflow with approval required
- Requires typing "PROMOTE" to confirm
- Optional backup before deployment

### Pull Request Validation (`pr-validation.yml`)
- RunsSecurity & Credentials

### GCP Service Account
- Email: `fincore-github-actions@project-07a61357-b791-4255-a9e.iam.gserviceaccount.com`
- Key stored locally in `gcp-sa-key.json` (gitignored)

### GitHub Secrets (configured but not currently used)
- `GCP_SA_KEY`: Service account JSON key
- Variable: `GCP_PROJECT_ID`

### Database Passwords
Stored in GCP Secret Manager:
- `fincore-npe-app-password` - fincore_app user password
- `fincore-npe-admin-password` - fincore_admin user password

AcceSetup
1. **Authenticate with GCP:**
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "$(Get-Location)\gcp-sa-key.json"
gcloud auth activate-service-account --key-file=gcp-sa-key.json
gcloud config set project project-07a61357-b791-4255-a9e
```

2. **Initialize Terraform:**
```powershell
cd terraform
terraform init -backend-config="bucket=fincore-npe-terraform-state" -backend-config="prefix=npe"
```

3. **Plan and Apply:**
```powershell
# Plan changes
terraform plan -var-file='environments/npe/terraform.tfvars'

# Apply changes (target database permissions only)
terraform apply -var-file='environments/npe/terraform.tfvars' `
  -target='module.database_permissions' `
  -target='random_password.fincore_app_password' `
  -target='random_password.fincore_admin_password' `
  -target='google_secret_manager_secret.fincore_app_password' `
  -target='google_secret_manager_secret.fincore_admin_password' `
  -target='google_secret_manager_secret_version.fincore_app_password' `
  -target='google_secret_manager_secret_version.fincore_admin_password'
```

### Database Management

**Create Database:**
```bash
gcloud sql databases create fincore_db \
  --instance=fincore-npe-db \
  --charset=utf8mb4 \
  --collation=utf8mb4_general_ci
```

**Create Users:**
```bash
gcloud sql users create fincore_app --instance=fincore-npe-db --password='<password>' --host='%'
gcloud sql users create fincore_admin --instance=fincore-npe-db --password='<password>' --host='%'
```

**Grant Privileges:**
Execute [scripts/grant-privileges-only.sql](scripts/grant-privileges-only.sql) via GCP Console SQL Editor.bash
cd scripts

# Review the migration SQL
cat migrate-to-fincore-db.sql

# Execute migration (PowerShell)
./run-database-migration.ps1

# Or use the batch file
./execute-migration.bat
```

## �️ Database Information

### Connection Details
- **Host:** `34.147.230.142` (public IP) or `10.140.0.3` (private IP)
- **Port:** `3306`
- **Database:** `fincore_db`
- **Instance:** `fincore-npe-db`
- **Region:** `europe-west2`

### Available Databases
- `fincore_db` - Main application database (utf8mb4_general_ci)
- System databases: mysql, information_schema, performance_schema, sys

### Storage Buckets
- `fincore-npe-terraform-state` (EUROPE-WEST2) - Terraform state storage
- `fincore-prod-terraform-state` (US) - Production state storage
- `project-07a61357-b791-4255-a9e_cloudbuild` (US) - Cloud Build artifacts

## 🔧 Troubleshooting

### Common Issues

**Terraform MySQL Provider Connection Failed:**
- Service account lacks direct MySQL access
- Use `gcloud sql` commands or GCP Console for database operations

**GitHub Actions Authentication Failed:**
- Current workaround: Deploy locally with service account
- Secret `GCP_SA_KEY` is configured but may have workflow-specific issues

**IPv6 Connection Issues:**
- Cloud SQL doesn't support IPv6 for direct connections
- Use Cloud SQL Proxy for local development

### Useful Commands
```bash
# List databases
gcloud sql databases list --instance=fincore-npe-db

# List users
gcloud sql users list --instance=fincore-npe-db

# Check bucket contents
gcloud storage ls gs://fincore-npe-terraform-state

# View Terraform state
cd terraform && terraform state list
```

---

**Project:** Fincore Infrastructure  
**Cloud Provider:** Google Cloud Platform  
**Region:** europe-west2 (London)  
**Managed By:** Terraform  
**Last Updated:** December 30, 2025
