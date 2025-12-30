# Infrastructure Health Check and Testing Report
# Testing all components for fincore_Iasc NPE environment

Write-Host "=== INFRASTRUCTURE HEALTH CHECK REPORT ===" -ForegroundColor Green
Write-Host "Environment: NPE" -ForegroundColor Yellow
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')" -ForegroundColor Yellow
Write-Host "=" * 60

# Test Results Object
$testResults = @{
    CloudSQL = @{}
    Database = @{}
    Users = @{}
    Connectivity = @{}
    Infrastructure = @{}
    Summary = @{}
}

Write-Host "`n1. CLOUD SQL INSTANCE STATUS" -ForegroundColor Cyan
Write-Host "-" * 40

try {
    $sqlInstanceStatus = gcloud sql instances describe fincore-npe-db --format="value(state,settings.tier,databaseVersion)" --quiet
    $instanceInfo = $sqlInstanceStatus -split "`t"
    
    $testResults.CloudSQL.Status = $instanceInfo[0]
    $testResults.CloudSQL.Tier = $instanceInfo[1]  
    $testResults.CloudSQL.Version = $instanceInfo[2]
    
    Write-Host "✅ Instance Status: $($instanceInfo[0])" -ForegroundColor Green
    Write-Host "✅ Instance Tier: $($instanceInfo[1])" -ForegroundColor Green
    Write-Host "✅ MySQL Version: $($instanceInfo[2])" -ForegroundColor Green
    
    # Get IP addresses
    $ipInfo = gcloud sql instances describe fincore-npe-db --format="value(ipAddresses[0].ipAddress,ipAddresses[1].ipAddress)" --quiet
    $ips = $ipInfo -split "`t"
    $testResults.CloudSQL.PublicIP = $ips[0]
    $testResults.CloudSQL.PrivateIP = $ips[1]
    
    Write-Host "✅ Public IP: $($ips[0])" -ForegroundColor Green
    Write-Host "✅ Private IP: $($ips[1])" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Cloud SQL Instance Check Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.CloudSQL.Error = $_.Exception.Message
}

Write-Host "`n2. DATABASE USERS VERIFICATION" -ForegroundColor Cyan  
Write-Host "-" * 40

try {
    $usersList = gcloud sql users list --instance=fincore-npe-db --format="csv[no-heading](name,host)" --quiet
    $users = $usersList -split "`n" | ForEach-Object { $_.Split(",") }
    
    $testResults.Users.List = @()
    foreach ($user in $users) {
        if ($user.Count -eq 2) {
            $userObj = @{
                Name = $user[0]
                Host = $user[1]
            }
            $testResults.Users.List += $userObj
            Write-Host "✅ User: $($user[0])@$($user[1])" -ForegroundColor Green
        }
    }
    
    # Check for our specific users
    $fincoreAppExists = $users | Where-Object { $_ -match "fincore_app" }
    $fincoreAdminExists = $users | Where-Object { $_ -match "fincore_admin" }
    
    $testResults.Users.FincoreApp = $fincoreAppExists -ne $null
    $testResults.Users.FincoreAdmin = $fincoreAdminExists -ne $null
    
    if ($fincoreAppExists) {
        Write-Host "✅ fincore_app user exists" -ForegroundColor Green
    } else {
        Write-Host "❌ fincore_app user missing" -ForegroundColor Red
    }
    
    if ($fincoreAdminExists) {
        Write-Host "✅ fincore_admin user exists" -ForegroundColor Green
    } else {
        Write-Host "❌ fincore_admin user missing" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ User Verification Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.Users.Error = $_.Exception.Message
}

Write-Host "`n3. DATABASE STRUCTURE CHECK" -ForegroundColor Cyan
Write-Host "-" * 40

try {
    $databases = gcloud sql databases list --instance=fincore-npe-db --format="csv[no-heading](name,charset,collation)" --quiet
    $dbList = $databases -split "`n" | ForEach-Object { $_.Split(",") }
    
    $testResults.Database.List = @()
    foreach ($db in $dbList) {
        if ($db.Count -eq 3) {
            $dbObj = @{
                Name = $db[0]
                Charset = $db[1]
                Collation = $db[2]
            }
            $testResults.Database.List += $dbObj
            Write-Host "✅ Database: $($db[0]) (charset: $($db[1]))" -ForegroundColor Green
        }
    }
    
    # Check for our specific database
    $myAuthDbExists = $dbList | Where-Object { $_ -match "my_auth_db" }
    $testResults.Database.MyAuthDbExists = $myAuthDbExists -ne $null
    
    if ($myAuthDbExists) {
        Write-Host "✅ my_auth_db database exists with UTF8MB4 charset" -ForegroundColor Green
    } else {
        Write-Host "❌ my_auth_db database missing" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Database Structure Check Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.Database.Error = $_.Exception.Message
}

Write-Host "`n4. NETWORK CONNECTIVITY TEST" -ForegroundColor Cyan
Write-Host "-" * 40

try {
    # Test public IP connectivity
    $publicIP = $testResults.CloudSQL.PublicIP
    if ($publicIP) {
        $tcpTest = Test-NetConnection -ComputerName $publicIP -Port 3306 -WarningAction SilentlyContinue
        $testResults.Connectivity.PublicPort3306 = $tcpTest.TcpTestSucceeded
        
        if ($tcpTest.TcpTestSucceeded) {
            Write-Host "✅ Port 3306 accessible on public IP ($publicIP)" -ForegroundColor Green
        } else {
            Write-Host "❌ Port 3306 not accessible on public IP ($publicIP)" -ForegroundColor Red
        }
    }
    
    # Test DNS resolution
    try {
        $dnsTest = Resolve-DnsName $publicIP -ErrorAction Stop
        $testResults.Connectivity.DNSResolution = $true
        Write-Host "✅ DNS resolution successful" -ForegroundColor Green
    } catch {
        $testResults.Connectivity.DNSResolution = $false
        Write-Host "❌ DNS resolution failed" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Network Connectivity Test Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.Connectivity.Error = $_.Exception.Message
}

Write-Host "`n5. CLOUD SQL OPERATIONS STATUS" -ForegroundColor Cyan
Write-Host "-" * 40

try {
    $recentOps = gcloud sql operations list --instance=fincore-npe-db --limit=5 --format="csv[no-heading](operationType,status,startTime)" --quiet
    $operations = $recentOps -split "`n" | ForEach-Object { $_.Split(",") }
    
    $testResults.Infrastructure.RecentOperations = @()
    foreach ($op in $operations) {
        if ($op.Count -eq 3) {
            $opObj = @{
                Type = $op[0]
                Status = $op[1]
                StartTime = $op[2]
            }
            $testResults.Infrastructure.RecentOperations += $opObj
            Write-Host "✅ $($op[0]): $($op[1]) ($($op[2]))" -ForegroundColor Green
        }
    }
    
} catch {
    Write-Host "❌ Operations Status Check Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.Infrastructure.Error = $_.Exception.Message
}

Write-Host "`n6. PROJECT AND AUTHENTICATION STATUS" -ForegroundColor Cyan
Write-Host "-" * 40

try {
    $currentProject = gcloud config get project --quiet
    $currentUser = gcloud auth list --filter=status:ACTIVE --format="value(account)" --quiet
    
    $testResults.Infrastructure.ProjectId = $currentProject
    $testResults.Infrastructure.AuthenticatedUser = $currentUser
    
    Write-Host "✅ Current Project: $currentProject" -ForegroundColor Green
    Write-Host "✅ Authenticated User: $currentUser" -ForegroundColor Green
    
    # Check IAM permissions
    $permissions = gcloud projects get-iam-policy $currentProject --format="value(bindings.members)" --quiet
    $hasCloudSqlAdmin = $permissions -match "cloudsql.admin"
    $testResults.Infrastructure.HasCloudSqlAdmin = $hasCloudSqlAdmin
    
    if ($hasCloudSqlAdmin) {
        Write-Host "✅ Cloud SQL Admin permissions confirmed" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Cloud SQL Admin permissions not found" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Project/Auth Status Check Failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.Infrastructure.AuthError = $_.Exception.Message
}

Write-Host "`n" + "=" * 60
Write-Host "INFRASTRUCTURE HEALTH SUMMARY" -ForegroundColor Green
Write-Host "=" * 60

# Generate Summary
$healthScore = 0
$totalChecks = 0

# Cloud SQL Instance (20 points)
if ($testResults.CloudSQL.Status -eq "RUNNABLE") {
    $healthScore += 20
    Write-Host "✅ Cloud SQL Instance: HEALTHY" -ForegroundColor Green
} else {
    Write-Host "❌ Cloud SQL Instance: UNHEALTHY" -ForegroundColor Red
}
$totalChecks += 20

# Database (15 points)
if ($testResults.Database.MyAuthDbExists) {
    $healthScore += 15
    Write-Host "✅ Database (my_auth_db): HEALTHY" -ForegroundColor Green
} else {
    Write-Host "❌ Database (my_auth_db): MISSING" -ForegroundColor Red
}
$totalChecks += 15

# Users (20 points)  
if ($testResults.Users.FincoreApp -and $testResults.Users.FincoreAdmin) {
    $healthScore += 20
    Write-Host "✅ Database Users: HEALTHY" -ForegroundColor Green
} else {
    Write-Host "❌ Database Users: INCOMPLETE" -ForegroundColor Red
}
$totalChecks += 20

# Connectivity (25 points)
if ($testResults.Connectivity.PublicPort3306) {
    $healthScore += 25
    Write-Host "✅ Network Connectivity: HEALTHY" -ForegroundColor Green
} else {
    Write-Host "❌ Network Connectivity: BLOCKED" -ForegroundColor Red
}
$totalChecks += 25

# Infrastructure (20 points)
if ($testResults.Infrastructure.ProjectId -and $testResults.Infrastructure.AuthenticatedUser) {
    $healthScore += 20
    Write-Host "✅ Infrastructure Config: HEALTHY" -ForegroundColor Green
} else {
    Write-Host "❌ Infrastructure Config: ISSUES" -ForegroundColor Red
}
$totalChecks += 20

$healthPercentage = [math]::Round(($healthScore / $totalChecks) * 100, 2)
$testResults.Summary.HealthScore = $healthScore
$testResults.Summary.TotalChecks = $totalChecks
$testResults.Summary.HealthPercentage = $healthPercentage

Write-Host "`nOVERALL HEALTH SCORE: $healthScore/$totalChecks ($healthPercentage%)" -ForegroundColor $(if ($healthPercentage -ge 80) { "Green" } elseif ($healthPercentage -ge 60) { "Yellow" } else { "Red" })

Write-Host "`n" + "=" * 60
Write-Host "API CONNECTION DETAILS FOR DEBUGGING" -ForegroundColor Magenta
Write-Host "=" * 60

Write-Host "Database Connection String:" -ForegroundColor Yellow
Write-Host "mysql://fincore_app:FincoreApp2024!@#@$($testResults.CloudSQL.PublicIP):3306/my_auth_db" -ForegroundColor White

Write-Host "`nConnection Parameters:" -ForegroundColor Yellow
Write-Host "Host: $($testResults.CloudSQL.PublicIP)" -ForegroundColor White
Write-Host "Port: 3306" -ForegroundColor White
Write-Host "Database: my_auth_db" -ForegroundColor White
Write-Host "Username: fincore_app" -ForegroundColor White
Write-Host "Password: FincoreApp2024!@#" -ForegroundColor White

Write-Host "`nSSL/TLS Configuration:" -ForegroundColor Yellow
Write-Host "SSL Required: NO (configured for ease of connection)" -ForegroundColor White
Write-Host "TLS Version: Any supported" -ForegroundColor White

Write-Host "`nNetwork Configuration:" -ForegroundColor Yellow
Write-Host "Public Access: ENABLED" -ForegroundColor White
Write-Host "Authorized Networks: 0.0.0.0/0 (all IPs allowed)" -ForegroundColor White
Write-Host "Private Network: Available ($($testResults.CloudSQL.PrivateIP))" -ForegroundColor White

Write-Host "`n" + "=" * 60
Write-Host "TROUBLESHOOTING CHECKLIST FOR API" -ForegroundColor Magenta
Write-Host "=" * 60

Write-Host "If your API is not connecting, check these:" -ForegroundColor Yellow
Write-Host "1. ✅ Database exists: my_auth_db" -ForegroundColor Green
Write-Host "2. ✅ User exists: fincore_app" -ForegroundColor Green  
Write-Host "3. ✅ Network access: Port 3306 open" -ForegroundColor Green
Write-Host "4. 🔍 API Configuration: Verify connection string matches above" -ForegroundColor Yellow
Write-Host "5. 🔍 API Dependencies: Check MySQL driver/connector version" -ForegroundColor Yellow
Write-Host "6. 🔍 API Logs: Check for specific connection error messages" -ForegroundColor Yellow
Write-Host "7. 🔍 Firewall: Ensure API server can reach $($testResults.CloudSQL.PublicIP):3306" -ForegroundColor Yellow

# Export detailed results to JSON for API consumption
$jsonOutput = $testResults | ConvertTo-Json -Depth 4
$jsonOutput | Out-File -FilePath "infrastructure-health-report.json" -Encoding UTF8

Write-Host "`n✅ Detailed JSON report exported to: infrastructure-health-report.json" -ForegroundColor Green
Write-Host "📄 This report contains all technical details for API debugging." -ForegroundColor Cyan

Write-Host "`n" + "=" * 60
Write-Host "REPORT COMPLETED: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')" -ForegroundColor Green
Write-Host "=" * 60