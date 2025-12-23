@echo off
echo Resume Optimizer Setup
echo ======================
echo.
echo 1. Checking PowerShell...
powershell -Command "if ($PSVersionTable.PSVersion.Major -ge 5) { Write-Host '? PowerShell 5.1+' -ForegroundColor Green } else { Write-Host '? Update PowerShell' -ForegroundColor Red }"

echo.
echo 2. Setting execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"

echo.
echo 3. Ready to run!
echo    Open PowerShell and run:
echo    .\scripts\resume_optimizer.ps1 -Interactive
echo.
pause
