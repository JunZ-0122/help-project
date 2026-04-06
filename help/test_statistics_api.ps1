# Test Statistics API
# Login with test account to get Token

Write-Host "=== Test Statistics API ===" -ForegroundColor Cyan

# 1. Login to get Token
Write-Host "`n1. Login to get Token..." -ForegroundColor Yellow
$loginBody = @{
    phone = "13800138002"
    password = "123456"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://172.31.32.1:8080/api/auth/login" `
        -Method POST `
        -Body $loginBody `
        -ContentType "application/json" `
        -UseBasicParsing
    
    $token = $loginResponse.data.token
    Write-Host "Login successful, Token: $($token.Substring(0, 20))..." -ForegroundColor Green
} catch {
    Write-Host "Login failed: $_" -ForegroundColor Red
    exit 1
}

# 2. Get statistics data
Write-Host "`n2. Get statistics data..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    $statsResponse = Invoke-RestMethod -Uri "http://172.31.32.1:8080/api/community/statistics" `
        -Method GET `
        -Headers $headers `
        -UseBasicParsing
    
    Write-Host "Get statistics successful" -ForegroundColor Green
    
    # 3. Display statistics
    Write-Host "`n3. Statistics details:" -ForegroundColor Yellow
    $stats = $statsResponse.data
    
    Write-Host "`nBasic statistics:" -ForegroundColor Cyan
    Write-Host "  Total requests: $($stats.totalRequests)"
    Write-Host "  Pending: $($stats.pendingRequests)"
    Write-Host "  In progress: $($stats.inProgressRequests)"
    Write-Host "  Completed: $($stats.completedRequests)"
    Write-Host "  Total volunteers: $($stats.totalVolunteers)"
    Write-Host "  Available volunteers: $($stats.availableVolunteers)"
    
    # 4. Check new fields
    Write-Host "`nNew fields check:" -ForegroundColor Cyan
    
    if ($stats.requestTypes) {
        Write-Host "  requestTypes exists, count: $($stats.requestTypes.Count)" -ForegroundColor Green
        if ($stats.requestTypes.Count -gt 0) {
            Write-Host "    Sample data:"
            $stats.requestTypes[0] | ConvertTo-Json -Depth 3
        }
    } else {
        Write-Host "  requestTypes does not exist" -ForegroundColor Red
    }
    
    if ($stats.weeklyTrend) {
        Write-Host "  weeklyTrend exists, count: $($stats.weeklyTrend.Count)" -ForegroundColor Green
        if ($stats.weeklyTrend.Count -gt 0) {
            Write-Host "    Sample data:"
            $stats.weeklyTrend[0] | ConvertTo-Json -Depth 3
        }
    } else {
        Write-Host "  weeklyTrend does not exist" -ForegroundColor Red
    }
    
    if ($stats.topVolunteers) {
        Write-Host "  topVolunteers exists, count: $($stats.topVolunteers.Count)" -ForegroundColor Green
        if ($stats.topVolunteers.Count -gt 0) {
            Write-Host "    Sample data:"
            $stats.topVolunteers[0] | ConvertTo-Json -Depth 3
        }
    } else {
        Write-Host "  topVolunteers does not exist" -ForegroundColor Red
    }
    
    # 5. Display full JSON
    Write-Host "`nFull response data:" -ForegroundColor Yellow
    $statsResponse | ConvertTo-Json -Depth 10
    
} catch {
    Write-Host "Get statistics failed: $_" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
