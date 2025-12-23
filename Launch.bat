@echo off
echo ========================================
echo     RESUME OPTIMIZER - AI Assistant
echo ========================================
echo.
echo This tool will help optimize your resume
echo for specific job descriptions.
echo.
echo [1] Interactive Mode (Recommended)
echo [2] Quick Test with Sample Files
echo [3] View Documentation
echo [4] Exit
echo.
set /p choice="Select option (1-4): "

if "%choice%"=="1" (
    echo Starting interactive mode...
    powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\resume_optimizer.ps1" -Interactive
    pause
) else if "%choice%"=="2" (
    echo Running test with sample files...
    powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\resume_optimizer.ps1" -ResumePath "test_files\sample_resume.txt" -JobDescriptionPath "test_files\test_jd.txt"
    pause
) else if "%choice%"=="3" (
    start "" "README.md"
    exit
) else (
    exit
)
