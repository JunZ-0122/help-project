# 更新统计数据脚本
Write-Host "=== 更新统计测试数据 ===" -ForegroundColor Green

# 数据库配置
$dbHost = "localhost"
$dbPort = "3306"
$dbName = "help"
$dbUser = "root"
$dbPassword = "123456"

Write-Host "`n1. 执行SQL脚本插入测试数据..." -ForegroundColor Yellow

# 执行SQL脚本
$sqlFile = "insert_statistics_test_data.sql"
if (Test-Path $sqlFile) {
    mysql -h $dbHost -P $dbPort -u $dbUser -p$dbPassword $dbName < $sqlFile
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ 测试数据插入成功" -ForegroundColor Green
    } else {
        Write-Host "   ✗ 测试数据插入失败" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "   ✗ SQL文件不存在: $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. 重新编译后端项目..." -ForegroundColor Yellow
mvn clean compile -DskipTests
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ 后端编译成功" -ForegroundColor Green
} else {
    Write-Host "   ✗ 后端编译失败" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== 更新完成 ===" -ForegroundColor Green
Write-Host "`n现在可以启动后端服务:" -ForegroundColor Cyan
Write-Host "  mvn spring-boot:run" -ForegroundColor White
Write-Host "`n然后重新编译前端应用查看效果" -ForegroundColor Cyan
