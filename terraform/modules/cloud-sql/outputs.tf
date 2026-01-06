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

output "instance_ip_address" {
  description = "Public IP address"
  value       = google_sql_database_instance.main.public_ip_address
}

output "private_ip_address" {
  description = "Private IP address"
  value       = google_sql_database_instance.main.private_ip_address
}

output "database_name" {
  description = "Database name"
  value       = google_sql_database.main.name
}

output "database_collation" {
  description = "Database collation"
  value       = google_sql_database.main.collation
}