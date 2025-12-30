-- Execute privileges directly  
GRANT ALL PRIVILEGES ON `fincore_db`.* TO 'fincore_app'@'%';
GRANT ALL PRIVILEGES ON `fincore_db`.* TO 'fincore_admin'@'%';
FLUSH PRIVILEGES;
SELECT 'Database privileges applied successfully!' as Result;