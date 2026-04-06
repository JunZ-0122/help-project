# HarmonyOS 应用重新编译脚本
# 使用方法: .\rebuild.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HarmonyOS 应用重新编译脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 步骤 1: 清理缓存
Write-Host "[1/3] 清理构建缓存..." -ForegroundColor Yellow
Remove-Item -Recurse -Force .hvigor\cache -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force entry\.preview -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force entry\build -ErrorAction SilentlyContinue
Write-Host "✓ 缓存清理完成" -ForegroundColor Green
Write-Host ""

# 步骤 2: 清理项目
Write-Host "[2/3] 清理项目..." -ForegroundColor Yellow
& "$PSScriptRoot\\hvigorw.cmd" clean
Write-Host "✓ 项目清理完成" -ForegroundColor Green
Write-Host ""

# 步骤 3: 重新构建
Write-Host "[3/3] 重新构建项目..." -ForegroundColor Yellow
& "$PSScriptRoot\\hvigorw.cmd" assembleHap
Write-Host "✓ 项目构建完成" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  重新编译完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步操作：" -ForegroundColor Yellow
Write-Host "1. 在 DevEco Studio 中停止当前运行的应用" -ForegroundColor White
Write-Host "2. 点击 Run 按钮（绿色三角形）重新运行" -ForegroundColor White
Write-Host "3. 或按快捷键 Shift+F10" -ForegroundColor White
Write-Host ""
