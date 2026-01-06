# VPC Module - Simplified for existing VPC

output "vpc_network" {
  description = "VPC network name"
  value       = "projects/${var.project_id}/global/networks/default"
}

output "private_subnet" {
  description = "Private subnet name"
  value       = "default"
}

output "vpc_connector" {
  description = "VPC connector for Cloud Run"
  value       = "fincore-${var.environment}-connector"
}