# setup-web.ps1 - Setup script for web interface

Write-Host "Setting up Resume Optimizer Web Interface" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Create directory structure
$directories = @("web_interface", "uploads", "outputs", "logs")

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "✓ Created directory: $dir" -ForegroundColor Green
    } else {
        Write-Host "✓ Directory exists: $dir" -ForegroundColor Gray
    }
}

# Check for existing web interface files
Write-Host "`nChecking for web interface files..." -ForegroundColor Cyan

$webFiles = @("index.html", "style.css", "app.js")
$createdCount = 0

foreach ($file in $webFiles) {
    $path = ".\web_interface\$file"
    if (-not (Test-Path $path)) {
        Write-Host "✗ Missing: $file" -ForegroundColor Yellow
    } else {
        Write-Host "✓ Found: $file" -ForegroundColor Green
        $createdCount++
    }
}

# Check if backend.ps1 exists
if (Test-Path ".\backend.ps1") {
    Write-Host "✓ Found backend.ps1" -ForegroundColor Green
} else {
    Write-Host "✗ Missing backend.ps1" -ForegroundColor Yellow
}

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Cyan

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Write-Host "✓ PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Green
} else {
    Write-Host "✗ PowerShell 5.1+ required (you have $($PSVersionTable.PSVersion))" -ForegroundColor Red
}

# Check execution policy
try {
    Get-ExecutionPolicy -Scope CurrentUser | Out-Null
    Write-Host "✓ Execution policy is set" -ForegroundColor Green
} catch {
    Write-Host "! May need to set execution policy" -ForegroundColor Yellow
}

# Summary
Write-Host "`n" + ("="*50) -ForegroundColor Cyan
Write-Host "SETUP COMPLETE" -ForegroundColor Cyan
Write-Host "="*50 -ForegroundColor Cyan

if ($createdCount -eq 0) {
    Write-Host "`nNo web interface files found." -ForegroundColor Yellow
    Write-Host "You need to create:" -ForegroundColor White
    Write-Host "  1. web_interface\index.html" -ForegroundColor Yellow
    Write-Host "  2. web_interface\style.css" -ForegroundColor Yellow
    Write-Host "  3. web_interface\app.js" -ForegroundColor Yellow
    Write-Host "  4. backend.ps1 (in main folder)" -ForegroundColor Yellow
    Write-Host "`nRun the creation scripts I provided to create these files." -ForegroundColor White
} elseif ($createdCount -lt 3) {
    Write-Host "`nSome web interface files are missing." -ForegroundColor Yellow
    Write-Host "Run the creation scripts for missing files." -ForegroundColor White
} else {
    Write-Host "`nWeb interface setup is ready!" -ForegroundColor Green
}

Write-Host "`nTo start the web interface after creating files:" -ForegroundColor White
Write-Host "1. Run the backend server:" -ForegroundColor Yellow
Write-Host "   .\backend.ps1" -ForegroundColor Green
Write-Host "2. Open your browser and go to:" -ForegroundColor Yellow
Write-Host "   http://localhost:5000" -ForegroundColor Green

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
