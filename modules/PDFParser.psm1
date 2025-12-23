# PDFParser.psm1 - Complete PDF Text Extraction Module
# Uses iTextSharp for reliable PDF parsing

function Initialize-PDFLibrary {
    <#
    .SYNOPSIS
    Downloads and loads the iTextSharp library if not already available.
    #>
    
    $libsDir = ".\libs"
    $dllPath = "$libsDir\itextsharp.dll"
    
    # Check if already loaded
    $isLoaded = [System.AppDomain]::CurrentDomain.GetAssemblies() | 
                Where-Object { $_.FullName -like "*itextsharp*" }
    
    if ($isLoaded) {
        Write-Verbose "iTextSharp already loaded"
        return $true
    }
    
    # Create libs directory if needed
    if (-not (Test-Path $libsDir)) {
        New-Item -ItemType Directory -Path $libsDir -Force | Out-Null
        Write-Host "Created libs directory for PDF library" -ForegroundColor Green
    }
    
    # Download if not present
    if (-not (Test-Path $dllPath)) {
        Write-Host "Downloading iTextSharp PDF library (one-time setup)..." -ForegroundColor Yellow
        
        try {
            # Download the iTextSharp release zip
            $zipUrl = "https://github.com/itext/itextsharp/releases/download/5.5.13.1/itextsharp-dll-core.zip"
            $zipPath = "$libsDir\itextsharp.zip"
            
            # Use TLS 1.2 for secure connection
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            
            Write-Host "Downloading from GitHub..." -ForegroundColor Gray
            $progressPreference = 'SilentlyContinue'  # Suppress progress bar
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UserAgent "PowerShell"
            $progressPreference = 'Continue'
            
            # Extract just the DLL we need
            $tempDir = "$libsDir\temp"
            if (Test-Path $tempDir) {
                Remove-Item -Path $tempDir -Recurse -Force
            }
            
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempDir)
            
            # Find the DLL (could be in various locations)
            $foundDll = Get-ChildItem -Path $tempDir -Filter "itextsharp.dll" -Recurse | 
                        Select-Object -First 1
            
            if ($foundDll) {
                Copy-Item -Path $foundDll.FullName -Destination $dllPath
                Write-Host "✓ iTextSharp library downloaded successfully" -ForegroundColor Green
            } else {
                Write-Host "✗ Could not find iTextSharp DLL in downloaded package" -ForegroundColor Red
                Write-Host "   Trying alternative search..." -ForegroundColor Yellow
                
                # Try alternative DLL name
                $foundDll = Get-ChildItem -Path $tempDir -Filter "*.dll" -Recurse | 
                           Where-Object { $_.Name -like "*itext*" } | 
                           Select-Object -First 1
                
                if ($foundDll) {
                    Copy-Item -Path $foundDll.FullName -Destination $dllPath
                    Write-Host "✓ Found alternative DLL: $($foundDll.Name)" -ForegroundColor Green
                } else {
                    return $false
                }
            }
            
            # Cleanup
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
            
        } catch {
            Write-Host "✗ Failed to download iTextSharp: $_" -ForegroundColor Red
            Write-Host "   You can manually download from:" -ForegroundColor Yellow
            Write-Host "   https://github.com/itext/itextsharp/releases" -ForegroundColor White
            return $false
        }
    }
    
    # Load the DLL
    try {
        Add-Type -Path $dllPath -ErrorAction Stop
        Write-Verbose "iTextSharp library loaded from: $dllPath"
        return $true
    } catch {
        Write-Host "✗ Failed to load iTextSharp DLL: $_" -ForegroundColor Red
        return $false
    }
}

function Read-PDFText {
    <#
    .SYNOPSIS
    Extracts text from a PDF file using iTextSharp.
    
    .EXAMPLE
    Read-PDFText -FilePath "C:\resumes\john_doe.pdf"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [int]$MaxPages = 0
    )
    
    # Validate file
    if (-not (Test-Path $FilePath)) {
        throw "PDF file not found: $FilePath"
    }
    
    # Ensure library is loaded
    if (-not (Initialize-PDFLibrary)) {
        throw "PDF processing library not available. Please check internet connection and try again."
    }
    
    $reader = $null
    try {
        # Create PDF reader
        $reader = New-Object iTextSharp.text.pdf.PdfReader($FilePath)
        
        # Check if PDF is encrypted
        if ($reader.IsEncrypted()) {
            if (-not $reader.IsOpenedWithFullPermissions()) {
                throw "PDF is encrypted or password-protected. Please provide an unencrypted version."
            }
        }
        
        # Determine how many pages to process
        $pageCount = $reader.NumberOfPages
        if ($MaxPages -gt 0 -and $MaxPages -lt $pageCount) {
            $pageCount = $MaxPages
        }
        
        Write-Verbose "Extracting text from $pageCount page(s)..."
        
        # Extract text from each page
        $textBuilder = New-Object System.Text.StringBuilder
        for ($page = 1; $page -le $pageCount; $page++) {
            try {
                $pageText = [iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($reader, $page)
                [void]$textBuilder.AppendLine($pageText.Trim())
                
                # Add page separator for multi-page documents
                if ($page -lt $pageCount) {
                    [void]$textBuilder.AppendLine("--- Page $page ---")
                }
            } catch {
                Write-Warning ("Could not extract text from page {0}: {1}" -f $page, $_)
                [void]$textBuilder.AppendLine("--- [Page $page content could not be extracted] ---")
            }
        }
        
        $result = $textBuilder.ToString().Trim()
        
        if ([string]::IsNullOrWhiteSpace($result)) {
            Write-Warning "No text could be extracted. The PDF may be scanned or image-based."
            Write-Host "   Try using OCR software or provide a text-based PDF." -ForegroundColor Yellow
        }
        
        return $result
        
    } catch {
        throw "Failed to read PDF: $_"
    } finally {
        # Ensure reader is closed
        if ($reader -ne $null) {
            try {
                $reader.Close()
            } catch {
                Write-Verbose "Error closing PDF reader: $_"
            }
        }
    }
}

function Test-PDFFile {
    <#
    .SYNOPSIS
    Tests if a PDF file can be read and provides diagnostics.
    #>
    
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return @{ Success = $false; Message = "File not found"; CanExtractText = $false }
    }
    
    if (-not (Initialize-PDFLibrary)) {
        return @{ Success = $false; Message = "PDF library not available"; CanExtractText = $false }
    }
    
    try {
        $reader = New-Object iTextSharp.text.pdf.PdfReader($FilePath)
        $info = @{
            Success = $true
            PageCount = $reader.NumberOfPages
            IsEncrypted = $reader.IsEncrypted()
            FileSize = (Get-Item $FilePath).Length
            CanExtractText = $true
            FileType = "PDF"
        }
        $reader.Close()
        return $info
    } catch {
        return @{
            Success = $false
            Message = $_.Exception.Message
            CanExtractText = $false
            FileType = "PDF (unreadable)"
        }
    }
}

Export-ModuleMember -Function Initialize-PDFLibrary, Read-PDFText, Test-PDFFile
