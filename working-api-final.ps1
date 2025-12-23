# ==================== HELPER FUNCTIONS ====================
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

function Extract-KeywordsFromText {
    param([string]$Text, [int]$MaxKeywords = 8)
    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    
    $commonWords = @('the','and','for','with','this','that','from','have','will','experience','your','work','team')
    $words = $Text.ToLower() -split '\W+' | Where-Object { $_.Length -gt 4 -and $commonWords -notcontains $_ }
    
    $groups = $words | Group-Object | Sort-Object Count -Descending | Select-Object -First $MaxKeywords
    return $groups.Name
}

# ==================== MAIN SERVER CODE ====================
$port = 5000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
    Write-Host "🚀 Server started at http://localhost:$port/" -ForegroundColor Green
    Write-Host "Listening for POST requests on /api/optimize..." -ForegroundColor Gray

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $path = $request.Url.LocalPath.ToLower()

        # Add CORS
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")

        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }

        # ROUTING
        if ($path -eq "/api/health") {
            Send-JsonResponse -Response $response -Json '{"status":"online"}'
        }
        elseif ($path -eq "/api/optimize" -and $request.HttpMethod -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            
            $keywords = Extract-KeywordsFromText -Text $data.jobDescription
            
            # Simple logic for match score
            $score = Get-Random -Minimum 60 -Maximum 95 
            
            $result = @{
                status = "success"
                matchScore = $score
                keywords = $keywords
                suggestions = @("Add more metrics", "Tailor your summary")
            }
            
            Send-JsonResponse -Response $response -Json ($result | ConvertTo-Json)
        }
        else {
            Send-JsonResponse -Response $response -Json '{"error":"Not Found"}' -StatusCode 404
        }
    }
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    $listener.Stop()
}