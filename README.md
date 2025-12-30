# Fincore Infrastructure as Code

Infrastructure as Code for deploying Fincore application on Google Cloud Platform (GCP) with automated GitHub Actions CI/CD.

## 🚀 Quick Start

### Prerequisites
- GCP Project: `project-07a61357-b791-4255-a9e`
- GitHub repository with secrets configured
- Terraform ~1.6.0

### Deployment
- **NPE (Non-Production)**: Auto-deploys on push to `develop` branch
- **Production**: Manual approval required via GitHub Actions

## 📋 Overview

This repository manages database permissions and users for the Fincore Cloud SQL instance using Terraform.

**Environments:**
- **NPE**: europe-west2, auto-deploy from develop branch
- **Production**: europe-west2, manual approval required

**Database Configuration:**
- Cloud SQL Instance: `fincore-npe-db`
- Database: `fincore_db`
- Character Set: UTF8MB4 (case-insensitive)
- Collation: utf8mb4_general_ci

## 🗄️ Database
  
- **Secret Manager**
  - Database password stored securely
  - User-managed replication

- **Monitoring & Logging**
  - Cloud Logging sinks for Cloud SQL and Cloud Run
  - Alert policies (error rate >5%, P99 latency >1000ms)
  - 7-day log retention

---

## Prerequisites

### Required Tools
- Terraform >= 1.6.0
- Google Cloud SDK (gcloud CLI)
- Docker (for building container images)
- PowerShell 5.1+ or Bash (for testing scripts)

**Users:**
- `fincore_app`: Application user with full privileges (SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, INDEX, REFERENCES)
- `fincore_admin`: Admin user with all privileges including GRANT

**Features:**
- Case-insensitive table and column names (`lower_case_table_names=1`)
- UTF8MB4 character encoding
- Automated password generation stored in Secret Manager

## 🏗️ Infrastructure

### Terraform Modules
```
terraform/
├── main.tf                    # Database permissions configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output definitions
├── versions.tf                # Provider versions
├── environments/
│   ├── npe/
│   │   ├── terraform.tfvars   # NPE variables
│   │   └── backend.tf         # NPE backend config
│   └── prod/
│       ├── terraform.tfvars   # Production variables
│       └── backend.tf         # Production backend config
└── modules/
    ├── database-permissions/  # Database users and grants
    └── cloud-sql/            # Cloud SQL configuration
```

## 🔄 CI/CD Workflows

### Main Deployment (`deploy.yml`)
- Triggers on push to `terraform/**` or `.github/workflows/**`
- Auto-deploys to NPE on `develop` branch
- Manual workflow dispatch for production

**Jobs:**
1. ✅ Validate - Terraform fmt, init, validate
2. 📋 Plan - Generate execution plan
3. 🚀 Apply - Deploy infrastructure (auto for NPE, manual for prod)
4. 🔐 Deploy Permissions - Create database users
5. 🧪 Test - Run infrastructure tests

### Production Promotion (`promote.yml`)
- Manual workflow with approval required
- Requires typing "PROMOTE" to confirm
- Optional backup before deployment

### Pull Request Validation (`pr-validation.yml`)
- Runs on PRs to main/develop
- Validates Terraform without applying

## 🔐 GitHub Secrets & Variables

### Required Secrets
- `GCP_SA_KEY`: Service account JSON key for authentication

### Required Variables
- `GCP_PROJECT_ID`: `project-07a61357-b791-4255-a9e`

## 📚 Documentation

- [Implementation Guide](IMPLEMENTATION_GUIDE.md) - Step-by-step setup instructions
- [Database Migration Scripts](scripts/) - SQL scripts for migrating from my_auth_db to fincore_db

## 🛠️ Local Development

### Prerequisites
- Terraform >= 1.6.0
- gcloud CLI
- GCP authentication configured

### Run Locally
```bash
cd terraform

# Initialize
terraform init -backend-config="environments/npe/backend.tf"

# Plan
terraform plan -var-file="environments/npe/terraform.tfvars"

# Apply
terraform apply -var-file="environments/npe/terraform.tfvars"
```

### Test Infrastructure
```bash
# PowerShell
./test-npe-infrastructure.ps1

# Bash
chmod +x test-npe-infrastructure.sh
./test-npe-infrastructure.sh
```

## 🗄️ Database Migration

To migrate from `my_auth_db` to `fincore_db`:

```bash
cd scripts

# Review the migration SQL
cat migrate-to-fincore-db.sql

# Execute migration (PowerShell)
./run-database-migration.ps1

# Or use the batch file
./execute-migration.bat
```

## 📞 Support

For issues or questions:
1. Check [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)
2. Review GitHub Actions logs
3. Check Cloud SQL logs in GCP Console

---

**Project:** Fincore  
**Cloud Provider:** Google Cloud Platform  
**Region:** europe-west2 (London)  
**Managed By:** Terraform + GitHub Actions
- Artifact Registry API enabled

---

**Project:** Fincore  
**Cloud Provider:** Google Cloud Platform  
**Region:** europe-west2 (London)  
**Managed By:** Terraform + GitHub Actions  
**Last Updated:** December 30, 2025
