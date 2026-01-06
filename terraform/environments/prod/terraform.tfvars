# Production Environment Configuration
# Strict security settings for production deployment

# Basic Infrastructure
project_id  = "project-07a61357-b791-4255-a9e"
region      = "us-central1"
environment = "prod"
name_prefix = "fincore"

# Database Configuration
database_name = "fincore_db"
app_username  = "fincore_app"

# Cloud SQL Configuration (Production settings)
cloud_sql_tier                  = "db-n1-standard-2"
cloud_sql_disk_size             = 100
cloud_sql_backup_enabled        = true
cloud_sql_backup_retention_days = 30
cloud_sql_require_ssl           = true # Required for production
delete_protection_enabled       = true # Enabled for production

# Database Permissions (Same as NPE for flexibility during schema changes)
app_privileges = [
  "SELECT", "INSERT", "UPDATE", "DELETE",
  "CREATE", "DROP", "INDEX", "ALTER",
  "CREATE TEMPORARY TABLES", "LOCK TABLES"
]

# Security Settings
require_ssl = true

# User Management (Production specific)
create_admin_user    = false # No admin user in production
create_readonly_user = true  # Enable readonly user for monitoring