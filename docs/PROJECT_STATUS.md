# Project Status - Fincore Infrastructure

**Date:** December 30, 2025  
**Status:** ✅ Deployed to NPE Environment

## Deployment Summary

### Infrastructure Deployed
- ✅ Cloud SQL MySQL 8.0 Instance: `fincore-npe-db`
- ✅ Database: `fincore_db` (utf8mb4_general_ci - case-insensitive)
- ✅ Users: `fincore_app`, `fincore_admin`
- ✅ Secrets: Passwords stored in Secret Manager
- ✅ Backend: Terraform state in GCS

### Database Configuration
```
Instance:   fincore-npe-db
Region:     europe-west2 (London)
Database:   fincore_db
Charset:    utf8mb4
Collation:  utf8mb4_general_ci (case-insensitive)
Version:    MySQL 8.0.41
```

### Connection Information
```
Public IP:  34.147.230.142
Private IP: 10.140.0.3
Port:       3306
```

### Users Created
| User | Host | Purpose | Password Location |
|------|------|---------|-------------------|
| fincore_app | % | Application user | Secret Manager: fincore-npe-app-password |
| fincore_admin | % | Admin user | Secret Manager: fincore-npe-admin-password |

### Privileges Granted
Both users have full DML/DDL privileges on `fincore_db`:
- SELECT, INSERT, UPDATE, DELETE
- CREATE, DROP, INDEX, ALTER
- CREATE TEMPORARY TABLES, LOCK TABLES

## Migration Completed

### Previous State
- Database: `my_auth_db` (utf8mb4_unicode_ci)
- Users: superuser, temp_admin, root

### Current State
- Database: `fincore_db` (utf8mb4_general_ci - **case-insensitive**)
- Users: fincore_app, fincore_admin
- Old database: **DELETED** (my_auth_db removed)

### Cleanup Performed
**Removed Databases:**
- ✅ my_auth_db

**Removed Storage Buckets:**
- ✅ fincore-npe-sql-import-temp
- ✅ fincore-npe-sql-scripts

**Retained Storage:**
- ✓ fincore-npe-terraform-state (required)
- ✓ fincore-prod-terraform-state (required)
- ✓ project-07a61357-b791-4255-a9e_cloudbuild (system)

**Removed Files:**
- ✅ All legacy setup scripts
- ✅ Outdated documentation
- ✅ Temporary test files
- ✅ Migration scripts (completed)
- ✅ Old status/report files

## Current Project Structure

```
fincore_Iasc/
├── README.md                          # Main documentation
├── gcp-sa-key.json                   # Service account key (gitignored)
├── .github/workflows/
│   ├── deploy.yml                    # Main deployment workflow
│   ├── promote.yml                   # Production promotion
│   └── pr-validation.yml             # PR validation
├── docs/
│   └── DEPLOYMENT_GUIDE.md           # Complete deployment guide
├── scripts/
│   ├── create-fincore-db-users.sql   # Complete setup SQL
│   └── grant-privileges-only.sql     # Grant privileges SQL
└── terraform/
    ├── main.tf                       # Main configuration
    ├── variables.tf                  # Input variables
    ├── outputs.tf                    # Outputs
    ├── versions.tf                   # Provider versions
    ├── environments/
    │   ├── npe/
    │   │   ├── terraform.tfvars      # NPE configuration
    │   │   └── backend.tf            # NPE backend
    │   └── prod/
    │       ├── terraform.tfvars      # Prod configuration
    │       └── backend.tf            # Prod backend
    └── modules/
        ├── database-permissions/     # User management
        ├── cloud-sql/               # Instance config
        ├── vpc/                     # Network
        └── security/                # Security policies
```

## Known Issues & Workarounds

### GitHub Actions Authentication
**Issue:** Workflow fails with "must specify exactly one of 'workload_identity_provider' or 'credentials_json'"  
**Status:** Unresolved  
**Workaround:** Deploy locally using service account key  
**Impact:** Low - local deployment works reliably

### MySQL Provider Direct Connection
**Issue:** Terraform MySQL provider cannot connect directly (IPv6, permissions)  
**Status:** Expected behavior  
**Workaround:** Use `gcloud sql` commands for database operations  
**Impact:** None - workflow adjusted accordingly

## Next Steps

### For NPE Environment
- ⏸️ Grant final database privileges (execute grant-privileges-only.sql)
- ⏸️ Test application connectivity
- ⏸️ Deploy application to Cloud Run/App Engine

### For Production
- ⏸️ Review and approve production deployment plan
- ⏸️ Create production database with same configuration
- ⏸️ Configure production GitHub environment secrets
- ⏸️ Execute controlled production deployment

### GitHub Actions (Optional)
- ⏸️ Troubleshoot secret access issue
- ⏸️ Re-enable automated deployments
- ⏸️ Or continue with local deployment workflow

## Verification Checklist

✅ Database exists with correct collation  
✅ Users created successfully  
✅ Passwords stored securely in Secret Manager  
✅ Terraform state saved in GCS  
✅ Old database removed  
✅ Unnecessary buckets cleaned up  
✅ Project files organized  
✅ Documentation updated  
✅ Service account authenticated  
⏸️ Database privileges granted (pending final step)  

## Access Information

### Retrieve Passwords
```bash
# App password
gcloud secrets versions access 1 --secret="fincore-npe-app-password"

# Admin password
gcloud secrets versions access 1 --secret="fincore-npe-admin-password"
```

### Connect to Database
```bash
# Via gcloud (requires Cloud SQL Proxy if IPv6)
gcloud sql connect fincore-npe-db --user=fincore_app

# Via MySQL client through proxy
mysql -h 127.0.0.1 -P 3306 -u fincore_app -p fincore_db
```

## Support Resources

- **Main Documentation:** [README.md](../README.md)
- **Deployment Guide:** [docs/DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **GCP Console:** https://console.cloud.google.com/sql/instances/fincore-npe-db
- **GitHub Repository:** https://github.com/kasisheraz/fincore_Iasc

---

**Environment:** NPE (Non-Production)  
**Status:** Deployed & Operational  
**Last Updated:** December 30, 2025  
**Deployed By:** Local Terraform (Service Account)
