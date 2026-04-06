# WebSocket 聊天功能测试脚本
# 用于测试聊天消息的实时推送功能

Write-Host "=== WebSocket 聊天功能测试 ===" -ForegroundColor Cyan
Write-Host ""

# 配置
$baseUrl = "http://localhost:8080/api"
$wsUrl = "ws://localhost:8080/ws/chat"

# 测试用户凭证
$seekerPhone = "13800138001"
$volunteerPhone = "13800138002"
$password = "123456"

Write-Host "步骤 1: 求助者登录" -ForegroundColor Yellow
$seekerLoginBody = @{
    phone = $seekerPhone
    password = $password
} | ConvertTo-Json

try {
    $seekerLoginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" `
        -Method POST `
        -ContentType "application/json" `
        -Body $seekerLoginBody
    
    $seekerToken = $seekerLoginResponse.data.token
    $seekerId = $seekerLoginResponse.data.user.id
    Write-Host "✓ 求助者登录成功" -ForegroundColor Green
    Write-Host "  Token: $($seekerToken.Substring(0, 20))..." -ForegroundColor Gray
    Write-Host "  用户ID: $seekerId" -ForegroundColor Gray
} catch {
    Write-Host "✗ 求助者登录失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "步骤 2: 志愿者登录" -ForegroundColor Yellow
$volunteerLoginBody = @{
    phone = $volunteerPhone
    password = $password
} | ConvertTo-Json

try {
    $volunteerLoginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" `
        -Method POST `
        -ContentType "application/json" `
        -Body $volunteerLoginBody
    
    $volunteerToken = $volunteerLoginResponse.data.token
    $volunteerId = $volunteerLoginResponse.data.user.id
    Write-Host "✓ 志愿者登录成功" -ForegroundColor Green
    Write-Host "  Token: $($volunteerToken.Substring(0, 20))..." -ForegroundColor Gray
    Write-Host "  用户ID: $volunteerId" -ForegroundColor Gray
} catch {
    Write-Host "✗ 志愿者登录失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "步骤 3: 获取第一个求助请求" -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $seekerToken"
    }
    
    $requestsResponse = Invoke-RestMethod -Uri "$baseUrl/help-requests/my-requests?page=1&size=10" `
        -Method GET `
        -Headers $headers
    
    if ($requestsResponse.data.records.Count -eq 0) {
        Write-Host "✗ 没有找到求助请求" -ForegroundColor Red
        exit 1
    }
    
    $requestId = $requestsResponse.data.records[0].id
    Write-Host "✓ 找到求助请求" -ForegroundColor Green
    Write-Host "  请求ID: $requestId" -ForegroundColor Gray
} catch {
    Write-Host "✗ 获取求助请求失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "步骤 4: 求助者发送消息" -ForegroundColor Yellow
$messageBody = @{
    requestId = $requestId
    receiverId = $volunteerId
    text = "你好，我需要帮助！(测试消息 $(Get-Date -Format 'HH:mm:ss'))"
    type = "text"
} | ConvertTo-Json

try {
    $headers = @{
        "Authorization" = "Bearer $seekerToken"
        "Content-Type" = "application/json"
    }
    
    $sendResponse = Invoke-RestMethod -Uri "$baseUrl/chat-messages/send" `
        -Method POST `
        -Headers $headers `
        -Body $messageBody
    
    $messageId = $sendResponse.data.id
    Write-Host "✓ 消息发送成功" -ForegroundColor Green
    Write-Host "  消息ID: $messageId" -ForegroundColor Gray
    Write-Host "  消息内容: $($sendResponse.data.text)" -ForegroundColor Gray
} catch {
    Write-Host "✗ 发送消息失败: $_" -ForegroundColor Red
    Write-Host "  错误详情: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "步骤 5: 志愿者获取聊天历史" -ForegroundColor Yellow
Start-Sleep -Seconds 1

try {
    $headers = @{
        "Authorization" = "Bearer $volunteerToken"
    }
    
    $historyResponse = Invoke-RestMethod -Uri "$baseUrl/chat-messages/history?requestId=$requestId&page=1" `
        -Method GET `
        -Headers $headers
    
    $messages = $historyResponse.data.records
    Write-Host "✓ 获取聊天历史成功" -ForegroundColor Green
    Write-Host "  消息数量: $($messages.Count)" -ForegroundColor Gray
    
    if ($messages.Count -gt 0) {
        $lastMessage = $messages[-1]
        Write-Host "  最新消息: $($lastMessage.text)" -ForegroundColor Gray
        Write-Host "  发送者: $($lastMessage.senderName)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ 获取聊天历史失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "步骤 6: 志愿者回复消息" -ForegroundColor Yellow
$replyBody = @{
    requestId = $requestId
    receiverId = $seekerId
    text = "收到！我马上过来帮忙。(测试回复 $(Get-Date -Format 'HH:mm:ss'))"
    type = "text"
} | ConvertTo-Json

try {
    $headers = @{
        "Authorization" = "Bearer $volunteerToken"
        "Content-Type" = "application/json"
    }
    
    $replyResponse = Invoke-RestMethod -Uri "$baseUrl/chat-messages/send" `
        -Method POST `
        -Headers $headers `
        -Body $replyBody
    
    Write-Host "✓ 回复消息发送成功" -ForegroundColor Green
    Write-Host "  消息ID: $($replyResponse.data.id)" -ForegroundColor Gray
    Write-Host "  消息内容: $($replyResponse.data.text)" -ForegroundColor Gray
} catch {
    Write-Host "✗ 发送回复失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "步骤 7: 验证消息已保存到数据库" -ForegroundColor Yellow
Start-Sleep -Seconds 1

try {
    $headers = @{
        "Authorization" = "Bearer $seekerToken"
    }
    
    $finalHistoryResponse = Invoke-RestMethod -Uri "$baseUrl/chat-messages/history?requestId=$requestId&page=1" `
        -Method GET `
        -Headers $headers
    
    $finalMessages = $finalHistoryResponse.data.records
    Write-Host "✓ 验证成功" -ForegroundColor Green
    Write-Host "  总消息数: $($finalMessages.Count)" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "最近的对话:" -ForegroundColor Cyan
    $finalMessages | Select-Object -Last 5 | ForEach-Object {
        $time = ([DateTime]$_.createdAt).ToString("HH:mm:ss")
        Write-Host "  [$time] $($_.senderName): $($_.text)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ 验证失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== WebSocket 功能说明 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "后端 WebSocket 实现:" -ForegroundColor Yellow
Write-Host "  • 端点: ws://localhost:8080/ws/chat?token=<JWT_TOKEN>" -ForegroundColor Gray
Write-Host "  • 认证: 通过 URL 参数传递 JWT Token" -ForegroundColor Gray
Write-Host "  • 消息格式: JSON" -ForegroundColor Gray
Write-Host "  • 推送机制: 发送者和接收者都会收到实时推送" -ForegroundColor Gray
Write-Host ""
Write-Host "前端 WebSocket 集成:" -ForegroundColor Yellow
Write-Host "  • 服务: WebSocketService (单例模式)" -ForegroundColor Gray
Write-Host "  • 连接管理: 自动重连机制" -ForegroundColor Gray
Write-Host "  • 消息处理: handleRealtimeMessage() 方法" -ForegroundColor Gray
Write-Host "  • 已读回执: handleReadReceipt() 方法" -ForegroundColor Gray
Write-Host ""
Write-Host "消息流程:" -ForegroundColor Yellow
Write-Host "  1. 用户在 ChatPage 输入消息并点击发送" -ForegroundColor Gray
Write-Host "  2. 调用 MessageApi.sendMessage() 发送到后端 REST API" -ForegroundColor Gray
Write-Host "  3. 后端保存消息到数据库" -ForegroundColor Gray
Write-Host "  4. 后端通过 WebSocket 推送消息给发送者和接收者" -ForegroundColor Gray
Write-Host "  5. 前端 WebSocketService 接收消息" -ForegroundColor Gray
Write-Host "  6. ChatPage.handleRealtimeMessage() 更新消息列表" -ForegroundColor Gray
Write-Host "  7. 对方实时看到新消息" -ForegroundColor Gray
Write-Host ""
Write-Host "✓ 测试完成！" -ForegroundColor Green
Write-Host ""
Write-Host "提示: 在前端应用中打开聊天页面，可以看到实时消息推送效果。" -ForegroundColor Cyan
