output "instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "Cloud SQL connection name"
  value       = google_sql_database_instance.main.connection_name
}

output "instance_id" {
  description = "Cloud SQL instance ID"
  value       = google_sql_database_instance.main.id
}

output "private_ip_address" {
  description = "Private IP address"
  value       = google_sql_database_instance.main.private_ip_address
}