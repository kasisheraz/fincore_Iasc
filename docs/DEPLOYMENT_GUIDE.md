# Fincore Deployment Guide

Complete guide for deploying Fincore infrastructure to GCP.

## Prerequisites

### Required Software
- Terraform >= 1.6.0
- gcloud CLI
- Git

### Required Access
- GCP Project: `project-07a61357-b791-4255-a9e`
- Service Account: `fincore-github-actions@project-07a61357-b791-4255-a9e.iam.gserviceaccount.com`
- Service account key file: `gcp-sa-key.json`

## Initial Setup

### 1. Clone Repository
```bash
git clone https://github.com/kasisheraz/fincore_Iasc.git
cd fincore_Iasc
```

### 2. Configure GCP Authentication
```powershell
# Set environment variable
$env:GOOGLE_APPLICATION_CREDENTIALS = "$(Get-Location)\gcp-sa-key.json"

# Activate service account
gcloud auth activate-service-account `
  fincore-github-actions@project-07a61357-b791-4255-a9e.iam.gserviceaccount.com `
  --key-file=gcp-sa-key.json `
  --project=project-07a61357-b791-4255-a9e

# Verify authentication
gcloud config list
```

### 3. Initialize Terraform
```powershell
cd terraform

# Initialize with backend
terraform init `
  -backend-config="bucket=fincore-npe-terraform-state" `
  -backend-config="prefix=npe"
```

## NPE Deployment

### Deploy Database Permissions

```powershell
# Review planned changes
terraform plan -var-file='environments/npe/terraform.tfvars'

# Apply database permissions and secrets
terraform apply -var-file='environments/npe/terraform.tfvars' `
  -target='module.database_permissions' `
  -target='random_password.fincore_app_password' `
  -target='random_password.fincore_admin_password' `
  -target='google_secret_manager_secret.fincore_app_password' `
  -target='google_secret_manager_secret.fincore_admin_password' `
  -target='google_secret_manager_secret_version.fincore_app_password' `
  -target='google_secret_manager_secret_version.fincore_admin_password'
```

### Create Database

```bash
# Create fincore_db with case-insensitive collation
gcloud sql databases create fincore_db \
  --instance=fincore-npe-db \
  --charset=utf8mb4 \
  --collation=utf8mb4_general_ci \
  --project=project-07a61357-b791-4255-a9e
```

### Create Users

Retrieve generated passwords:
```bash
# Get app password
gcloud secrets versions access 1 --secret="fincore-npe-app-password"

# Get admin password
gcloud secrets versions access 1 --secret="fincore-npe-admin-password"
```

Create users:
```bash
# Create fincore_app user
gcloud sql users create fincore_app \
  --instance=fincore-npe-db \
  --password='<APP_PASSWORD>' \
  --host='%' \
  --project=project-07a61357-b791-4255-a9e

# Create fincore_admin user
gcloud sql users create fincore_admin \
  --instance=fincore-npe-db \
  --password='<ADMIN_PASSWORD>' \
  --host='%' \
  --project=project-07a61357-b791-4255-a9e
```

### Grant Privileges

Execute the SQL commands in [scripts/grant-privileges-only.sql](../scripts/grant-privileges-only.sql) via:
- GCP Console → Cloud SQL → fincore-npe-db → Query tab
- Or use Cloud SQL Proxy with MySQL client

## Production Deployment

### 1. Switch to Production Backend
```powershell
cd terraform
terraform init -reconfigure `
  -backend-config="bucket=fincore-prod-terraform-state" `
  -backend-config="prefix=prod"
```

### 2. Deploy with Production Variables
```powershell
terraform plan -var-file='environments/prod/terraform.tfvars'
terraform apply -var-file='environments/prod/terraform.tfvars'
```

### 3. Follow same database/user creation steps as NPE

## Verification

### Check Deployed Resources

```bash
# List databases
gcloud sql databases list --instance=fincore-npe-db

# List users
gcloud sql users list --instance=fincore-npe-db

# Check secrets
gcloud secrets list --filter="name:fincore-npe"

# View Terraform state
terraform state list
```

### Verify Database Configuration

Connect to database and run:
```sql
-- Check database collation
SELECT SCHEMA_NAME, DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME 
FROM INFORMATION_SCHEMA.SCHEMATA 
WHERE SCHEMA_NAME = 'fincore_db';

-- Verify users
SELECT user, host FROM mysql.user 
WHERE user IN ('fincore_app', 'fincore_admin');

-- Check privileges
SHOW GRANTS FOR 'fincore_app'@'%';
SHOW GRANTS FOR 'fincore_admin'@'%';
```

## Rollback Procedures

### Rollback Database Changes
```bash
# Remove users
gcloud sql users delete fincore_app --instance=fincore-npe-db --host='%'
gcloud sql users delete fincore_admin --instance=fincore-npe-db --host='%'

# Remove database
gcloud sql databases delete fincore_db --instance=fincore-npe-db
```

### Rollback Terraform
```powershell
# Destroy specific resources
terraform destroy -var-file='environments/npe/terraform.tfvars' `
  -target='module.database_permissions'

# Or rollback to previous state
terraform state pull > backup.tfstate
# Manually edit and push back if needed
```

## Troubleshooting

### Issue: MySQL Provider Connection Failed
**Cause:** Service account lacks direct MySQL root access  
**Solution:** Use `gcloud sql` commands or GCP Console for database operations

### Issue: GitHub Actions Authentication Failed
**Cause:** Workflow-specific secret access issue  
**Solution:** Deploy locally using service account key

### Issue: IPv6 Connection Error
**Cause:** Cloud SQL doesn't support IPv6 direct connections  
**Solution:** Use Cloud SQL Proxy:
```powershell
# Download Cloud SQL Proxy
Invoke-WebRequest -Uri "https://dl.google.com/cloudsql/cloud_sql_proxy_x64.exe" `
  -OutFile "cloud-sql-proxy.exe"

# Start proxy
.\cloud-sql-proxy.exe project-07a61357-b791-4255-a9e:europe-west2:fincore-npe-db
```

### Issue: Terraform State Locked
**Cause:** Previous operation didn't complete  
**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

## Best Practices

1. **Always backup before production changes**
   ```bash
   gcloud sql backups create --instance=fincore-npe-db
   ```

2. **Use targeted applies when possible**
   - Reduces blast radius of changes
   - Faster deployments

3. **Store sensitive data in Secret Manager**
   - Never commit passwords to Git
   - Use Secret Manager for all credentials

4. **Test in NPE before production**
   - Full deployment testing
   - Verify all functionality

5. **Keep Terraform state secure**
   - GCS buckets with versioning enabled
   - Limited access permissions

---

**Last Updated:** December 30, 2025  
**Maintained By:** Fincore Infrastructure Team
