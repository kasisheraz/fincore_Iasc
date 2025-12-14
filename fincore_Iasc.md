# Fincore Infrastructure As Code (IaC)

## Overview

This repository contains the complete Infrastructure as Code (IaC) configuration for deploying a full-stack microservices application on Google Cloud Platform (GCP). The design follows a structured approach to manage infrastructure through code, enabling consistent, reproducible deployments across NPE (Non-Production Environment) and Production environments.

---

## 1. Architecture Components

### 1.1 Network & Security Layer

* **VPC Network** (Virtual Private Cloud)
  * Single VPC for NPE environment
  * Custom subnets for Cloud Run and Cloud SQL
  * Cloud NAT for secure outbound connectivity

### 1.2 Load Balancing & DNS

* **Global Application Load Balancer (GCLB)**
  * SSL/TLS termination with managed certificates
  * Health checks for backend services
  * URL-based routing policies

* **Cloud DNS**
  * DNS record management for custom domains
  * Managed SSL certificates integration

* **Serverless NEG (Network Endpoint Group)**
  * Cloud Run services as backends
  * Automatic service discovery

### 1.3 Compute Layer

* **Cloud Run Services**
  * Backend API services (containerized microservices)
  * Frontend web application (static or SSR)
  * Worker services (async job processing)
  * Service-to-service communication through service accounts
  * Memory: 512MB to 8GB (configurable)
  * CPU: Allocated based on concurrency settings
  * Auto-scaling based on traffic

### 1.4 Data Layer

* **Cloud SQL**
  * MySQL instance
  * Database name: `my_auth_db` (and application databases)
  * Automated backups with point-in-time recovery for Production only
  * Cloud SQL Proxy for secure connections
  * Private IP connectivity (via VPC)

* **Cloud Storage**
  * Buckets for application artifacts
  * Terraform state files storage (with versioning & locking)
  * User-uploaded files and media assets

### 1.5 Caching & Performance

* **Cloud CDN**
  * Content delivery for static assets
  * Integration with Load Balancer

### 1.6 Message Queue & Async Processing

* **Cloud Tasks**
  * Scheduled job execution
  * Task queues for background processing
  * Retry policies and rate limiting

### 1.7 Monitoring & Logging

* **Cloud Logging**

  * Centralized log aggregation
  * Application, infrastructure, and security logs
  * Log routing and filtering
* **Cloud Monitoring (Stackdriver)**

  * Metrics collection and visualization
  * Custom dashboards
  * Alert policies for anomalies
* **Cloud Trace**

  * Distributed tracing for microservices
  * Performance bottleneck identification
* **Cloud Audit Logs**

  * Compliance and security auditing
  * Admin activity, data access, and system events

### 1.8 Security & Identity

* **Cloud Identity & Access Management (IAM)**
  * Service accounts for component authentication
  * Role-based access control (RBAC)

* **Secret Manager**
  * Secure storage of API keys, passwords, credentials
  * Audit logging of secret access

* **Service Accounts**
  * Cloud Run service accounts
  * Cloud SQL client service accounts
  * Storage access service accounts

### 1.9 CI/CD Pipeline

* **Cloud Build**
  * Automated builds from source repositories
  * Container image creation and storage

* **Artifact Registry**
  * Private container image repository
  * Integration with Cloud Build

---

## 2. Repository Structure

```
fincore-iac/
├── README.md                           # Project overview and setup guide
├── terraform/
│   ├── main.tf                        # Primary Terraform configuration
│   ├── variables.tf                   # Variable definitions
│   ├── outputs.tf                     # Output definitions
│   ├── versions.tf                    # Terraform and provider versions
│   ├── backend.tf                     # Remote state configuration
│   ├── terraform.tfvars               # (Gitignored) Local overrides
│   ├── modules/
│   │   ├── vpc/                       # VPC & networking module
│   │   ├── cloud-run/                 # Cloud Run services module
│   │   ├── cloud-sql/                 # Cloud SQL module
│   │   ├── load-balancer/             # Load balancing module
│   │   ├── storage/                   # Cloud Storage module
│   │   ├── monitoring/                # Monitoring & logging module
│   │   ├── security/                  # IAM & Secret Manager module
│   │   └── dns/                       # Cloud DNS module
│   ├── environments/
│   │   └── npe/
│   │       ├── terraform.tfvars       # NPE environment variables
│   │       ├── backend.tf             # NPE state backend config
│   │       └── provider.tf            # NPE provider configuration
│   └── scripts/
│       ├── init.sh                    # Initialize Terraform
│       ├── plan.sh                    # Generate execution plans
│       ├── apply.sh                   # Apply infrastructure changes
│       └── validate.sh                # Validate configuration
├── docker/
│   ├── Dockerfile.api                 # API service Dockerfile
│   ├── Dockerfile.frontend            # Frontend service Dockerfile
│   └── .dockerignore
├── cloudbuild.yaml                    # Cloud Build CI/CD configuration
├── monitoring/
│   ├── dashboards.json                # Cloud Monitoring dashboards
│   └── alert-policies.yaml            # Alert policy definitions
├── .github/
│   └── workflows/
│       └── deploy-npe.yml             # NPE deployment workflow
├── docs/
│   ├── ARCHITECTURE.md                # Detailed architecture documentation
│   ├── DEPLOYMENT.md                  # Deployment procedures
│   └── TROUBLESHOOTING.md             # Common issues and fixes
└── .gitignore
```

---

## 3. Environment-Specific Configuration

### 3.1 NPE Environment (`npe/terraform.tfvars`)

```hcl
project_id          = "fincore-npe-proj"
region              = "us-central1"
environment_name    = "npe"
enable_ha           = false
cloud_run_memory    = "256Mi"
cloud_run_cpu       = "0.5"
cloud_sql_tier      = "db-f1-micro"
enable_monitoring   = true
log_retention_days  = 7
```

**Note:** For Production, these values will be increased (2Gi memory, 2 CPU, db-standard-4, etc.)

---

## 4. Step-by-Step Deployment Plan for GCP (NPE Focus)

### Phase 1: Pre-Deployment Setup (1-2 hours)

#### Step 1.1: GCP Project Setup
- [ ] Create GCP Project for NPE environment (`fincore-npe-proj`)
- [ ] Enable billing on the project
- [ ] Obtain project ID and billing account ID

#### Step 1.2: Enable Required APIs
```bash
gcloud services enable compute.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage-api.googleapis.com
gcloud services enable dns.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
```

#### Step 1.3: Setup Local Development Environment
- [ ] Install Terraform (v1.5+)
- [ ] Install Google Cloud SDK
- [ ] Install Docker
- [ ] Authenticate: `gcloud auth application-default login`
- [ ] Set project: `gcloud config set project fincore-npe-proj`

#### Step 1.4: Setup Terraform State Management
- [ ] Create GCS bucket for Terraform state: `gs://fincore-npe-terraform-state`
- [ ] Enable versioning on the bucket
- [ ] Configure backend.tf for state storage

#### Step 1.5: Create Service Accounts & IAM Roles
- [ ] Create `terraform-sa@fincore-npe-proj.iam.gserviceaccount.com` service account
- [ ] Grant necessary roles:
  - `roles/compute.admin`
  - `roles/cloudsql.admin`
  - `roles/run.admin`
  - `roles/storage.admin`
  - `roles/iam.serviceAccountAdmin`
  - `roles/secretmanager.admin`
  - `roles/dns.admin`
- [ ] Create and download service account key for local Terraform execution

#### Step 1.6: Prepare Application Code
- [ ] Containerize backend API services (create Dockerfile.api)
- [ ] Containerize frontend application (create Dockerfile.frontend)
- [ ] Setup Artifact Registry repositories:
  - `fincore-api`
  - `fincore-frontend`
- [ ] Build and push initial container images

---

### Phase 2: Infrastructure-as-Code Development (2-3 days)

#### Step 2.1: VPC & Network Setup
- [ ] Create VPC module with:
  - Custom VPC network
  - Subnets for Cloud Run and Cloud SQL
  - Firewall rules (ingress/egress)
  - Cloud NAT for outbound connectivity
- [ ] Test module: `terraform plan -module=vpc`

#### Step 2.2: Cloud SQL Database Setup
- [ ] Create Cloud SQL module with:
  - MySQL instance (db-f1-micro for NPE)
  - Database initialization scripts
  - User creation and permissions
  - Cloud SQL Proxy for secure connectivity
  - Private IP configuration (VPC)
- [ ] Create database schema and migrations
- [ ] Test: `terraform apply -target=module.cloud_sql`

#### Step 2.3: Cloud Storage Setup
- [ ] Create storage module with:
  - Application artifacts bucket
  - User uploads bucket
  - Terraform state bucket
  - CORS configuration for frontend access
- [ ] Test: `terraform apply -target=module.storage`

#### Step 2.4: Cloud Run Services
- [ ] Create Cloud Run module with:
  - API service definition
  - Frontend service definition
  - Service account for each service
  - Environment variable configuration
  - Secret reference configuration
  - Auto-scaling policies (min: 1, max: 10 for NPE)
- [ ] Test: `terraform apply -target=module.cloud_run`

#### Step 2.5: Load Balancer & DNS
- [ ] Create load balancer module with:
  - Global application load balancer
  - Backend configuration
  - Health checks
  - SSL/TLS managed certificates
- [ ] Create DNS module with:
  - DNS zone creation
  - DNS record configuration
  - Certificate provisioning
- [ ] Test: `terraform apply -target=module.load_balancer module.dns`

#### Step 2.6: Monitoring & Logging
- [ ] Create monitoring module with:
  - Log sinks for centralized logging
  - Custom dashboards
  - Alert policies for errors and high latency
- [ ] Test: `terraform apply -target=module.monitoring`

#### Step 2.7: Security & Secrets
- [ ] Create security module with:
  - Secret Manager setup
  - IAM service accounts
  - Custom IAM roles
- [ ] Store sensitive data in Secret Manager:
  - Database passwords
  - API keys
  - OAuth secrets
- [ ] Test: `terraform apply -target=module.security`

---

### Phase 3: NPE Environment Deployment (1-2 days)

#### Step 3.1: Initial Infrastructure Deployment
```bash
cd environments/npe
terraform init -backend-config="bucket=fincore-npe-terraform-state"
terraform validate
terraform plan -out=npe.tfplan
terraform apply npe.tfplan
```
- [ ] Review outputs
- [ ] Verify resource creation in GCP Console

#### Step 3.2: Database Migration & Seeding
- [ ] Run database migration scripts:
  ```bash
  gcloud sql connect fincore-npe-db --user=root
  # Run migration scripts
  ```
- [ ] Seed test data (optional)
- [ ] Verify database connectivity

#### Step 3.3: Deploy Application Services
- [ ] Deploy backend API service
- [ ] Deploy frontend service
- [ ] Verify services are healthy via Cloud Run console

#### Step 3.4: Verify Load Balancer & DNS
- [ ] Test Load Balancer health checks
- [ ] Verify DNS resolution for custom domain
- [ ] Test HTTPS/TLS connectivity

#### Step 3.5: Smoke Testing
- [ ] Test API endpoints
- [ ] Test frontend application accessibility
- [ ] Verify database connectivity
- [ ] Verify logging and monitoring

#### Step 3.6: Configure Monitoring & Alerts
- [ ] Create custom dashboards
- [ ] Setup alert policies for:
  - High error rates
  - High latency
  - Resource utilization
- [ ] Configure log-based metrics

---

### Phase 4: CI/CD Pipeline Setup (1-2 days)

#### Step 4.1: Cloud Build Configuration
- [ ] Create `cloudbuild.yaml` with steps:
  - Code checkout
  - Run tests
  - Build container images
  - Push to Artifact Registry
  - Update Cloud Run services
- [ ] Test build pipeline with manual trigger

#### Step 4.2: GitHub Actions Setup
- [ ] Create workflow file: `deploy-npe.yml`
  - Validate Terraform on PR
  - Deploy to NPE on merge to develop
- [ ] Setup branch protection rules

#### Step 4.3: Secrets Management for CI/CD
- [ ] Store GCP service account key in GitHub Secrets
- [ ] Setup environment-specific secrets

#### Step 4.4: Test CI/CD Pipeline
- [ ] Make code change and push to trigger build
- [ ] Verify build completes successfully
- [ ] Verify Cloud Run service is updated

---

### Phase 5: Testing & Validation (1-2 days)

#### Step 5.1: Functional Testing
- [ ] Test all API endpoints
- [ ] Verify frontend functionality
- [ ] Test database operations
- [ ] Verify error handling

#### Step 5.2: Security Testing
- [ ] Verify SSL/TLS configuration
- [ ] Test IAM permissions
- [ ] Verify secret access logs
- [ ] Check Cloud Run identity and access

#### Step 5.3: Cost Optimization
- [ ] Review GCP billing reports
- [ ] Verify resource sizing is appropriate for NPE
- [ ] Setup budget alerts (e.g., $500/month)

---

### Phase 6: Preparation for Production Migration (When Ready)

When you're ready to move to production, you will:
- [ ] Create a separate GCP Project (`fincore-prod-proj`)
- [ ] Repeat steps 1.1-1.5 for production environment
- [ ] Update production/terraform.tfvars with HA settings
- [ ] Deploy production infrastructure
- [ ] Migrate data from NPE to Production
- [ ] Setup production monitoring and alerts
- [ ] Configure production CI/CD pipeline

---

## 5. Cost Optimization for NPE Environment

**Estimated Monthly Cost for NPE (us-central1):**

| Service | Sizing | Estimated Cost |
|---------|--------|-----------------|
| Cloud Run | 256Mi memory, min:1 max:10 | $5-15 |
| Cloud SQL | db-f1-micro (0.6GB RAM) | $8-12 |
| Cloud Storage | 10GB storage | $0.20 |
| Cloud Monitoring | Basic metrics | Free tier |
| Cloud Logging | 5GB logs/month | $2-5 |
| Cloud DNS | 1 zone | $0.40 |
| Load Balancer | 1 forwarding rule | $16.50 |
| **Total** | | **~$33-49/month** |

**Cost Saving Tips:**
- Use auto-scaling (scale to 0 during off-hours if no traffic)
- Set short log retention (7 days for NPE)
- Use shared Cloud SQL instance (db-f1-micro is cheapest)
- Leverage free tier limits for Cloud Monitoring
- Commit to 1-year discount for Cloud SQL (when moving to production)

---

## 6. Additional Considerations

### 6.1 Security Best Practices (Implemented)
- Private IP connectivity for Cloud SQL (via VPC)
- Secret Manager for sensitive credentials
- IAM roles with least privilege principle
- Cloud SQL Proxy for encrypted connections
- Service accounts isolation for each component

### 6.2 Backup Strategy
- **NPE:** Manual backups (optional, not critical)
- **Production:** Automated daily backups with 30-day retention

### 6.3 Documentation
- Maintain architecture diagrams
- Document deployment procedures
- Create troubleshooting guides
- Document security procedures and access controls

### 6.4 Monitoring Essentials
- API response time (p50, p95, p99)
- Error rate (4xx, 5xx)
- Cloud Run request count and latency
- Cloud SQL connections and CPU usage
- Load Balancer latency and traffic

---

## 7. Quick Start Commands

### Initialize Terraform for NPE
```bash
cd environments/npe
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
terraform init
terraform plan
terraform apply
```

### Deploy Application to Cloud Run
```bash
gcloud builds submit --config=cloudbuild.yaml
```

### View Logs
```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=fincore-api" --limit=50
```

### Scale Cloud Run Service
```bash
gcloud run services update fincore-api --max-instances=10 --region=us-central1
```

---

## 8. Next Steps After NPE is Stable

Once NPE is running stable for 2-4 weeks:

1. **Production Project Setup**
   - Create separate GCP project for production
   - Repeat infrastructure setup with HA configurations

2. **Enhanced Security for Production**
   - Enable Cloud Armor WAF rules
   - Implement automated backups with PITR
   - Add read replicas for Cloud SQL

3. **Data Migration**
   - Migrate production data to new environment
   - Verify data integrity
   - Setup continuous replication (if needed)

4. **Production Deployment**
   - Deploy with proper change management
   - Implement blue-green deployments
   - Setup enhanced monitoring and alerts

---

**Last Updated:** December 2025
**Status:** Simplified for Cost-Effective NPE Deployment
