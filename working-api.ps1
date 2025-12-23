# working-api.ps1 - Resume Optimizer API Server
Write-Host "========================================" -ForegroundColor Green
Write-Host "  RESUME OPTIMIZER API SERVER" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$port = 5000
$listener = $null

try {
    # Create HTTP listener
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$port/")
    $listener.Start()
    
    Write-Host "✅ API Server started on port $port" -ForegroundColor Green
    Write-Host "📡 Available endpoints:" -ForegroundColor Cyan
    Write-Host "  • POST /api/optimize" -ForegroundColor White
    Write-Host "  • GET  /api/health" -ForegroundColor White
    Write-Host "  • GET  /api/keywords" -ForegroundColor White
    Write-Host "`nWaiting for requests...`n" -ForegroundColor Gray
    
    $requestCount = 0
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $requestCount++
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $($request.HttpMethod) $($request.Url.LocalPath)" -ForegroundColor Cyan
        
        # Add CORS headers
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
        
        # Handle OPTIONS preflight
        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }
        
        $path = $request.Url.LocalPath.ToLower()
        
        # Health check
        if ($path -eq "/api/health" -or $path -eq "/api/health/") {
            $json = '{"status":"ok","service":"Resume Optimizer API","requests":' + $requestCount + '}'
            Send-JsonResponse -Response $response -Json $json -StatusCode 200
        }
        
        # Extract keywords endpoint
        elseif ($path -eq "/api/keywords" -and $request.HttpMethod -eq "POST") {
            try {
                # Read request body
                $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $body = $reader.ReadToEnd()
                $reader.Close()
                
                if ([string]::IsNullOrEmpty($body)) {
                    $json = '{"error":"Empty request body","keywords":[]}'
                    Send-JsonResponse -Response $response -Json $json -StatusCode 400
                    continue
                }
                
                # Parse JSON
                $data = $body | ConvertFrom-Json
                $text = $data.text
                
                if ([string]::IsNullOrEmpty($text)) {
                    $json = '{"error":"No text provided","keywords":[]}'
                    Send-JsonResponse -Response $response -Json $json -StatusCode 400
                    continue
                }
                
                # Extract keywords (using the function we defined)
                $keywords = Extract-KeywordsFromText -Text $text
                
                $result = @{
                    status = "success"
                    keywordCount = $keywords.Count
                    keywords = $keywords
                    originalTextLength = $text.Length
                }
                
                $json = $result | ConvertTo-Json
                Send-JsonResponse -Response $response -Json $json -StatusCode 200
                
            } catch {
                $json = '{"error":"' + $_.Exception.Message.Replace('"', "'") + '","keywords":[]}'
                Send-JsonResponse -Response $response -Json $json -StatusCode 500
            }
        }
        
        # Main optimization endpoint
        elseif ($path -eq "/api/optimize" -and $request.HttpMethod -eq "POST") {
            try {
                # Read request body
                $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $body = $reader.ReadToEnd()
                $reader.Close()
                
                if ([string]::IsNullOrEmpty($body)) {
                    $json = '{"error":"Empty request body"}' 
                    Send-JsonResponse -Response $response -Json $json -StatusCode 400
                    continue
                }
                
                # Parse JSON
                $data = $body | ConvertFrom-Json
                $resumeText = $data.resumeText
                $jobDescription = $data.jobDescription
                
                if ([string]::IsNullOrEmpty($resumeText) -or [string]::IsNullOrEmpty($jobDescription)) {
                    $json = '{"error":"Missing resumeText or jobDescription"}'
                    Send-JsonResponse -Response $response -Json $json -StatusCode 400
                    continue
                }
                
                # Calculate match score (simple example)
                $resumeWords = ($resumeText.ToLower() -split '\W+' | Where-Object { $_ -ne '' -and $_.Length -gt 3 })
                $jobWords = ($jobDescription.ToLower() -split '\W+' | Where-Object { $_ -ne '' -and $_.Length -gt 3 })
                
                $commonWords = $resumeWords | Where-Object { $_ -in $jobWords }
                $matchScore = if ($jobWords.Count -gt 0) { 
                    [math]::Round(($commonWords.Count / $jobWords.Count) * 100, 1)
                } else { 0 }
                
                # Extract keywords
                $keywords = Extract-KeywordsFromText -Text $jobDescription
                
                # Generate suggestions
                $suggestions = @()
                if ($matchScore -lt 70) {
                    $suggestions = @(
                        "Add more quantifiable achievements (increased X by Y%, reduced Z by A%)",
                        "Include specific technologies mentioned in the job description",
                        "Reorder experience to highlight the most relevant positions first"
                    )
                } elseif ($matchScore -lt 85) {
                    $suggestions = @(
                        "Add 2-3 more keywords from the job description to your skills section",
                        "Include metrics in your bullet points",
                        "Add a professional summary tailored to this specific role"
                    )
                } else {
                    $suggestions = @(
                        "Your resume is well-matched! Consider adding a cover letter",
                        "Highlight your most relevant project at the top of your experience",
                        "Double-check that all required skills are clearly listed"
                    )
                }
                
                # Create response
                $result = @{
                    status = "success"
                    matchScore = $matchScore
                    suggestions = $suggestions
                    keywords = $keywords
                    resumeLength = $resumeText.Length
                    jobDescLength = $jobDescription.Length
                    commonWordsCount = $commonWords.Count
                }
                
                $json = $result | ConvertTo-Json
                Send-JsonResponse -Response $response -Json $json -StatusCode 200
                
            } catch {
                $json = '{"error":"' + $_.Exception.Message.Replace('"', "'") + '"}'
                Send-JsonResponse -Response $response -Json $json -StatusCode 500
            }
        }
        
        # Catch-all for other paths
        else {
            $json = '{"error":"Endpoint not found. Available: /api/health, /api/optimize, /api/keywords"}'
            Send-JsonResponse -Response $response -Json $json -StatusCode 404
        }
    }
    
} catch {
    Write-Host "❌ Server Error: $_" -ForegroundColor Red
} finally {
    if ($listener) {
        $listener.Stop()
        $listener.Close()
    }
    Write-Host "`nServer stopped. Total requests: $requestCount" -ForegroundColor Yellow
}

# Helper function to send JSON responses
function Send-JsonResponse {
    param(
        [System.Net.HttpListenerResponse]$Response,
        [string]$Json,
        [int]$StatusCode = 200
    )
    
    $Response.StatusCode = $StatusCode
    $Response.ContentType = "application/json; charset=utf-8"
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($Json)
    $Response.ContentLength64 = $buffer.Length
    $Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $Response.Close()
}

# Keyword extraction function (same as above)
function Extract-KeywordsFromText {
    param(
        [string]$Text,
        [int]$MaxKeywords = 8
    )
    
    if ([string]::IsNullOrEmpty($Text)) {
        return @()
    }
    
    $textLower = $Text.ToLower()
    $words = $textLower -split '\W+' | Where-Object { $_ -ne '' }
    
    $commonWords = @('the', 'and', 'for', 'with', 'this', 'that', 'from', 'have', 'will', 'experience',
                     'are', 'you', 'your', 'not', 'but', 'was', 'were', 'they', 'their', 'what',
                     'which', 'when', 'where', 'who', 'how', 'been', 'being', 'said', 'could',
                     'should', 'would', 'about', 'after', 'before', 'while', 'during', 'under',
                     'over', 'between', 'through', 'since', 'until', 'upon', 'without')
    
    $wordCounts = @{}
    foreach ($word in $words) {
        if ($word.Length -gt 4 -and $commonWords -notcontains $word) {
            if ($wordCounts.ContainsKey($word)) {
                $wordCounts[$word]++
            } else {
                $wordCounts[$word] = 1
            }
        }
    }
    
    $keywords = $wordCounts.GetEnumerator() | 
                Sort-Object Value -Descending | 
                Select-Object -First $MaxKeywords | 
                ForEach-Object { $_.Key }
    
    return $keywords
}
