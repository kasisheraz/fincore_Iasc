-- Database User Setup Script for fincore_Iasc
-- Run this against your Cloud SQL MySQL instance at 34.147.230.142:3306

-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS fincore_db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- Use the database
USE fincore_db;

-- Generate strong passwords (you should change these)
SET @app_password = 'FincoreApp2024!@#';
SET @admin_password = 'FincoreAdmin2024!@#';

-- Create fincore_app user with % host (for normal connections)
CREATE USER IF NOT EXISTS 'fincore_app'@'%' IDENTIFIED BY @app_password;

-- Create fincore_app user with cloudsqlproxy host (for proxy connections)  
CREATE USER IF NOT EXISTS 'fincore_app'@'cloudsqlproxy~%' IDENTIFIED BY @app_password;

-- Create fincore_admin user with % host (for admin connections)
CREATE USER IF NOT EXISTS 'fincore_admin'@'%' IDENTIFIED BY @admin_password;

-- Create fincore_admin user with cloudsqlproxy host (for admin proxy connections)
CREATE USER IF NOT EXISTS 'fincore_admin'@'cloudsqlproxy~%' IDENTIFIED BY @admin_password;

-- Grant ALL PRIVILEGES to fincore_app on fincore_db (relaxed policy for NPE)
GRANT ALL PRIVILEGES ON fincore_db.* TO 'fincore_app'@'%';
GRANT ALL PRIVILEGES ON fincore_db.* TO 'fincore_app'@'cloudsqlproxy~%';

-- Grant ALL PRIVILEGES to fincore_admin on fincore_db (admin access)
GRANT ALL PRIVILEGES ON fincore_db.* TO 'fincore_admin'@'%';
GRANT ALL PRIVILEGES ON fincore_db.* TO 'fincore_admin'@'cloudsqlproxy~%';

-- Apply the changes
FLUSH PRIVILEGES;

-- Verify users were created
SELECT User, Host FROM mysql.user WHERE User IN ('fincore_app', 'fincore_admin');

-- Show granted privileges
SHOW GRANTS FOR 'fincore_app'@'%';
SHOW GRANTS FOR 'fincore_app'@'cloudsqlproxy~%';
SHOW GRANTS FOR 'fincore_admin'@'%';
SHOW GRANTS FOR 'fincore_admin'@'cloudsqlproxy~%';

-- Success message
SELECT 'Database users created successfully!' AS Status;