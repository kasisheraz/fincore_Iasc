-- ========================================================================
-- Database Migration Script: my_auth_db → fincore_db
-- ========================================================================
-- Purpose: Drop old my_auth_db database and create new fincore_db
--          with case-insensitive configuration
-- Target: NPE Environment (Cloud SQL MySQL 8.0)
-- Date: December 30, 2025
-- ========================================================================

-- Display current database status
SELECT 'Current Databases:' AS Info;
SHOW DATABASES LIKE '%auth%';
SHOW DATABASES LIKE '%fincore%';

-- ========================================================================
-- STEP 1: DROP OLD DATABASE (NO DATA BACKUP)
-- ========================================================================
SELECT 'Dropping old my_auth_db database...' AS Info;
DROP DATABASE IF EXISTS my_auth_db;

-- Verify deletion
SELECT 'Verification - my_auth_db should be gone:' AS Info;
SHOW DATABASES LIKE '%auth%';

-- ========================================================================
-- STEP 2: CREATE NEW DATABASE WITH CASE-INSENSITIVE SETTINGS
-- ========================================================================
SELECT 'Creating new fincore_db database...' AS Info;
CREATE DATABASE fincore_db 
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_general_ci;

-- Verify creation
SELECT 'Verification - fincore_db should exist:' AS Info;
SHOW DATABASES LIKE '%fincore%';

-- Switch to new database
USE fincore_db;

-- Display database configuration
SELECT 'Database Configuration:' AS Info;
SELECT 
  SCHEMA_NAME as 'Database',
  DEFAULT_CHARACTER_SET_NAME as 'Charset',
  DEFAULT_COLLATION_NAME as 'Collation'
FROM information_schema.SCHEMATA 
WHERE SCHEMA_NAME = 'fincore_db';

-- ========================================================================
-- STEP 3: GRANT PERMISSIONS TO APPLICATION USERS
-- ========================================================================
SELECT 'Granting permissions to fincore_app user...' AS Info;

-- Grant to fincore_app (standard connections)
GRANT ALL PRIVILEGES ON fincore_db.* TO 'fincore_app'@'%';
GRANT ALL PRIVILEGES ON fincore_db.* TO 'fincore_app'@'cloudsqlproxy~%';

SELECT 'Granting permissions to fincore_admin user...' AS Info;

-- Grant to fincore_admin (admin connections)
GRANT ALL PRIVILEGES ON fincore_db.* TO 'fincore_admin'@'%';
GRANT ALL PRIVILEGES ON fincore_db.* TO 'fincore_admin'@'cloudsqlproxy~%';

-- Apply all changes
FLUSH PRIVILEGES;

-- ========================================================================
-- STEP 4: VERIFY PERMISSIONS
-- ========================================================================
SELECT 'Verifying user permissions...' AS Info;

-- Show grants for fincore_app
SELECT 'Permissions for fincore_app@%:' AS Info;
SHOW GRANTS FOR 'fincore_app'@'%';

SELECT 'Permissions for fincore_app@cloudsqlproxy~%:' AS Info;
SHOW GRANTS FOR 'fincore_app'@'cloudsqlproxy~%';

-- Show grants for fincore_admin
SELECT 'Permissions for fincore_admin@%:' AS Info;
SHOW GRANTS FOR 'fincore_admin'@'%';

SELECT 'Permissions for fincore_admin@cloudsqlproxy~%:' AS Info;
SHOW GRANTS FOR 'fincore_admin'@'cloudsqlproxy~%';

-- ========================================================================
-- STEP 5: TEST CASE-INSENSITIVE BEHAVIOR
-- ========================================================================
SELECT 'Testing case-insensitive behavior...' AS Info;

-- Create test table with mixed case column names
CREATE TABLE IF NOT EXISTS TestCaseInsensitive (
  UserId INT PRIMARY KEY,
  UserName VARCHAR(100),
  user_email VARCHAR(100)
);

-- Verify table creation
SHOW TABLES LIKE 'test%';

-- Test case-insensitive column access
INSERT INTO TestCaseInsensitive (userid, USERNAME, User_Email) 
VALUES (1, 'TestUser', 'test@example.com');

-- Query with different case variations
SELECT * FROM testcaseinsensitive;
SELECT userid, username, user_email FROM TestCaseInsensitive;

-- Clean up test table
DROP TABLE IF EXISTS TestCaseInsensitive;

-- ========================================================================
-- MIGRATION COMPLETE
-- ========================================================================
SELECT '✅ MIGRATION COMPLETED SUCCESSFULLY!' AS Status;
SELECT 'Database: fincore_db' AS Info;
SELECT 'Charset: utf8mb4' AS Info;
SELECT 'Collation: utf8mb4_general_ci (case-insensitive)' AS Info;
SELECT 'Permissions: ALL PRIVILEGES granted to fincore_app and fincore_admin' AS Info;
