# Minimal Database Permissions Outputs

# Database Connection Information  
output "database_endpoint" {
  description = "Database connection endpoint"
  value       = "${data.google_sql_database_instance.existing.public_ip_address}:3306"
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