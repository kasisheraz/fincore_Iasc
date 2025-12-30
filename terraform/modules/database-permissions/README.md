# Database Permissions Module - README

## Overview

This Terraform module manages database users, permissions, and access control for the Fincore application. It creates dedicated database users with appropriate privileges for different access patterns (application access, proxy access, read-only access).

## Features

- Creates application database users for standard and Cloud SQL Proxy connections
- Configurable privilege grants with validation
- Optional read-only user creation for monitoring/reporting
- SSL requirement enforcement
- Automatic privilege flushing

## Usage

```hcl
module "database_permissions" {
  source = "./modules/database-permissions"

  # Database connection
  database_endpoint = module.cloud_sql.private_ip_address
  admin_password    = var.db_root_password
  
  # Application user
  app_password = var.db_app_password
  
  # Environment
  environment = var.environment
  project_id  = var.project_id
  
  # Optional: Create read-only user
  create_readonly_user = true
  readonly_password   = var.db_readonly_password
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| mysql | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| mysql | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| database_endpoint | Database connection endpoint (host:port) | `string` | n/a | yes |
| admin_username | Database admin username | `string` | `"root"` | no |
| admin_password | Database admin password | `string` | n/a | yes |
| database_name | Name of the database to grant permissions on | `string` | `"my_auth_db"` | no |
| app_username | Application database username | `string` | `"fincore_app"` | no |
| app_password | Application database password | `string` | n/a | yes |
| app_privileges | Privileges to grant to application user | `list(string)` | `["ALL PRIVILEGES"]` | no |
| require_ssl | Require SSL connections to database | `bool` | `true` | no |
| create_readonly_user | Create a read-only user for monitoring/reporting | `bool` | `false` | no |
| readonly_username | Read-only database username | `string` | `"fincore_readonly"` | no |
| readonly_password | Read-only database password | `string` | `""` | no |
| environment | Environment (npe, prod, etc.) | `string` | n/a | yes |
| project_id | GCP Project ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| app_username | Application database username |
| app_user_hosts | Hosts for which application user is created |
| readonly_username | Read-only database username |
| database_name | Database name with permissions configured |
| privileges_granted | List of privileges granted to application user |

## Security Considerations

1. **Principle of Least Privilege**: Consider using specific privileges instead of `ALL PRIVILEGES` for production
2. **Password Management**: Store passwords in Secret Manager or use Terraform sensitive variables
3. **SSL Enforcement**: Always use SSL connections in production
4. **Host Restrictions**: Consider restricting hosts for production environments

## Recommended Production Configuration (Relaxed Policy)

```hcl
module "database_permissions" {
  source = "./modules/database-permissions"

  # Database connection
  database_endpoint = module.cloud_sql.private_ip_address
  admin_password    = data.google_secret_manager_secret_version.db_root_password.secret_data
  
  # Application user with relaxed privileges for schema evolution
  app_password = data.google_secret_manager_secret_version.db_app_password.secret_data
  app_privileges = [
    "SELECT", "INSERT", "UPDATE", "DELETE",
    "CREATE", "DROP", "INDEX", "ALTER",
    "CREATE TEMPORARY TABLES", "LOCK TABLES",
    "CREATE VIEW", "SHOW VIEW"
  ]
  
  # Security settings
  require_ssl = true
  
  # Monitoring
  create_readonly_user = true
  readonly_password   = data.google_secret_manager_secret_version.db_readonly_password.secret_data
  
  environment = "prod"
  project_id  = var.project_id
}
```