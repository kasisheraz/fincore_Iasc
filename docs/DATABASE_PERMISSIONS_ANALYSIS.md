# Database Permissions for User Management API

## Overview

This document describes the optimized database permission model specifically designed for the **User Management API** (userManagementApi). The permission model has been analyzed and tailored based on the application's actual database operations and security requirements.

## Application Analysis

### Database Operations Required

Based on the userManagementApi codebase analysis, the application performs the following database operations:

#### Core Tables
- **`users`** - User account management
- **`roles`** - Role definitions (ADMIN, COMPLIANCE_OFFICER, OPERATIONAL_STAFF)
- **`permissions`** - Granular permission definitions
- **`role_permissions`** - Many-to-many mapping

#### Required Operations
1. **Authentication Operations**
   - `SELECT` on users table for login validation
   - `UPDATE` on users table for failed login attempts, last login timestamp
   - Account locking/unlocking (status updates)

2. **User Management (CRUD)**
   - `SELECT`, `INSERT`, `UPDATE`, `DELETE` on users table
   - Password hash updates
   - Profile information updates

3. **Role & Permission Management**
   - `SELECT` on roles and permissions tables
   - `INSERT`, `UPDATE`, `DELETE` on role_permissions for access control

4. **Audit & Security**
   - Timestamp updates (created_at, updated_at, last_login_at)
   - Failed login attempt tracking
   - Account status changes

## Environment-Specific Permission Strategy

### NPE (Non-Production Environment)

**Purpose:** Development, testing, schema evolution

**Permissions Granted:**
```sql
GRANT SELECT, INSERT, UPDATE, DELETE, 
      CREATE, DROP, INDEX, ALTER,
      CREATE TEMPORARY TABLES, LOCK TABLES 
ON my_auth_db.* TO 'fincore_app'@'%';

GRANT SELECT, INSERT, UPDATE, DELETE, 
      CREATE, DROP, INDEX, ALTER,
      CREATE TEMPORARY TABLES, LOCK TABLES 
ON my_auth_db.* TO 'fincore_app'@'cloudsqlproxy~%';
```

**Additional Users:**
- **`fincore_admin`** - For schema migrations and administrative tasks
- **No read-only user** - Not needed in development

**Rationale:**
- Includes DDL permissions (`CREATE`, `DROP`, `ALTER`) for schema evolution
- Allows developers to modify database structure during development
- More permissive to support testing scenarios

### Production Environment

**Purpose:** Live application serving real users

**Permissions Granted:**
```sql
GRANT SELECT, INSERT, UPDATE, DELETE,
      CREATE TEMPORARY TABLES, LOCK TABLES 
ON my_auth_db.* TO 'fincore_app'@'%';

GRANT SELECT, INSERT, UPDATE, DELETE,
      CREATE TEMPORARY TABLES, LOCK TABLES 
ON my_auth_db.* TO 'fincore_app'@'cloudsqlproxy~%';
```

**Additional Users:**
- **`fincore_readonly`** - For monitoring, reporting, and read-only analytics
- **No admin user** - Administrative access managed through separate, more secure channels

**Rationale:**
- **No DDL permissions** (`CREATE`, `DROP`, `ALTER`) - Schema changes go through controlled migration process
- Only DML operations for normal application functionality
- Separate read-only user for monitoring tools and analytics

## Security Considerations

### Principle of Least Privilege

1. **Application User (`fincore_app`)**
   - Only permissions required for normal application operation
   - No administrative privileges
   - No DDL permissions in production

2. **Read-Only User (`fincore_readonly`)**
   - Only `SELECT` permission
   - Used for monitoring, reporting, dashboards
   - Cannot modify data

3. **Admin User (`fincore_admin`)**
   - Only in NPE environment
   - Used for schema migrations and development tasks
   - Not created in production for security

### Connection Security

1. **SSL/TLS Enforcement**
   - All connections require SSL encryption
   - Prevents man-in-the-middle attacks
   - Protects credentials in transit

2. **Cloud SQL Proxy Support**
   - Specific grants for `cloudsqlproxy~%` host pattern
   - Enables secure tunneled connections
   - Works with Cloud Run serverless environment

3. **Host Restrictions**
   - Uses `%` wildcard for flexibility with Cloud Run
   - In production, could be further restricted to specific IP ranges
   - Proxy connections automatically restricted by GCP network policies

## Terraform Configuration

### Module Usage

```hcl
module "database_permissions" {
  source = "./modules/database-permissions"

  # Database connection
  database_endpoint = "${module.cloud_sql.private_ip_address}:3306"
  admin_password    = var.db_root_password
  
  # Application user
  app_password   = var.db_app_password
  app_privileges = var.environment == "prod" ? [
    "SELECT", "INSERT", "UPDATE", "DELETE",
    "CREATE TEMPORARY TABLES", "LOCK TABLES"
  ] : [
    "SELECT", "INSERT", "UPDATE", "DELETE",
    "CREATE", "DROP", "INDEX", "ALTER",
    "CREATE TEMPORARY TABLES", "LOCK TABLES"
  ]
  
  # Environment-specific users
  create_admin_user    = var.environment == "npe"
  admin_password       = var.db_admin_password
  
  create_readonly_user = var.environment == "prod"
  readonly_password    = var.db_readonly_password
  
  # Security
  require_ssl = true
  
  environment = var.environment
  project_id  = var.project_id
}
```

### Environment Variables

#### NPE Environment
```bash
# Application database user
DB_USER=fincore_app
DB_PASSWORD=<secure-password>

# Administrative user for development
ADMIN_USER=fincore_admin
ADMIN_PASSWORD=<admin-password>

# SSL enforcement
DB_USE_SSL=true
```

#### Production Environment
```bash
# Application database user (restricted permissions)
DB_USER=fincore_app
DB_PASSWORD=<secure-production-password>

# Read-only user for monitoring
READONLY_USER=fincore_readonly
READONLY_PASSWORD=<readonly-password>

# SSL enforcement
DB_USE_SSL=true
```

## Migration Strategy

### From Current Setup

If you already have the database user `fincore_app` with `ALL PRIVILEGES`, here's how to migrate:

1. **Backup Current Setup**
   ```sql
   SHOW GRANTS FOR 'fincore_app'@'%';
   SHOW GRANTS FOR 'fincore_app'@'cloudsqlproxy~%';
   ```

2. **Apply New Permissions**
   ```bash
   cd terraform
   terraform apply -target=module.database_permissions
   ```

3. **Verify New Permissions**
   ```sql
   SHOW GRANTS FOR 'fincore_app'@'%';
   SHOW GRANTS FOR 'fincore_app'@'cloudsqlproxy~%';
   ```

4. **Test Application**
   - Run full test suite
   - Verify all API endpoints work
   - Check authentication and user management functions

## Monitoring and Validation

### Permission Verification

```sql
-- Check application user permissions
SHOW GRANTS FOR 'fincore_app'@'%';
SHOW GRANTS FOR 'fincore_app'@'cloudsqlproxy~%';

-- Check read-only user (production only)
SHOW GRANTS FOR 'fincore_readonly'@'%';

-- Check admin user (NPE only)
SHOW GRANTS FOR 'fincore_admin'@'%';

-- Verify SSL requirement
SHOW VARIABLES LIKE '%ssl%';
```

### Application Testing

```bash
# Test authentication
curl -X POST https://your-api-url/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Admin@123456"}'

# Test user creation
curl -X POST https://your-api-url/api/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "TestPass123!",
    "fullName": "Test User",
    "department": "IT"
  }'

# Test user retrieval
curl -X GET https://your-api-url/api/users \
  -H "Authorization: Bearer $TOKEN"
```

## Troubleshooting

### Common Issues

1. **Access Denied Error**
   ```
   Access denied for user 'fincore_app'@'cloudsqlproxy~...'
   ```
   **Solution:** Verify both `%` and `cloudsqlproxy~%` grants exist

2. **Schema Creation Fails in Production**
   ```
   User doesn't have CREATE privilege
   ```
   **Solution:** Expected behavior - use migration scripts with admin access

3. **Monitoring Queries Fail**
   ```
   Access denied for user 'fincore_app' (using password: YES)
   ```
   **Solution:** Use `fincore_readonly` user for monitoring queries

### Best Practices

1. **Regular Permission Audits**
   - Review user permissions quarterly
   - Remove unused users
   - Rotate passwords regularly

2. **Development Workflow**
   - Test schema changes in NPE first
   - Use admin user only for migrations
   - Validate application works with restricted prod permissions

3. **Security Monitoring**
   - Monitor failed login attempts
   - Set up alerts for unusual database access patterns
   - Use read-only user for all monitoring tools

This optimized permission model ensures your User Management API has exactly the database access it needs while maintaining strong security boundaries between environments.