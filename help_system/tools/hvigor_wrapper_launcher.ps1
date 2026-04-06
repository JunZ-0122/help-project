$ErrorActionPreference = 'Stop'

$projectDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$projectName = Split-Path $projectDir -Leaf
$sandboxRoot = 'C:\Users\CodexSandboxOnline\.codex\.sandbox\cwd'

if (Test-Path $sandboxRoot) {
  Get-ChildItem $sandboxRoot -Directory | ForEach-Object {
    $candidate = Join-Path $_.FullName $projectName
    if (Test-Path (Join-Path $candidate 'tools\hvigor_wrapper_local.js')) {
      $projectDir = $candidate
    }
  }
}

$devecoStudioHome = 'D:\Huawei\DevEco Studio'
$nodeExe = Join-Path $devecoStudioHome 'tools\node\node.exe'
$hvigorBin = Join-Path $devecoStudioHome 'tools\hvigor\bin'
$ohpmBin = Join-Path $devecoStudioHome 'tools\ohpm\bin'
$launcherScript = Join-Path $projectDir 'tools\hvigor_wrapper_local.js'

if (-not (Test-Path $nodeExe)) {
  Write-Error "Node executable not found at $nodeExe"
}

if (-not (Test-Path $launcherScript)) {
  Write-Error "Local hvigor launcher not found at $launcherScript"
}

$env:DEVECO_STUDIO_HOME = $devecoStudioHome
$env:DEVECO_SDK_HOME = Join-Path $devecoStudioHome 'sdk'
$env:NODE_HOME = Join-Path $devecoStudioHome 'tools\node'
$env:HOME = $projectDir
$env:USERPROFILE = $projectDir
$env:HVIGOR_USER_HOME = Join-Path $projectDir '.hvigor_local'
$env:NPM_CONFIG_CACHE = Join-Path $projectDir '.npm-cache-local'
$env:npm_config_cache = $env:NPM_CONFIG_CACHE
$env:PATH = "$hvigorBin;$($env:NODE_HOME);$ohpmBin;$($env:PATH)"

Set-Location $projectDir

$bootstrap = @"
const fs = require('fs');
const path = require('path');
const Module = require('module');
const scriptPath = process.argv[1];
const scriptCode = fs.readFileSync(scriptPath, 'utf8');
const scriptModule = new Module(scriptPath, module);
scriptModule.filename = scriptPath;
scriptModule.paths = Module._nodeModulePaths(path.dirname(scriptPath));
scriptModule._compile(scriptCode, scriptPath);
"@

& $nodeExe -e $bootstrap $launcherScript @args
exit $LASTEXITCODE
