# NPE Environment Configuration
# Relaxed security settings for development and testing

# Basic Infrastructure
project_id   = "project-07a61357-b791-4255-a9e"
region       = "us-central1"
environment  = "npe"
name_prefix  = "fincore"

# Database Configuration
database_name = "fincore_db"
app_username  = "fincore_app"

# Cloud SQL Configuration (Development settings)
cloud_sql_tier                   = "db-f1-micro"
cloud_sql_disk_size              = 10
cloud_sql_backup_enabled         = true
cloud_sql_backup_retention_days  = 7
cloud_sql_require_ssl           = false  # Relaxed for NPE
delete_protection_enabled        = false # Disabled for NPE

# Database Permissions (Relaxed for Schema Evolution)
app_privileges = [
  "SELECT", "INSERT", "UPDATE", "DELETE",
  "CREATE", "DROP", "INDEX", "ALTER",
  "CREATE TEMPORARY TABLES", "LOCK TABLES"
]

# Security Settings (Relaxed)
require_ssl = false

# User Management (NPE specific)
create_admin_user    = true   # Enable admin user for schema management
create_readonly_user = false  # Not needed in NPE