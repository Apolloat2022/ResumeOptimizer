# backend.ps1 - Simple HTTP Server for Resume Optimizer

Write-Host "Resume Optimizer Web Server" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host "Starting server on http://localhost:5000" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow

# Import modules if they exist
try {
    Import-Module .\modules\ResumeOptimizer.psm1 -ErrorAction SilentlyContinue
    Write-Host "✓ Loaded ResumeOptimizer module" -ForegroundColor Green
} catch {
    Write-Host "! Could not load ResumeOptimizer module" -ForegroundColor Yellow
}

try {
    # Create HTTP listener
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:5000/")
    $listener.Start()
    
    Write-Host "`nServer is running! Open http://localhost:5000 in your browser." -ForegroundColor Green
    Write-Host "`nWaiting for requests..." -ForegroundColor Gray
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        # Log request
        Write-Host "$(Get-Date -Format 'HH:mm:ss') - $($request.HttpMethod) $($request.Url.LocalPath)" -ForegroundColor Cyan
        
        # Set CORS headers
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        
        # Route requests
        $path = $request.Url.LocalPath
        
        if ($path -eq "/" -or $path -eq "/index.html") {
            # Serve index.html
            $filePath = ".\web_interface\index.html"
            if (Test-Path $filePath) {
                $content = Get-Content -Path $filePath -Raw
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
                $response.ContentType = "text/html"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        }
        elseif ($path -eq "/style.css") {
            # Serve style.css
            $filePath = ".\web_interface\style.css"
            if (Test-Path $filePath) {
                $content = Get-Content -Path $filePath -Raw
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
                $response.ContentType = "text/css"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        }
        elseif ($path -eq "/app.js") {
            # Serve app.js
            $filePath = ".\web_interface\app.js"
            if (Test-Path $filePath) {
                $content = Get-Content -Path $filePath -Raw
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
                $response.ContentType = "application/javascript"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        }
        elseif ($path -eq "/optimize" -and $request.HttpMethod -eq "POST") {
            # Handle optimization request (demo mode)
            $responseData = @{
                success = $true
                message = "Demo mode: Processing would happen here"
                matchScore = 78
                keywords = @("JavaScript", "React", "Node.js", "AWS")
                suggestions = @("Add Docker to skills", "Quantify achievements")
            } | ConvertTo-Json
            
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseData)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        else {
            # 404 for other paths
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("404 - Not Found")
            $response.StatusCode = 404
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
    }
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    if ($listener) {
        $listener.Stop()
        $listener.Close()
    }
    Write-Host "`nServer stopped." -ForegroundColor Yellow
}
