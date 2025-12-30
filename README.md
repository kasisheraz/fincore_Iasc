# Fincore NPE Infrastructure

Complete Infrastructure as Code (IaC) for deploying Fincore full-stack application on Google Cloud Platform (GCP) in the Non-Production Environment (NPE).

## Overview

This repository contains Terraform modules and testing scripts to deploy and validate a production-ready infrastructure in Google Cloud. The NPE environment is optimized for cost-efficiency while maintaining all necessary components for application deployment and testing.

**Status:** ✅ Infrastructure Deployed (VPC, Cloud SQL, Storage, IAM, Monitoring)  
**Region:** europe-west2 (London)  
**Cloud Provider:** Google Cloud Platform  
**Cost:** ~$22/month (within $300 free credits)

---

## Architecture

### Network & Compute
- **VPC Network** (fincore-npe-vpc)
  - Subnet: 10.0.0.0/20 in europe-west2
  - Cloud NAT for secure outbound connectivity
  - Serverless VPC Connector for Cloud Run to Cloud SQL communication
  - Private networking (no public IPs for databases)

- **Cloud Run Services** (Pending Docker images)
  - API Service: fincore-npe-api (256Mi, 0.5 CPU, max 2 instances)
  - Frontend Service: fincore-npe-frontend (256Mi, 0.5 CPU, max 2 instances)
  - Service accounts with proper IAM roles

### Data Layer
- **Cloud SQL MySQL 8.0**
  - Instance: fincore-npe-db
  - Tier: db-f1-micro (cost-optimized)
  - Database: my_auth_db
  - Users: root, fincore_app
  - Backups: 7-day retention
  - Private IP only (via VPC peering)
  - SSL required for connections

- **Cloud Storage** (3 buckets in london)
  - fincore-npe-terraform-state: Terraform remote state
  - fincore-npe-artifacts: Built artifacts and deployment packages
  - fincore-npe-uploads: User uploads with lifecycle policies

### Security & Monitoring
- **Service Accounts**
  - fincore-npe-cloudrun: Cloud Run service principal
  - fincore-npe-secrets: Secret Manager access
  
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

### GCP Setup
- Active GCP project: `fincore-npe-proj` (ID: `project-07a61357-b791-4255-a9e`)
- Billing account with $300 free credits activated
- Required APIs enabled:
  - Compute Engine API
  - Cloud Run API
  - Cloud SQL Admin API
  - Cloud Storage API
  - Secret Manager API
  - Cloud Logging API
  - Cloud Monitoring API
  - Service Networking API
  - VPC Access API
  - Cloud Build API

### Authentication
```bash
gcloud auth application-default login
gcloud config set project project-07a61357-b791-4255-a9e
```

---

## Directory Structure

```
fincore_Iasc/
├── README.md                           # This file
├── fincore_Iasc.md                    # Detailed architecture documentation
├── test-npe-infrastructure.ps1        # PowerShell infrastructure validation script
├── test-npe-infrastructure.sh         # Bash infrastructure validation script
└── terraform/
    ├── versions.tf                    # Provider versions (GCP, Random)
    ├── variables.tf                   # Input variables
    ├── main.tf                        # Module orchestration
    ├── outputs.tf                     # Output definitions
    ├── backend.tf                     # GCS remote state configuration
    ├── terraform.tfvars              # Default variables (deprecated)
    ├── environments/
    │   └── npe/
    │       ├── terraform.tfvars      # NPE-specific variables
    │       ├── backend.tf            # NPE backend config
    │       └── .terraform.lock.hcl   # Dependency lock file
    └── modules/
        ├── vpc/                      # VPC, subnets, NAT, connectors
        ├── cloud-sql/                # MySQL database, users, backups
        ├── storage/                  # GCS buckets, lifecycle policies
        ├── cloud-run/                # Cloud Run services
        ├── load-balancer/            # Application Load Balancer (disabled for NPE)
        ├── security/                 # IAM, service accounts, secrets
        ├── monitoring/               # Logging sinks, alert policies
        └── dns/                      # Cloud DNS (optional)
```

---

## Deployment Status

### ✅ Completed
- VPC network with all networking components
- Cloud SQL MySQL 8.0 instance (14+ minute creation)
- Cloud Storage buckets with versioning and lifecycle policies
- Service accounts and IAM role bindings
- Secret Manager password storage
- Monitoring, logging, and alert policies
- Terraform remote state in GCS

### ⏳ Pending
- Docker images for API and Frontend services
- Cloud Run service deployment
- End-to-end integration testing
- Performance baseline testing

---

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform
terraform init -backend-config="environments/npe/backend.tf"
```

### 2. Review Deployment Plan

```bash
terraform plan -var-file="environments/npe/terraform.tfvars"
```

### 3. Apply Infrastructure

```bash
terraform apply -var-file="environments/npe/terraform.tfvars"
```

This will deploy:
- VPC network and related networking resources
- Cloud SQL instance (takes ~15 minutes)
- Storage buckets
- Service accounts and IAM roles
- Monitoring and logging infrastructure

### 4. Test Infrastructure

#### PowerShell (Windows)
```powershell
./test-npe-infrastructure.ps1
```

#### Bash (Linux/Mac)
```bash
chmod +x test-npe-infrastructure.sh
./test-npe-infrastructure.sh
```

Both scripts validate:
- VPC network and subnets
- Cloud SQL instance and databases
- Storage buckets
- Service accounts and IAM roles
- Monitoring and logging
- Cloud Run services (when deployed)

---

## Building and Deploying Container Images

### Prerequisites
- Docker installed and running
- gcloud CLI authenticated
- Artifact Registry API enabled

### Build and Push Images

```bash
# Build API image
docker build -t gcr.io/project-07a61357-b791-4255-a9e/fincore-api:latest ./api
docker push gcr.io/project-07a61357-b791-4255-a9e/fincore-api:latest

# Build Frontend image
docker build -t gcr.io/project-07a61357-b791-4255-a9e/fincore-frontend:latest ./frontend
docker push gcr.io/project-07a61357-b791-4255-a9e/fincore-frontend:latest
```

### Deploy Cloud Run Services

```bash
terraform apply -var-file="environments/npe/terraform.tfvars" -auto-approve
```

This will deploy:
- API service at `fincore-npe-api-xxxxx.run.app`
- Frontend service at `fincore-npe-frontend-xxxxx.run.app`

---

## Accessing Services

### Cloud SQL
```bash
# Get instance connection name
gcloud sql instances describe fincore-npe-db --format='value(connectionName)'

# Connect via Cloud SQL Proxy (requires proxy installation)
cloud-sql-proxy project-07a61357-b791-4255-a9e:europe-west2:fincore-npe-db &
mysql -h 127.0.0.1 -u root -p
```

### Cloud Storage
```bash
# List buckets
gcloud storage buckets list

# Upload file
gcloud storage cp myfile.txt gs://fincore-npe-uploads/

# Download file
gcloud storage cp gs://fincore-npe-uploads/myfile.txt .
```

### Cloud Run
```bash
# Get service URL
gcloud run services describe fincore-npe-api --region=europe-west2 --format='value(status.url)'

# Test health endpoint
curl https://fincore-npe-api-xxxxx.run.app/health
```

---

## Monitoring & Logging

### View Logs
```bash
# Cloud SQL logs
gcloud logging read 'resource.type=cloudsql_database' --limit=10

# Cloud Run logs
gcloud logging read 'resource.type=cloud_run_revision' --limit=10

# Error logs only
gcloud logging read 'severity=ERROR' --limit=10
```

### Check Metrics
```bash
# Cloud SQL CPU usage
gcloud monitoring metrics-descriptors list --filter="metric.type:cloudsql*"

# Cloud Run request count
gcloud monitoring time-series list --filter='metric.type="run.googleapis.com/request_count"'
```

---

## Cost Optimization

### Current NPE Configuration
- **Cloud Run:** $0/month (0 requests) → Variable based on usage
- **Cloud SQL:** ~$6/month (db-f1-micro tier)
- **Storage:** ~$0-2/month (standard class with lifecycle policies)
- **Load Balancer:** $0/month (disabled for NPE)
- **Total Estimated:** ~$22/month

### Cost Reduction Measures Applied
1. Cloud SQL: db-f1-micro tier (smallest available)
2. Cloud Run: Max 2 instances (reduced from 10)
3. Cloud Run: 256Mi memory, 0.5 CPU
4. Load Balancer: Disabled ($18/month savings)
5. Storage: Lifecycle policies (auto-archive old uploads)
6. Backups: 7-day retention (not indefinite)

### Monitor Costs
```bash
# View billing information
gcloud billing accounts list
gcloud billing budgets list --billing-account=BILLING_ACCOUNT_ID

# Open GCP Console
gcloud console billing
```

---

## Configuration Files

### Environment Variables (terraform.tfvars)
```hcl
# NPE-specific configuration
project_id = "project-07a61357-b791-4255-a9e"
region = "europe-west2"
environment = "npe"

# Compute sizing
cloud_run_memory = 256
cloud_run_cpu = "0.5"
cloud_run_max_instances = 2
cloud_sql_tier = "db-f1-micro"

# Features
enable_load_balancer = false
enable_dns = false
```

### Backend Configuration (backend.tf)
```hcl
terraform {
  backend "gcs" {
    bucket = "fincore-npe-terraform-state"
    prefix = "npe"
    region = "europe-west2"
  }
}
```

---

## Troubleshooting

### Terraform Lock Conflicts
```bash
# Remove lock if deployment fails
terraform force-unlock [LOCK_ID]
```

### Cloud SQL Connection Issues
- Verify Serverless VPC Connector is ready: `gcloud compute vpc-access connectors describe npe-connector --region=europe-west2`
- Check Cloud SQL private IP configuration
- Verify IAM: Cloud Run service account must have `roles/cloudsql.client`

### Cloud Run Deployment Failures
- Check image exists: `gcloud container images list`
- Review Cloud Run logs: `gcloud logging read 'resource.type=cloud_run_revision'`
- Verify environment variables are set correctly

### Storage Access Issues
- Check bucket permissions: `gsutil iam ch` 
- Verify service account has Storage Object Admin role
- Check CORS configuration for uploads bucket

---

## Next Steps

1. **Build Docker Images**
   - Create Dockerfile for API service
   - Create Dockerfile for Frontend service
   - Push to gcr.io registry

2. **Deploy Cloud Run Services**
   - Run terraform apply to deploy services
   - Verify endpoints are accessible
   - Test API health checks

3. **Configure Monitoring**
   - Set up custom dashboards
   - Configure alert channels (email, Slack, etc.)
   - Add service-level indicators (SLI)

4. **Production Readiness**
   - Test disaster recovery procedures
   - Performance load testing
   - Security penetration testing
   - Cost forecasting

5. **CI/CD Integration**
   - Connect Cloud Build to GitHub
   - Automate Docker image builds
   - Set up automated testing pipeline
   - Implement blue-green deployments

---

## Documentation

- [Detailed Architecture](./fincore_Iasc.md) - Comprehensive infrastructure design
- [Test Scripts](./test-npe-infrastructure.ps1) - Infrastructure validation (PowerShell)
- [Test Scripts](./test-npe-infrastructure.sh) - Infrastructure validation (Bash)
- [Terraform Modules](./terraform/modules) - Module documentation in each subdirectory

---

## Support & Troubleshooting

For issues or questions:
1. Check test script output: `./test-npe-infrastructure.ps1`
2. Review Terraform state: `terraform state show`
3. Check GCP Console for resource status
4. Review application logs: `gcloud logging read`

---

## License

All infrastructure code is proprietary to Fincore.

---

**Last Updated:** December 15, 2025  
**Environment:** NPE (Non-Production)  
**Region:** europe-west2 (London)  
**Status:** Production-Ready Infrastructure

<!-- Deployment trigger -->
