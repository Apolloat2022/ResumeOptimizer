function Send-Response {
    param($Response, $Json, $Status = 200)
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($Json)
    $Response.StatusCode = $Status
    $Response.ContentType = "application/json"
    $Response.Headers.Add("Access-Control-Allow-Origin", "*")
    $Response.Headers.Add("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
    $Response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
    $Response.ContentLength64 = $buffer.Length
    $Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $Response.Close()
}
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:5000/")
$listener.Start()
Write-Host "🚀 AI ENGINE ACTIVE - READY FOR PDF OR TEXT" -ForegroundColor Green

while ($listener.IsListening) {
    $context = $listener.GetContext(); $req = $context.Request; $res = $context.Response
    if ($req.HttpMethod -eq "OPTIONS") { Send-Response -Response $res -Json "{}"; continue }
    if ($req.Url.LocalPath -eq "/api/optimize") {
        $reader = New-Object System.IO.StreamReader($req.InputStream)
        $body = $reader.ReadToEnd() | ConvertFrom-Json
        
        $resText = $body.resume.ToLower()
        $jdText = $body.jobDescription.ToLower()

        # Expanded Skills Bank
        $skills = @("agile", "scrum", "project management", "python", "sql", "aws", "azure", "docker", "leadership", "jira", "tableau", "power bi")
        
        $required = $skills | Where-Object { $jdText -like "*$_*" }
        $found = $required | Where-Object { $resText -like "*$_*" }
        $missing = $required | Where-Object { $_ -notin $found }

        $score = if ($required.Count -gt 0) { [math]::Round(($found.Count / $required.Count) * 100) } else { 100 }
        
        $result = @{ 
            matchScore = $score
            keywords = $found
            missing = $missing
            recommendation = if ($missing) { "Strategic Gap: Your resume is missing '" + ($missing -join ", ") + "'. Add these to your experience section to bypass ATS filters." } else { "Perfect Match! Your resume contains all keywords identified in the JD." }
        }
        Send-Response -Response $res -Json ($result | ConvertTo-Json)
    }
}
