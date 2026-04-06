# 启用Windows防火墙规则，允许8080端口入站连接
# 需要以管理员身份运行此脚本

Write-Host "正在添加防火墙规则..." -ForegroundColor Yellow

try {
    netsh advfirewall firewall add rule name="Spring Boot 8080" dir=in action=allow protocol=TCP localport=8080
    Write-Host "✓ 防火墙规则添加成功！" -ForegroundColor Green
    Write-Host "  规则名称: Spring Boot 8080" -ForegroundColor Cyan
    Write-Host "  端口: 8080" -ForegroundColor Cyan
    Write-Host "  协议: TCP" -ForegroundColor Cyan
} catch {
    Write-Host "✗ 添加防火墙规则失败: $_" -ForegroundColor Red
    Write-Host "  请确保以管理员身份运行此脚本" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
