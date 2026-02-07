# test_api.ps1
$resumeFile = "test_files/test_resume.txt"
$jdText = "We are looking for a Software Engineer proficient in JavaScript, React, Node.js, and AWS."

$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

$body = (
    "--$boundary",
    "Content-Disposition: form-data; name=`"resume`"; filename=`"test_resume.txt`"",
    "Content-Type: text/plain",
    "",
    (Get-Content $resumeFile -Raw),
    "--$boundary",
    "Content-Disposition: form-data; name=`"jobDescriptionText`"",
    "",
    $jdText,
    "--$boundary--"
) -join $LF

$response = Invoke-RestMethod -Uri "http://localhost:5000/api/optimize" -Method Post -ContentType "multipart/form-data; boundary=$boundary" -Body $body
$response | ConvertTo-Json -Depth 10
