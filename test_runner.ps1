# test_runner.ps1
# Simple test for the resume optimizer

Write-Host "AI Resume Optimizer - Test Runner" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Ensure required directories exist
@("outputs", "test_files", "logs") | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Host "Created directory: $_" -ForegroundColor Green
    }
}

# Create test resume
$testResume = @"
JANE SMITH
Software Engineer
(555) 123-4567 | jane.smith@email.com | linkedin.com/in/janesmith

SUMMARY
Software engineer with 4 years experience in full-stack development. 
Proficient in JavaScript, React, and Node.js.

EXPERIENCE
Full Stack Developer
Tech Innovations Inc.
2020 - Present

• Developed and maintained web applications using React and Node.js
• Created RESTful APIs for data management
• Implemented AWS services for cloud deployment
• Collaborated using Agile methodologies
• Wrote unit tests and performed code reviews

Junior Developer
Startup Solutions LLC
2018 - 2020

• Assisted in frontend development with React
• Worked on database design and SQL queries
• Participated in team meetings and code reviews
• Fixed bugs and implemented new features

EDUCATION
Bachelor of Computer Science
State University, 2018

SKILLS
JavaScript, React, Node.js, Python, SQL, AWS, Git, Docker
"@

$testResume | Out-File -FilePath "test_files\test_resume.txt" -Encoding UTF8

# Create test job description
$testJD = @"
Senior Software Developer Position

We are seeking an experienced Senior Software Developer to join our team.

Required Qualifications:
- 4+ years of software development experience
- Proficient in JavaScript and React
- Strong experience with Node.js and REST APIs
- Knowledge of AWS cloud services
- Familiar with Agile methodologies
- Experience with SQL databases
- Understanding of Docker and containerization

Preferred Skills:
- Experience with TypeScript
- Knowledge of Kubernetes
- Understanding of CI/CD pipelines
- Python programming experience

Responsibilities:
- Develop and maintain scalable web applications
- Design and implement RESTful APIs
- Deploy applications to AWS cloud infrastructure
- Collaborate with cross-functional teams
- Write clean, maintainable, and testable code
- Mentor junior developers
"@

$testJD | Out-File -FilePath "test_files\test_jd.txt" -Encoding UTF8

Write-Host "Test files created:" -ForegroundColor Green
Write-Host "  • test_files\test_resume.txt" -ForegroundColor White
Write-Host "  • test_files\test_jd.txt" -ForegroundColor White
Write-Host ""

# Test the module
Write-Host "Testing the resume optimizer..." -ForegroundColor Yellow
Write-Host ""

try {
    # Import the module
    Import-Module -Name ".\modules\ResumeOptimizer.psm1" -Force
    
    # Test with the created files
    $result = Optimize-Resume -ResumePath "test_files\test_resume.txt" -JobDescriptionPath "test_files\test_jd.txt"
    
    Write-Host "Test completed successfully!" -ForegroundColor Green
    Write-Host "Match Score: $($result.MatchScore.Score)%" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "To run interactive mode:" -ForegroundColor Yellow
    Write-Host "  .\scripts\resume_optimizer.ps1 -Interactive" -ForegroundColor White
    Write-Host ""
    
    Write-Host "To run with your own files:" -ForegroundColor Yellow
    Write-Host "  .\scripts\resume_optimizer.ps1 -ResumePath 'your_resume.txt' -JobDescriptionPath 'job_description.txt'" -ForegroundColor White
    
    # Show where files were saved
    $latestOutput = Get-ChildItem -Path "outputs" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestOutput) {
        Write-Host "`nOutput files saved to: $($latestOutput.FullName)" -ForegroundColor Green
    }
}
catch {
    Write-Host "Test failed: $_" -ForegroundColor Red
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    Write-Host "Make sure the module is properly created." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
