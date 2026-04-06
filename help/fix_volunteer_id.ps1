# 修复 volunteer_id 字段的 PowerShell 脚本

Write-Host "开始修复 volunteer_id 字段..." -ForegroundColor Green

# 执行 SQL 脚本
mysql -u root -p help < fix_volunteer_id.sql

if ($LASTEXITCODE -eq 0) {
    Write-Host "修复成功！" -ForegroundColor Green
} else {
    Write-Host "修复失败，请检查错误信息" -ForegroundColor Red
}

Write-Host "`n按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
