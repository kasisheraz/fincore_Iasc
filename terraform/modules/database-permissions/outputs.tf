# Database Permissions Module Outputs

output "app_username" {
  description = "Application database username"
  value       = var.app_username
}

output "app_user_hosts" {
  description = "Hosts for which application user is created"
  value = [
    mysql_user.fincore_app.host,
    mysql_user.fincore_app_proxy.host
  ]
}

output "admin_username" {
  description = "Administrative database username"
  value       = var.create_admin_user ? var.app_admin_username : null
}

output "readonly_username" {
  description = "Read-only database username"
  value       = var.create_readonly_user ? var.readonly_username : null
}

output "database_name" {
  description = "Database name with permissions configured"
  value       = var.database_name
}

output "app_privileges_granted" {
  description = "List of privileges granted to application user"
  value       = var.app_privileges
}

output "admin_privileges_granted" {
  description = "List of privileges granted to administrative user"
  value       = var.create_admin_user ? var.admin_privileges : []
}

output "users_created" {
  description = "Summary of users created"
  value = {
    application = {
      username = var.app_username
      hosts    = ["%", "cloudsqlproxy~%"]
    }
    admin = var.create_admin_user ? {
      username = var.app_admin_username
      hosts    = ["%", "cloudsqlproxy~%"]
    } : null
    readonly = var.create_readonly_user ? {
      username = var.readonly_username
      hosts    = ["%", "cloudsqlproxy~%"]
    } : null
  }
}