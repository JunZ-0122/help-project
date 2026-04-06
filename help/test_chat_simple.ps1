# Simple Chat Test Script
$ErrorActionPreference = "Stop"

$baseUrl = "http://localhost:8080/api"

Write-Host "=== Chat WebSocket Test ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Login as seeker
Write-Host "Step 1: Seeker login" -ForegroundColor Yellow
$seekerBody = @{
    phone = "13800138001"
    password = "123456"
} | ConvertTo-Json

$seekerResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -ContentType "application/json" -Body $seekerBody
$seekerToken = $seekerResponse.data.token
$seekerId = $seekerResponse.data.user.id
Write-Host "Success: Seeker ID = $seekerId" -ForegroundColor Green

# Step 2: Login as volunteer
Write-Host ""
Write-Host "Step 2: Volunteer login" -ForegroundColor Yellow
$volunteerBody = @{
    phone = "13800138002"
    password = "123456"
} | ConvertTo-Json

$volunteerResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -ContentType "application/json" -Body $volunteerBody
$volunteerToken = $volunteerResponse.data.token
$volunteerId = $volunteerResponse.data.user.id
Write-Host "Success: Volunteer ID = $volunteerId" -ForegroundColor Green

# Step 3: Get first request
Write-Host ""
Write-Host "Step 3: Get help request" -ForegroundColor Yellow
$headers = @{ "Authorization" = "Bearer $seekerToken" }
$requestsUrl = "$baseUrl/help-requests/my-requests" + "?page=1" + "&size=10"
$requestsResponse = Invoke-RestMethod -Uri $requestsUrl -Method GET -Headers $headers
$requestId = $requestsResponse.data.records[0].id
Write-Host "Success: Request ID = $requestId" -ForegroundColor Green

# Step 4: Send message from seeker
Write-Host ""
Write-Host "Step 4: Seeker sends message" -ForegroundColor Yellow
$timestamp = Get-Date -Format "HH:mm:ss"
$messageBody = @{
    requestId = $requestId
    receiverId = $volunteerId
    text = "Hello, I need help! (Test at $timestamp)"
    type = "text"
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $seekerToken"
    "Content-Type" = "application/json"
}
$sendResponse = Invoke-RestMethod -Uri "$baseUrl/chat-messages/send" -Method POST -Headers $headers -Body $messageBody
Write-Host "Success: Message ID = $($sendResponse.data.id)" -ForegroundColor Green
Write-Host "Message: $($sendResponse.data.text)" -ForegroundColor Gray

# Step 5: Volunteer gets chat history
Write-Host ""
Write-Host "Step 5: Volunteer gets chat history" -ForegroundColor Yellow
Start-Sleep -Seconds 1
$headers = @{ "Authorization" = "Bearer $volunteerToken" }
$historyUrl = "$baseUrl/chat-messages/history" + "?requestId=$requestId" + "&page=1"
$historyResponse = Invoke-RestMethod -Uri $historyUrl -Method GET -Headers $headers
$messages = $historyResponse.data.records
Write-Host "Success: Found $($messages.Count) messages" -ForegroundColor Green

# Step 6: Volunteer replies
Write-Host ""
Write-Host "Step 6: Volunteer replies" -ForegroundColor Yellow
$timestamp = Get-Date -Format "HH:mm:ss"
$replyBody = @{
    requestId = $requestId
    receiverId = $seekerId
    text = "Got it! I will help you. (Reply at $timestamp)"
    type = "text"
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $volunteerToken"
    "Content-Type" = "application/json"
}
$replyResponse = Invoke-RestMethod -Uri "$baseUrl/chat-messages/send" -Method POST -Headers $headers -Body $replyBody
Write-Host "Success: Reply ID = $($replyResponse.data.id)" -ForegroundColor Green
Write-Host "Reply: $($replyResponse.data.text)" -ForegroundColor Gray

# Step 7: Verify messages
Write-Host ""
Write-Host "Step 7: Verify all messages" -ForegroundColor Yellow
Start-Sleep -Seconds 1
$headers = @{ "Authorization" = "Bearer $seekerToken" }
$finalUrl = "$baseUrl/chat-messages/history" + "?requestId=$requestId" + "&page=1"
$finalResponse = Invoke-RestMethod -Uri $finalUrl -Method GET -Headers $headers
$finalMessages = $finalResponse.data.records
Write-Host "Success: Total $($finalMessages.Count) messages" -ForegroundColor Green

Write-Host ""
Write-Host "Recent conversation:" -ForegroundColor Cyan
$finalMessages | Select-Object -Last 5 | ForEach-Object {
    $time = ([DateTime]$_.createdAt).ToString("HH:mm:ss")
    Write-Host "  [$time] $($_.senderName): $($_.text)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "WebSocket Info:" -ForegroundColor Cyan
Write-Host "  Endpoint: ws://localhost:8080/ws/chat?token=<JWT_TOKEN>" -ForegroundColor Gray
Write-Host "  Messages are pushed in real-time via WebSocket" -ForegroundColor Gray
Write-Host "  Open ChatPage in the app to see real-time updates" -ForegroundColor Gray
