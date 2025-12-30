-- ================================================================
-- Fincore Database: Grant Privileges to Users
-- ================================================================
-- Description: Grants database privileges to fincore_app and fincore_admin users
-- Database: fincore_db
-- Prerequisites: Users must already exist (created via gcloud or Terraform)
-- Execute: Via GCP Console SQL Editor or Cloud SQL Proxy
-- Last Updated: December 30, 2025
-- ================================================================

-- Grant privileges to fincore_app user
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES 
ON fincore_db.* TO 'fincore_app'@'%';

-- Grant privileges to fincore_admin user  
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES 
ON fincore_db.* TO 'fincore_admin'@'%';

-- Apply changes
FLUSH PRIVILEGES;

-- ================================================================
-- Verification Queries
-- ================================================================

-- Verify users exist
SELECT user, host FROM mysql.user WHERE user IN ('fincore_app', 'fincore_admin');

-- Verify grants for fincore_app
SHOW GRANTS FOR 'fincore_app'@'%';

-- Verify grants for fincore_admin
SHOW GRANTS FOR 'fincore_admin'@'%';
