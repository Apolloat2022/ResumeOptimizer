Write-Host "Resume Optimizer - First Time Setup" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host "`nChecking system requirements..." -ForegroundColor Yellow

$issues = @()

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    $issues += "PowerShell 5.1 or higher required (you have $($PSVersionTable.PSVersion))"
} else {
    Write-Host "✓ PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Green
}

# Check .NET for DOCX parsing
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
    Write-Host "✓ .NET Framework available for DOCX parsing" -ForegroundColor Green
} catch {
    $issues += ".NET Framework 4.5+ required for DOCX files"
}

# Set execution policy
Write-Host "`nSetting execution policy..." -ForegroundColor Yellow
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
    Write-Host "✓ Execution policy set" -ForegroundColor Green
} catch {
    $issues += "Could not set execution policy. Run PowerShell as Administrator."
}

# Create required directories
@("outputs", "logs", "libs", "templates") | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Host "✓ Created $_ directory" -ForegroundColor Green
    }
}

# Show results
if ($issues.Count -eq 0) {
    Write-Host "`n" + ("="*50) -ForegroundColor Green
    Write-Host "SETUP COMPLETE!" -ForegroundColor Green
    Write-Host ("="*50) -ForegroundColor Green
    Write-Host "`nTo start:" -ForegroundColor White
    Write-Host "1. Double-click Launch.bat" -ForegroundColor Yellow
    Write-Host "2. Or run: .\scripts\resume_optimizer.ps1 -Interactive" -ForegroundColor Yellow
} else {
    Write-Host "`n" + ("="*50) -ForegroundColor Red
    Write-Host "SETUP ISSUES FOUND" -ForegroundColor Red
    Write-Host ("="*50) -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "• $issue" -ForegroundColor Red
    }
    Write-Host "`nPlease fix these issues and run setup again." -ForegroundColor Yellow
}

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
