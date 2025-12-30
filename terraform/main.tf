# Minimal Database Permissions Configuration
# Only adds database permissions to existing Cloud SQL instance
# Deploy: 2025-12-30

# Configure Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Data source for existing Cloud SQL instance
data "google_sql_database_instance" "existing" {
  name = "fincore-npe-db"  # Your existing instance
}

# Configure MySQL provider to connect to existing instance
provider "mysql" {
  endpoint = "${data.google_sql_database_instance.existing.public_ip_address}:3306"
  username = "root"
  password = "TempRoot2024!"  # Your current password
  tls      = false
}

# Generate new passwords
resource "random_password" "fincore_app_password" {
  length  = 16
  special = true
}

resource "random_password" "fincore_admin_password" {
  length  = 16
  special = true
}

# Store new passwords in Secret Manager
resource "google_secret_manager_secret" "fincore_app_password" {
  secret_id = "fincore-npe-app-password"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "fincore_app_password" {
  secret      = google_secret_manager_secret.fincore_app_password.id
  secret_data = random_password.fincore_app_password.result
}

resource "google_secret_manager_secret" "fincore_admin_password" {
  secret_id = "fincore-npe-admin-password"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "fincore_admin_password" {
  secret      = google_secret_manager_secret.fincore_admin_password.id
  secret_data = random_password.fincore_admin_password.result
}

# Database Permissions Module - simplified call
module "database_permissions" {
  source = "./modules/database-permissions"

  # Connection to existing database
  database_endpoint = "${data.google_sql_database_instance.existing.public_ip_address}:3306"
  admin_username    = "root"
  admin_password    = "TempRoot2024!"
  
  # Database configuration
  database_name = "fincore_db"
  app_username  = "fincore_app"
  app_password  = random_password.fincore_app_password.result
  
  # Relaxed permissions for schema evolution
  app_privileges = [
    "SELECT", "INSERT", "UPDATE", "DELETE",
    "CREATE", "DROP", "INDEX", "ALTER",
    "CREATE TEMPORARY TABLES", "LOCK TABLES"
  ]
  
  # Security settings (relaxed for NPE)
  require_ssl = false
  
  # NPE admin user for schema management
  create_admin_user  = true
  app_admin_username = "fincore_admin"
  app_admin_password = random_password.fincore_admin_password.result
  admin_privileges   = [
    "SELECT", "INSERT", "UPDATE", "DELETE",
    "CREATE", "DROP", "INDEX", "ALTER",
    "CREATE TEMPORARY TABLES", "LOCK TABLES"
  ]
  
  # No readonly user in NPE
  create_readonly_user = false
  readonly_username    = ""
  readonly_password    = ""
  
  # Environment context
  environment = "npe"
  project_id  = var.project_id
}