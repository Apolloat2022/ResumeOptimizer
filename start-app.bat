@echo off
echo ========================================
echo     OPTiRESUME AI - Startup Script
echo ========================================
echo.

echo [1/2] Starting Backend Server...
start "OptiResume Backend" cmd /c "node server.js"

echo [2/2] Starting Frontend (Vite)...
cd client
start "OptiResume Frontend" cmd /c "npm run dev"

echo.
echo ========================================
echo   Application is starting!
echo   1. Backend: http://localhost:5000
echo   2. Frontend: http://localhost:5173 (check window)
echo ========================================
pause
