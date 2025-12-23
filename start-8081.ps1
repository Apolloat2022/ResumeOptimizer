$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8081/")
$listener.Start()
Write-Host "Server started on http://localhost:8081" -ForegroundColor Green
Write-Host "Press Enter to stop" -ForegroundColor Yellow
Read-Host
$listener.Stop()
