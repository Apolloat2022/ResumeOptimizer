# ResumeOptimizer.psm1
# AI Resume Optimization Module - Consolidated Version

$ModuleVersion = "1.0.1"

# ========== LOGGING FUNCTIONS ==========
function Write-ResumeLog {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR","DEBUG")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
        "INFO"  { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry }
    }
    
    # Write to log file
    $logFile = "logs\resume_optimizer_$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $logFile -Value $logEntry
}

# ========== TEXT PROCESSING FUNCTIONS ==========
function ConvertTo-Text {
    param([string]$FilePath)
    
    Write-ResumeLog "Converting file to text: $FilePath" -Level "INFO"
    
    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }
    
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    
    try {
        switch ($extension) {
            ".txt" {
                return Get-Content -Path $FilePath -Raw
            }
            ".docx" {
                # Simple DOCX extraction for MVP
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                
                $tempDir = Join-Path $env:TEMP "resume_extract_$(Get-Random)"
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                
                [System.IO.Compression.ZipFile]::ExtractToDirectory($FilePath, $tempDir)
                
                $documentPath = Join-Path $tempDir "word\document.xml"
                if (Test-Path $documentPath) {
                    [xml]$xmlContent = Get-Content -Path $documentPath
                    $textNodes = $xmlContent.SelectNodes("//w:t")
                    $text = ($textNodes.InnerText -join " ").Trim()
                } else {
                    $text = "Could not extract text from DOCX."
                }
                
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                return $text
            }
            ".pdf" {
                # For MVP, PDF requires manual conversion
                Write-Host "PDF parsing limited in MVP. Please convert to TXT first." -ForegroundColor Yellow
                Write-Host "For now, using simple text extraction..." -ForegroundColor Yellow
                
                # Try to extract text using .NET (very basic)
                try {
                    $reader = New-Object iTextSharp.text.pdf.PdfReader -ArgumentList $FilePath
                    $text = ""
                    for ($i = 1; $i -le $reader.NumberOfPages; $i++) {
                        $text += [iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($reader, $i)
                    }
                    $reader.Close()
                    return $text
                }
                catch {
                    return "PDF_CONTENT_REQUIRES_ADVANCED_PARSING`nPlease convert PDF to TXT format for best results."
                }
            }
            default {
                throw "Unsupported file format: $extension. Please use .txt or .docx"
            }
        }
    }
    catch {
        Write-ResumeLog "Error converting file: $_" -Level "ERROR"
        throw "Failed to process file: $_"
    }
}

function Extract-Keywords {
    param(
        [string]$Text,
        [ValidateSet("JobDescription","Resume")]
        [string]$Type = "JobDescription"
    )
    
    Write-ResumeLog "Extracting keywords from $Type" -Level "INFO"
    
    # Clean text
    $cleanText = $Text -replace '[^\w\s\.\-@#]', ' '
    $cleanText = $cleanText -replace '\s+', ' '
    
    # Convert to lowercase for analysis
    $lowerText = $cleanText.ToLower()
    
    # Common stop words to ignore
    $stopWords = @(
        "the", "and", "for", "are", "with", "this", "that", "have", "from",
        "you", "your", "will", "would", "should", "their", "there", "what",
        "which", "when", "where", "who", "whom", "how", "why", "about"
    )
    
    # Split into words
    $words = $lowerText -split '\s+' | Where-Object {
        $_.Length -gt 2 -and 
        $_ -notmatch '^\d+$' -and 
        $_ -notin $stopWords
    }
    
    # Count frequency
    $wordCount = @{}
    foreach ($word in $words) {
        if ($wordCount.ContainsKey($word)) {
            $wordCount[$word]++
        } else {
            $wordCount[$word] = 1
        }
    }
    
    # Extract potential skills/technologies
    $potentialSkills = @()
    $sentences = $cleanText -split '[.!?]' | Where-Object { $_.Trim().Length -gt 0 }
    
    foreach ($sentence in $sentences) {
        # Look for patterns like "Experience with X", "Knowledge of Y"
        if ($sentence -match "(?:experience with|knowledge of|proficient in|skilled in|expertise in)\s+([A-Za-z0-9+#\.\s]+)") {
            $skills = $matches[1].Trim() -split '[,\s]+' | Where-Object { $_.Length -gt 1 }
            $potentialSkills += $skills
        }
        
        # Look for tools/technologies
        if ($sentence -match "([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+(?:\d+\.\d+|\.NET|JS|SQL)") {
            $potentialSkills += $matches[1]
        }
    }
    
    # Find job title (usually in first few lines)
    $firstLines = ($cleanText -split "`n")[0..4] -join " "
    $jobTitle = ""
    if ($firstLines -match "(?:position|role|title)[:\s]+([A-Za-z\s]+)") {
        $jobTitle = $matches[1].Trim()
    }
    
    # Return structured keyword analysis
    return @{
        WordFrequency = $wordCount.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 20
        PotentialSkills = $potentialSkills | Select-Object -Unique
        JobTitle = $jobTitle
        Sentences = $sentences
    }
}

# ========== OPTIMIZATION FUNCTIONS ==========
function Optimize-Resume {
    param(
        [string]$ResumePath,
        [string]$JobDescriptionPath,
        [string]$JobDescriptionText
    )
    
    Write-ResumeLog "Starting resume optimization process" -Level "INFO"
    
    try {
        # Extract text from resume
        Write-ResumeLog "Reading resume from: $ResumePath" -Level "INFO"
        $resumeText = ConvertTo-Text -FilePath $ResumePath
        
        # Extract text from job description
        if ($JobDescriptionPath) {
            Write-ResumeLog "Reading job description from file: $JobDescriptionPath" -Level "INFO"
            $jdText = ConvertTo-Text -FilePath $JobDescriptionPath
        } else {
            Write-ResumeLog "Using provided job description text" -Level "INFO"
            $jdText = $JobDescriptionText
        }
        
        # Analyze keywords
        $resumeAnalysis = Extract-Keywords -Text $resumeText -Type "Resume"
        $jdAnalysis = Extract-Keywords -Text $jdText -Type "JobDescription"
        
        # Calculate match score
        $matchScore = Calculate-MatchScore -ResumeAnalysis $resumeAnalysis -JDAnalysis $jdAnalysis
        
        # Generate optimized resume
        $optimizedResume = Generate-OptimizedResume -OriginalResume $resumeText -JDAnalysis $jdAnalysis
        
        # Prepare result
        $result = @{
            OriginalResume = $resumeText
            JobDescription = $jdText
            ResumeAnalysis = $resumeAnalysis
            JDAnalysis = $jdAnalysis
            MatchScore = $matchScore
            OptimizedResume = $optimizedResume
            OptimizationDate = Get-Date
        }
        
        Write-ResumeLog "Optimization complete. Match score: $($matchScore.Score)%" -Level "INFO"
        
        return $result
    }
    catch {
        Write-ResumeLog "Optimization failed: $_" -Level "ERROR"
        throw
    }
}

function Calculate-MatchScore {
    param(
        [hashtable]$ResumeAnalysis,
        [hashtable]$JDAnalysis
    )
    
    Write-ResumeLog "Calculating match score" -Level "INFO"
    
    # Extract key terms from job description
    $jdKeywords = @()
    
    # Add high-frequency words from JD
    $jdKeywords += $JDAnalysis.WordFrequency | Where-Object { $_.Value -ge 2 } | Select-Object -ExpandProperty Name
    
    # Add potential skills from JD
    $jdKeywords += $JDAnalysis.PotentialSkills
    
    # Remove duplicates and normalize
    $jdKeywords = $jdKeywords | ForEach-Object { $_.ToLower().Trim() } | Select-Object -Unique
    
    # Extract terms from resume
    $resumeKeywords = @()
    $resumeKeywords += $ResumeAnalysis.WordFrequency | Where-Object { $_.Value -ge 2 } | Select-Object -ExpandProperty Name
    $resumeKeywords += $ResumeAnalysis.PotentialSkills
    $resumeKeywords = $resumeKeywords | ForEach-Object { $_.ToLower().Trim() } | Select-Object -Unique
    
    # Calculate overlap
    $matchingKeywords = $jdKeywords | Where-Object { $_ -in $resumeKeywords }
    
    # Calculate score
    $score = 0
    if ($jdKeywords.Count -gt 0) {
        $score = [math]::Round(($matchingKeywords.Count / $jdKeywords.Count) * 100, 2)
    }
    
    # Adjust score based on job title match
    $titleBonus = 0
    if ($JDAnalysis.JobTitle -and $ResumeAnalysis.WordFrequency.Name -contains $JDAnalysis.JobTitle.ToLower()) {
        $titleBonus = 10
        $score += $titleBonus
    }
    
    # Cap at 100%
    $score = [math]::Min($score, 100)
    
    return @{
        Score = $score
        TotalJDKeywords = $jdKeywords.Count
        MatchedKeywords = $matchingKeywords.Count
        MatchingKeywords = $matchingKeywords
        TitleBonus = $titleBonus
    }
}

function Generate-OptimizedResume {
    param(
        [string]$OriginalResume,
        [hashtable]$JDAnalysis
    )
    
    Write-ResumeLog "Generating optimized resume" -Level "INFO"
    
    # For MVP, we'll do simple keyword insertion
    $optimizedText = $OriginalResume
    
    # Add job title to summary if found
    if ($JDAnalysis.JobTitle -and $JDAnalysis.JobTitle.Length -gt 3) {
        $optimizedText = "Results-driven $($JDAnalysis.JobTitle) professional`n" + $optimizedText
    }
    
    # Add a skills section if not present
    if ($optimizedText -notmatch "(?i)skills.*:") {
        $skillsSection = "`n`nSKILLS:`n"
        if ($JDAnalysis.PotentialSkills.Count -gt 0) {
            $skillsSection += ($JDAnalysis.PotentialSkills | Select-Object -First 10) -join ", "
        }
        $optimizedText += $skillsSection
    }
    
    return $optimizedText
}

function Export-OptimizedResume {
    param([hashtable]$Result)
    
    Write-ResumeLog "Exporting optimized resume" -Level "INFO"
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputDir = "outputs\$timestamp"
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    
    # Save optimized resume
    $resumePath = Join-Path $outputDir "optimized_resume.txt"
    $Result.OptimizedResume | Out-File -FilePath $resumePath -Encoding UTF8
    
    # Generate report
    $reportPath = Join-Path $outputDir "optimization_report.txt"
    Generate-Report -Result $Result | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-ResumeLog "Files saved to: $outputDir" -Level "INFO"
    
    # Display summary
    Show-Summary -Result $Result -OutputDir $outputDir
    
    return @{
        OutputDirectory = $outputDir
        ResumePath = $resumePath
        ReportPath = $reportPath
    }
}

function Generate-Report {
    param([hashtable]$Result)
    
    $report = @"
RESUME OPTIMIZATION REPORT
===========================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

MATCH ANALYSIS
--------------
Overall Match Score: $($Result.MatchScore.Score)%

Job Description Keywords: $($Result.MatchScore.TotalJDKeywords)
Matched Keywords: $($Result.MatchScore.MatchedKeywords)
Title Match Bonus: $($Result.MatchScore.TitleBonus)

TOP MATCHING KEYWORDS:
----------------------
$(($Result.MatchScore.MatchingKeywords | Select-Object -First 10) -join ", ")

RECOMMENDATIONS:
----------------
1. Consider adding these skills to your resume
2. Quantify achievements where possible
3. Use strong action verbs
4. Ensure consistent formatting

OPTIMIZED RESUME PREVIEW:
-------------------------
$(($Result.OptimizedResume -split "`n" | Select-Object -First 20) -join "`n")
...
"@
    
    return $report
}

function Show-Summary {
    param(
        [hashtable]$Result,
        [string]$OutputDir
    )
    
    Clear-Host
    
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "     RESUME OPTIMIZATION COMPLETE        " -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Display match score with color coding
    $score = $Result.MatchScore.Score
    $color = "Red"
    if ($score -ge 70) { $color = "Green" }
    elseif ($score -ge 50) { $color = "Yellow" }
    
    Write-Host "Match Score: " -NoNewline
    Write-Host "$score%" -ForegroundColor $color
    Write-Host ""
    
    Write-Host "Files saved to:" -ForegroundColor White
    Write-Host "  $OutputDir" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Files created:" -ForegroundColor White
    Write-Host "  ✓ optimized_resume.txt" -ForegroundColor Green
    Write-Host "  ✓ optimization_report.txt" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Next Steps:" -ForegroundColor White
    Write-Host "  1. Review the optimization report" -ForegroundColor Yellow
    Write-Host "  2. Check the optimized resume" -ForegroundColor Yellow
    Write-Host "  3. Make any manual adjustments needed" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Press any key to open the output folder..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Open output folder
    Invoke-Item $OutputDir
}

# ========== INTERACTIVE FUNCTIONS ==========
function Start-InteractiveMode {
    Write-ResumeLog "Starting interactive mode" -Level "INFO"
    
    Clear-Host
    Show-Banner
    
    # Get resume file
    $resumePath = Get-ResumeFile
    
    # Get job description
    $jobDescriptionText = Get-JobDescriptionFromInput
    
    # Process optimization
    Write-Host "`nProcessing..." -ForegroundColor Yellow
    
    $result = Optimize-Resume -ResumePath $resumePath -JobDescriptionText $jobDescriptionText
    $output = Export-OptimizedResume -Result $result
    
    Write-Host "`nThank you for using AI Resume Optimizer!" -ForegroundColor Green
}

function Show-Banner {
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "    AI RESUME OPTIMIZER - MVP v1.0      " -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This tool will help optimize your resume" -ForegroundColor White
    Write-Host "for specific job descriptions." -ForegroundColor White
    Write-Host ""
}

function Get-ResumeFile {
    while ($true) {
        Write-Host "`nPlease provide your resume:" -ForegroundColor White
        Write-Host "  1. Enter file path" -ForegroundColor Yellow
        Write-Host "  2. Use sample resume" -ForegroundColor Yellow
        Write-Host "  3. Exit" -ForegroundColor Red
        
        $choice = Read-Host "`nSelect option (1-3)"
        
        switch ($choice) {
            "1" {
                $path = Read-Host "Enter full path to your resume (e.g., C:\resume.txt)"
                if (Test-Path $path) {
                    return $path
                } else {
                    Write-Host "File not found: $path" -ForegroundColor Red
                }
            }
            "2" {
                return Create-SampleResume
            }
            "3" {
                Write-ResumeLog "User exited from resume selection" -Level "INFO"
                exit 0
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
            }
        }
    }
}

function Create-SampleResume {
    $samplePath = "test_files\sample_resume.txt"
    
    $sampleContent = @"
JOHN DOE
Software Developer
(123) 456-7890 | john.doe@email.com | linkedin.com/in/johndoe

PROFESSIONAL SUMMARY
Experienced software developer with 5 years in web development and cloud technologies. 
Skilled in troubleshooting and implementing technical solutions.

EXPERIENCE
Senior Software Developer
ABC Corporation, Anytown, USA
June 2019 - Present

• Developed web applications using JavaScript and React
• Implemented REST APIs for data integration
• Collaborated with teams using Agile methodologies
• Deployed applications to AWS cloud infrastructure

Software Developer
XYZ Solutions, Othertown, USA
January 2017 - May 2019

• Created responsive web applications
• Maintained code quality and performed code reviews
• Assisted with software installation and configuration
• Documented technical procedures and solutions

EDUCATION
Bachelor of Science in Computer Science
University of Technology, Anytown, USA
Graduated: May 2016

SKILLS
JavaScript, React, Node.js, AWS, SQL, Git
"@
    
    New-Item -ItemType Directory -Path "test_files" -Force | Out-Null
    $sampleContent | Out-File -FilePath $samplePath -Encoding UTF8
    
    Write-Host "Sample resume created at: $samplePath" -ForegroundColor Green
    return $samplePath
}

function Get-JobDescriptionFromInput {
    Write-Host "`nPaste the job description below (press Enter twice when done):" -ForegroundColor White
    Write-Host "--------------------------------------------------------------" -ForegroundColor Gray
    
    $lines = @()
    while ($true) {
        $line = Read-Host
        if ($line -eq "" -and $lines[-1] -eq "") {
            break
        }
        $lines += $line
    }
    
    return $lines -join "`n"
}

# ========== HELPER FUNCTIONS ==========
function Show-Help {
    Write-Host @"
AI Resume Optimizer - PowerShell MVP
====================================

Usage:
  .\resume_optimizer.ps1 [-Interactive]
  .\resume_optimizer.ps1 -ResumePath <path> -JobDescriptionPath <path>
  .\resume_optimizer.ps1 -ResumePath <path> -JobDescriptionText <text>

Parameters:
  -Interactive           Start interactive mode
  -ResumePath           Path to your resume file
  -JobDescriptionPath   Path to job description file
  -JobDescriptionText   Job description as text string
  -Help                 Show this help message

Examples:
  1. Interactive mode:
     .\resume_optimizer.ps1 -Interactive
  
  2. With files:
     .\resume_optimizer.ps1 -ResumePath "C:\resume.txt" -JobDescriptionPath "C:\job.txt"
  
  3. With text:
     .\resume_optimizer.ps1 -ResumePath "resume.txt" -JobDescriptionText "Looking for Python developer..."

Supported Formats:
  - Resume: .txt, .docx (PDF basic)
  - Job Description: .txt, .docx (PDF basic)

Notes:
  - PDF parsing is limited in MVP
  - For best results, use .txt files
  - Outputs are saved to 'outputs' folder with timestamp

"@
}

# Export public functions
Export-ModuleMember -Function Write-ResumeLog
Export-ModuleMember -Function Optimize-Resume
Export-ModuleMember -Function Export-OptimizedResume
Export-ModuleMember -Function Start-InteractiveMode
Export-ModuleMember -Function Show-Help
