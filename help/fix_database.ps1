# 修复数据库中的 user_id 字段
# 解决志愿者无法发送消息的问题

$ErrorActionPreference = "Stop"

Write-Host "=== 修复数据库 user_id 字段 ===" -ForegroundColor Cyan
Write-Host ""

# 数据库配置
$dbHost = "localhost"
$dbPort = "3306"
$dbName = "help"
$dbUser = "root"
$dbPassword = "123456"

Write-Host "步骤 1: 检查当前数据状态" -ForegroundColor Yellow

# 检查 MySQL 是否可用
try {
    $checkQuery = "SELECT COUNT(*) as count FROM help_requests WHERE user_id IS NULL;"
    $result = mysql -h $dbHost -P $dbPort -u $dbUser -p$dbPassword $dbName -e $checkQuery 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ 无法连接到数据库" -ForegroundColor Red
        Write-Host "请确保 MySQL 服务正在运行" -ForegroundColor Yellow
        Write-Host "数据库配置: $dbHost:$dbPort/$dbName" -ForegroundColor Gray
        exit 1
    }
    
    Write-Host "✓ 数据库连接成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 数据库连接失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "步骤 2: 查找 user_id 为 NULL 的记录" -ForegroundColor Yellow

$findNullQuery = @"
SELECT id, title, status, user_name 
FROM help_requests 
WHERE user_id IS NULL;
"@

$nullRecords = mysql -h $dbHost -P $dbPort -u $dbUser -p$dbPassword $dbName -e $findNullQuery 2>&1

if ($nullRecords -match "id\s+title") {
    Write-Host "找到以下记录的 user_id 为 NULL:" -ForegroundColor Yellow
    Write-Host $nullRecords -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "步骤 3: 修复 user_id 字段" -ForegroundColor Yellow
    
    $fixQuery = "UPDATE help_requests SET user_id = 'user001' WHERE user_id IS NULL;"
    mysql -h $dbHost -P $dbPort -u $dbUser -p$dbPassword $dbName -e $fixQuery 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ user_id 字段已修复" -ForegroundColor Green
    } else {
        Write-Host "✗ 修复失败" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✓ 没有找到 user_id 为 NULL 的记录" -ForegroundColor Green
}

Write-Host ""
Write-Host "步骤 4: 验证修复结果" -ForegroundColor Yellow

$verifyQuery = @"
SELECT id, user_id, user_name, volunteer_id, title, status 
FROM help_requests 
WHERE status IN ('assigned', 'in-progress') 
ORDER BY created_at DESC 
LIMIT 5;
"@

$verifyResult = mysql -h $dbHost -P $dbPort -u $dbUser -p$dbPassword $dbName -e $verifyQuery 2>&1
Write-Host $verifyResult -ForegroundColor Gray

Write-Host ""
Write-Host "步骤 5: 检查是否还有空值" -ForegroundColor Yellow

$countQuery = "SELECT COUNT(*) as null_count FROM help_requests WHERE user_id IS NULL;"
$countResult = mysql -h $dbHost -P $dbPort -u $dbUser -p$dbPassword $dbName -e $countQuery 2>&1

if ($countResult -match "0") {
    Write-Host "✓ 所有记录的 user_id 都已设置" -ForegroundColor Green
} else {
    Write-Host "⚠ 仍有记录的 user_id 为 NULL" -ForegroundColor Yellow
    Write-Host $countResult -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== 修复完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "下一步:" -ForegroundColor Cyan
Write-Host "1. 重新运行前端应用" -ForegroundColor Gray
Write-Host "2. 以志愿者身份登录" -ForegroundColor Gray
Write-Host "3. 进入聊天页面" -ForegroundColor Gray
Write-Host "4. 尝试发送消息" -ForegroundColor Gray
Write-Host "5. 查看日志输出，应该看到 targetUserId 不再为空" -ForegroundColor Gray
