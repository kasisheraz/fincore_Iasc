# Fincore Infrastructure - Full Cloud SQL Management
# Manages Cloud SQL instance and database permissions
# Updated: 2026-01-06 - Added full instance management with case-insensitive collation

# Configure Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Get variables from tfvars
locals {
  environment   = var.environment
  name_prefix   = var.name_prefix
  database_name = var.database_name
}

# VPC Module (simplified - uses existing VPC)
module "vpc" {
  source      = "./modules/vpc"
  environment = local.environment
}

# Cloud SQL Module - Now manages the full instance
module "cloud_sql" {
  source = "./modules/cloud-sql"

  project_id                      = var.project_id
  region                          = var.region
  environment                     = local.environment
  name_prefix                     = local.name_prefix
  database_name                   = local.database_name
  cloud_sql_tier                  = var.cloud_sql_tier
  cloud_sql_disk_size             = var.cloud_sql_disk_size
  cloud_sql_backup_enabled        = var.cloud_sql_backup_enabled
  cloud_sql_backup_retention_days = var.cloud_sql_backup_retention_days
  cloud_sql_require_ssl           = var.cloud_sql_require_ssl
  delete_protection_enabled       = var.delete_protection_enabled
  db_root_password                = random_password.root_password.result
  db_app_password                 = random_password.fincore_app_password.result
  app_username                    = var.app_username
  vpc_network                     = "projects/${var.project_id}/global/networks/default"
  private_subnet                  = "default"
}

# Configure MySQL provider to connect to managed instance
provider "mysql" {
  endpoint = "${module.cloud_sql.instance_ip_address}:3306"
  username = "root"
  password = random_password.root_password.result
  tls      = false
}

# Generate passwords
resource "random_password" "root_password" {
  length  = 16
  special = true
}

resource "random_password" "fincore_app_password" {
  length  = 16
  special = true
}

resource "random_password" "fincore_admin_password" {
  length  = 16
  special = true
}

# Store passwords in Secret Manager
resource "google_secret_manager_secret" "root_password" {
  secret_id = "${local.name_prefix}-${local.environment}-root-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "root_password" {
  secret      = google_secret_manager_secret.root_password.id
  secret_data = random_password.root_password.result
}

# Store passwords in Secret Manager
resource "google_secret_manager_secret" "fincore_app_password" {
  secret_id = "${local.name_prefix}-${local.environment}-app-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "fincore_app_password" {
  secret      = google_secret_manager_secret.fincore_app_password.id
  secret_data = random_password.fincore_app_password.result
}

resource "google_secret_manager_secret" "fincore_admin_password" {
  secret_id = "${local.name_prefix}-${local.environment}-admin-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "fincore_admin_password" {
  secret      = google_secret_manager_secret.fincore_admin_password.id
  secret_data = random_password.fincore_admin_password.result
}

# Database Permissions Module
module "database_permissions" {
  source = "./modules/database-permissions"

  # Connection to managed database
  database_endpoint = "${module.cloud_sql.instance_ip_address}:3306"
  admin_username    = "root"
  admin_password    = random_password.root_password.result
  
  # Database configuration
  database_name = local.database_name
  app_username  = var.app_username
  app_password  = random_password.fincore_app_password.result
  
  # Relaxed permissions for schema evolution
  app_privileges = var.app_privileges
  
  # Security settings
  require_ssl = var.cloud_sql_require_ssl
  
  # Admin user for schema management
  create_admin_user  = var.create_admin_user
  app_admin_username = "fincore_admin"
  app_admin_password = random_password.fincore_admin_password.result
  admin_privileges   = var.app_privileges
  
  # No readonly user in NPE
  create_readonly_user = false
  readonly_username    = ""
  readonly_password    = ""
  
  # Environment context
  environment = local.environment
  project_id  = var.project_id
  
  depends_on = [module.cloud_sql]
}