# resume_optimizer.ps1
# Main script for resume optimization

param(
    [Parameter(Mandatory=$false)]
    [string]$ResumePath,
    
    [Parameter(Mandatory=$false)]
    [string]$JobDescriptionPath,
    
    [Parameter(Mandatory=$false)]
    [string]$JobDescriptionText,
    
    [switch]$Interactive,
    [switch]$Help
)

# Change to script directory
Set-Location $PSScriptRoot\..

if ($Help) {
    # Import module just for help
    Import-Module -Name ".\modules\ResumeOptimizer.psm1" -Force
    Show-Help
    exit 0
}

# Import module
try {
    Import-Module -Name ".\modules\ResumeOptimizer.psm1" -Force
}
catch {
    Write-Host "Error loading module: $_" -ForegroundColor Red
    Write-Host "Please ensure the module file exists at: .\modules\ResumeOptimizer.psm1" -ForegroundColor Yellow
    exit 1
}

if ($Interactive) {
    Start-InteractiveMode
} else {
    if (-not $ResumePath -or (-not $JobDescriptionPath -and -not $JobDescriptionText)) {
        Write-Host "Missing required parameters." -ForegroundColor Red
        Write-Host "Use -Interactive mode or provide all parameters:" -ForegroundColor Yellow
        Write-Host "  -ResumePath <path> -JobDescriptionPath <path>" -ForegroundColor White
        Write-Host "  -ResumePath <path> -JobDescriptionText <text>" -ForegroundColor White
        exit 1
    }
    
    try {
        $result = Optimize-Resume -ResumePath $ResumePath -JobDescriptionPath $JobDescriptionPath -JobDescriptionText $JobDescriptionText
        Export-OptimizedResume -Result $result
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }
}
