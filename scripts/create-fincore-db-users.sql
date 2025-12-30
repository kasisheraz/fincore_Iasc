-- ================================================================
-- Fincore Database: Complete Setup Script
-- ================================================================
-- Description: Creates fincore_db database and all required users with privileges
-- Database: fincore_db (case-insensitive collation)
-- Prerequisites: MySQL root access or Cloud SQL admin privileges
-- Execute: Via GCP Console SQL Editor or Cloud SQL Proxy
-- Last Updated: December 30, 2025
-- ================================================================

-- Create fincore_db database with case-insensitive collation
CREATE DATABASE IF NOT EXISTS fincore_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_general_ci;

-- Create fincore_app user with standard host
CREATE USER IF NOT EXISTS 'fincore_app'@'%' IDENTIFIED BY '}iaczgnIKK*3BShD';

-- Create fincore_app user with Cloud SQL Proxy host
CREATE USER IF NOT EXISTS 'fincore_app'@'cloudsqlproxy~%' IDENTIFIED BY '}iaczgnIKK*3BShD';

-- Create fincore_admin user with standard host
CREATE USER IF NOT EXISTS 'fincore_admin'@'%' IDENTIFIED BY '!uHw[D)ZZCB=%emD';

-- Create fincore_admin user with Cloud SQL Proxy host
CREATE USER IF NOT EXISTS 'fincore_admin'@'cloudsqlproxy~%' IDENTIFIED BY '!uHw[D)ZZCB=%emD';

-- Grant privileges to fincore_app users
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, 
      CREATE TEMPORARY TABLES, LOCK TABLES 
ON fincore_db.* TO 'fincore_app'@'%';

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, 
      CREATE TEMPORARY TABLES, LOCK TABLES 
ON fincore_db.* TO 'fincore_app'@'cloudsqlproxy~%';

-- Grant privileges to fincore_admin users
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, 
      CREATE TEMPORARY TABLES, LOCK TABLES 
ON fincore_db.* TO 'fincore_admin'@'%';

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, 
      CREATE TEMPORARY TABLES, LOCK TABLES 
ON fincore_db.* TO 'fincore_admin'@'cloudsqlproxy~%';

-- Flush privileges to ensure changes take effect
FLUSH PRIVILEGES;

-- Verify database collation
SELECT SCHEMA_NAME, DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME 
FROM INFORMATION_SCHEMA.SCHEMATA 
WHERE SCHEMA_NAME = 'fincore_db';
