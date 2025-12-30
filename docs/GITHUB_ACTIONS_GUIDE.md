# Fincore GitHub Actions CI/CD Implementation Guide

## Overview

This repository now includes a comprehensive GitHub Actions CI/CD pipeline for deploying Fincore infrastructure from NPE (Non-Production Environment) to Production with manual approval gates and comprehensive validation.

## 🚀 Features

### 1. **Automated Infrastructure Deployment**
- **Environment-specific deployments** (NPE/Production)
- **Manual workflow dispatch** with configurable options
- **Automatic deployments** on main branch push
- **Database permissions management** as separate module

### 2. **Comprehensive Validation**
- **Terraform validation** (format, validate, plan)
- **Security scanning** for sensitive data
- **Documentation consistency** checks
- **Infrastructure testing** after deployment

### 3. **Production Safety**
- **Manual confirmation** required for production deployments
- **Automatic database backups** before production changes
- **Environment protection** rules
- **Rollback capabilities**

## 📁 Repository Structure

```
.github/
├── workflows/
│   ├── deploy.yml          # Main deployment workflow
│   ├── promote.yml         # NPE to Production promotion
│   └── pr-validation.yml   # Pull request validation
│
terraform/
├── environments/
│   ├── npe/
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── terraform.tfvars
│       └── backend.tf
│
└── modules/
    └── database-permissions/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── README.md
```

## 🔧 Setup Instructions

### 1. **GitHub Repository Configuration**

#### Required Secrets:
```bash
# GCP Service Account Key (JSON)
GCP_SA_KEY='{
  "type": "service_account",
  "project_id": "project-07a61357-b791-4255-a9e",
  "private_key_id": "...",
  "private_key": "...",
  ...
}'
```

#### Required Variables:
```bash
GCP_PROJECT_ID=project-07a61357-b791-4255-a9e
```

#### Environment Protection Rules:
1. Go to **Settings** → **Environments**
2. Create environments: `npe` and `prod`
3. For **production**:
   - Enable "Required reviewers"
   - Add team members as reviewers
   - Set deployment timeout (optional)

### 2. **Service Account Permissions**

The GitHub Actions service account needs these IAM roles:
```bash
# Core infrastructure management
roles/compute.admin
roles/cloudsql.admin
roles/storage.admin
roles/iam.serviceAccountAdmin
roles/iam.serviceAccountUser

# Cloud Run and networking
roles/run.admin
roles/compute.networkAdmin
roles/vpcaccess.admin

# Monitoring and logging
roles/logging.admin
roles/monitoring.admin

# Secret Manager
roles/secretmanager.admin

# Service account key management
roles/iam.serviceAccountKeyAdmin
```

### 3. **Terraform Backend Setup**

Ensure GCS buckets exist for Terraform state:
```bash
# Create NPE state bucket
gsutil mb gs://fincore-npe-terraform-state

# Create Production state bucket  
gsutil mb gs://fincore-prod-terraform-state

# Enable versioning
gsutil versioning set on gs://fincore-npe-terraform-state
gsutil versioning set on gs://fincore-prod-terraform-state
```

## 🚀 Deployment Workflows

### 1. **Manual Deployment (`deploy.yml`)**

**Trigger:** Manual workflow dispatch

**Options:**
- **Environment**: NPE or Production
- **Action**: Plan, Apply, or Destroy
- **Deploy Permissions**: Enable/disable database permissions
- **Run Tests**: Enable/disable infrastructure tests
- **Auto Approve**: Auto-approve applies (use with caution)

**Usage:**
1. Go to **Actions** → **Fincore Infrastructure Deployment**
2. Click **Run workflow**
3. Select options and click **Run workflow**

### 2. **NPE to Production Promotion (`promote.yml`)**

**Trigger:** Manual workflow dispatch

**Features:**
- **Confirmation required**: Must type "PROMOTE" to proceed
- **Automatic backup**: Creates database backup before deployment
- **Environment verification**: Validates NPE environment exists
- **Production testing**: Optional infrastructure tests

**Usage:**
1. Go to **Actions** → **Promote NPE to Production**
2. Click **Run workflow**
3. Type "PROMOTE" in confirmation field
4. Configure options and click **Run workflow**

### 3. **Pull Request Validation (`pr-validation.yml`)**

**Trigger:** Pull requests to main/develop branches

**Validates:**
- Terraform formatting and syntax
- Security configurations
- Documentation updates
- Plan generation for both environments

## 🔐 Database Permissions Module

### Implementation

The database permissions are managed through a dedicated Terraform module:

```hcl
# In your main Terraform configuration
module "database_permissions" {
  source = "./modules/database-permissions"

  # Database connection
  database_endpoint = module.cloud_sql.private_ip_address
  admin_password    = var.db_root_password
  
  # Application user
  app_password = var.db_app_password
  
  # Environment configuration
  environment = var.environment
  project_id  = var.project_id
  
  # Optional read-only user
  create_readonly_user = var.environment == "prod"
  readonly_password   = var.db_readonly_password
}
```

### Benefits

1. **Separation of Concerns**: Database permissions are managed independently
2. **Environment-specific**: Different configurations for NPE vs Production
3. **Security**: Passwords managed through Secret Manager integration
4. **Flexibility**: Can be deployed separately or with infrastructure

### Usage in Workflows

```yaml
- name: 🔐 Deploy Database Permissions
  run: |
    cd terraform
    terraform apply \
      -target=module.database_permissions \
      -var-file="environments/${{ env.ENVIRONMENT }}/terraform.tfvars" \
      -auto-approve
```

## 🧪 Testing Strategy

### Infrastructure Tests

The repository includes comprehensive infrastructure testing:

```bash
# NPE Environment
./test-npe-infrastructure.sh

# Production Environment (generated dynamically)
sed 's/npe/prod/g' test-npe-infrastructure.sh > test-prod-infrastructure.sh
./test-prod-infrastructure.sh
```

### Validation Checks

1. **VPC and Networking**
2. **Cloud SQL Connectivity**
3. **Storage Buckets**
4. **Service Accounts and IAM**
5. **Cloud Run Services** (when deployed)
6. **Database Permissions**

## 📊 Monitoring and Logging

### Workflow Insights

Each workflow provides detailed summaries:

- **Deployment status** and timestamps
- **Resource changes** applied
- **Test results** and validation status
- **Error details** and troubleshooting hints

### GitHub Actions Artifacts

- **Terraform plans** (retained for 5 days)
- **Test outputs** and logs
- **Backup confirmations**

## 🔄 Best Practices

### 1. **Environment Promotion Flow**

```
Feature Branch → PR → NPE Deployment → Testing → Production Promotion
```

### 2. **Security Considerations**

- **Never commit secrets** to repository
- **Use Secret Manager** for database passwords
- **Enable branch protection** on main branch
- **Require PR reviews** before merging

### 3. **Deployment Safety**

- **Always test in NPE** before production
- **Create backups** before production changes
- **Monitor deployments** for errors
- **Have rollback plan** ready

### 4. **Cost Management**

- **Use appropriate instance sizes** per environment
- **Enable lifecycle policies** for storage
- **Monitor billing** alerts
- **Clean up unused resources**

## 🚨 Troubleshooting

### Common Issues

1. **Terraform Lock Conflicts**
   ```bash
   terraform force-unlock <LOCK_ID>
   ```

2. **Authentication Issues**
   - Verify GCP_SA_KEY secret is valid JSON
   - Check service account permissions
   - Ensure project ID matches

3. **Backend Access Issues**
   - Verify state buckets exist
   - Check bucket permissions
   - Validate backend configuration

4. **Database Connection Issues**
   - Check VPC connectivity
   - Verify Cloud SQL private IP
   - Validate service account permissions

### Getting Help

1. **Check workflow logs** in GitHub Actions
2. **Review Terraform plans** before applying
3. **Run infrastructure tests** to validate deployments
4. **Check GCP Console** for resource status

## 📈 Next Steps

1. **Container Deployment**
   - Add Docker image build workflows
   - Integrate Cloud Run deployment
   - Set up health checks

2. **Advanced Monitoring**
   - Custom dashboards
   - Alert policies
   - SLI/SLO definitions

3. **Disaster Recovery**
   - Backup automation
   - Recovery procedures
   - Cross-region replication

4. **Performance Optimization**
   - Load testing integration
   - Autoscaling configuration
   - Cache management

This implementation provides a robust, secure, and maintainable CI/CD pipeline for your Fincore infrastructure while following best practices for cloud deployments and database security.