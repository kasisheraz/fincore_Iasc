# Fincore Infrastructure Outputs

# Cloud SQL Instance Information
output "cloud_sql_instance_name" {
  description = "Cloud SQL instance name"
  value       = module.cloud_sql.instance_name
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL connection name"
  value       = module.cloud_sql.instance_connection_name
}

output "database_name" {
  description = "Database name"
  value       = module.cloud_sql.database_name
}

output "database_collation" {
  description = "Database collation (case-insensitive)"
  value       = module.cloud_sql.database_collation
}

# Database Connection Information  
output "database_endpoint" {
  description = "Database connection endpoint"
  value       = "${module.cloud_sql.instance_ip_address}:3306"
  sensitive   = true
}

# Secret Manager References
output "root_password_secret" {
  description = "Secret Manager secret ID for root password"
  value       = google_secret_manager_secret.root_password.secret_id
}

output "fincore_app_password_secret" {
  description = "Secret Manager secret ID for fincore app password"
  value       = google_secret_manager_secret.fincore_app_password.secret_id
}

output "fincore_admin_password_secret" {
  description = "Secret Manager secret ID for fincore admin password" 
  value       = google_secret_manager_secret.fincore_admin_password.secret_id
}

# Environment Information
output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "environment" {
  description = "Environment"
  value       = local.environment
}