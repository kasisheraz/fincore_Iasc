# VPC Module - Placeholder
# This module will be enhanced with full VPC configuration

output "vpc_network" {
  description = "VPC network name"
  value       = "fincore-${var.environment}-vpc"
}

output "private_subnet" {
  description = "Private subnet name"
  value       = "fincore-${var.environment}-subnet"
}

output "vpc_connector" {
  description = "VPC connector for Cloud Run"
  value       = "fincore-${var.environment}-connector"
}