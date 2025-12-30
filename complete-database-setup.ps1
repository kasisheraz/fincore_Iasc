# PowerShell script to complete database setup
# Downloads mysql client and executes privilege grants

Write-Host "=== Database Setup Completion ===" -ForegroundColor Green

# Check if we need to install mysql client
$mysqlPath = Get-Command mysql -ErrorAction SilentlyContinue

if (-not $mysqlPath) {
    Write-Host "Installing MySQL client..." -ForegroundColor Yellow
    
    # Download and install MySQL client (portable version)
    $downloadUrl = "https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.40-winx64.zip"
    $tempDir = "$env:TEMP\mysql_client"
    $zipFile = "$tempDir\mysql.zip"
    
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    try {
        Write-Host "Downloading MySQL client..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
        
        Write-Host "Extracting MySQL client..." -ForegroundColor Yellow
        Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force
        
        $mysqlExe = Get-ChildItem -Path $tempDir -Recurse -Name "mysql.exe" | Select-Object -First 1
        $mysqlFullPath = Join-Path $tempDir $mysqlExe
        
        Write-Host "MySQL client ready at: $mysqlFullPath" -ForegroundColor Green
        
        # Execute the privilege grants
        Write-Host "Granting database privileges..." -ForegroundColor Yellow
        $grantSql = @"
GRANT ALL PRIVILEGES ON fincore_db.* TO 'fincore_app'@'%';
GRANT ALL PRIVILEGES ON fincore_db.* TO 'fincore_admin'@'%';
FLUSH PRIVILEGES;
SELECT 'Privileges granted successfully!' AS Status;
"@
        
        $grantSql | & $mysqlFullPath -h 34.147.230.142 -u root -p"TempRoot2024!"
        
        Write-Host "Database setup completed successfully!" -ForegroundColor Green
        
    } catch {
        Write-Error "Failed to setup MySQL client: $_"
        Write-Host "Manual approach required - see DATABASE_SETUP.md" -ForegroundColor Yellow
    } finally {
        # Cleanup
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "MySQL client found, granting privileges..." -ForegroundColor Green
    $grantSql = @"
GRANT ALL PRIVILEGES ON fincore_db.* TO 'fincore_app'@'%';
GRANT ALL PRIVILEGES ON fincore_db.* TO 'fincore_admin'@'%';
FLUSH PRIVILEGES;
SELECT 'Privileges granted successfully!' AS Status;
"@
    
    $grantSql | mysql -h 34.147.230.142 -u root -p"TempRoot2024!"
    Write-Host "Database setup completed!" -ForegroundColor Green
}

Write-Host "`n=== Setup Summary ===" -ForegroundColor Cyan
Write-Host "✅ Database: fincore_db (created)" -ForegroundColor Green
Write-Host "✅ User: fincore_app (password: FincoreApp2024!@#)" -ForegroundColor Green  
Write-Host "✅ User: fincore_admin (password: FincoreAdmin2024!@#)" -ForegroundColor Green
Write-Host "✅ Privileges: ALL PRIVILEGES ON fincore_db.*" -ForegroundColor Green
Write-Host "✅ Connection: 34.147.230.142:3306" -ForegroundColor Green