// app.js - Frontend JavaScript for Resume Optimizer

// DOM Elements
const resumeFileInput = document.getElementById('resumeFile');
const jobDescFileInput = document.getElementById('jobDescFile');
const jobTextArea = document.getElementById('jobText');
const optimizeBtn = document.getElementById('optimizeBtn');
const resultsSection = document.getElementById('resultsSection');
const loadingModal = document.getElementById('loadingModal');
const resumeInfo = document.getElementById('resumeInfo');
const jobDescInfo = document.getElementById('jobDescInfo');
const keywordsList = document.getElementById('keywordsList');
const suggestionsList = document.getElementById('suggestionsList');
const scoreProgress = document.querySelector('.score-progress');
const scoreText = document.querySelector('.score-text');

// File Handling
resumeFileInput.addEventListener('change', function(e) {
    const file = e.target.files[0];
    if (file) {
        resumeInfo.innerHTML = `<i class="fas fa-check-circle"></i> ${file.name} (${formatBytes(file.size)})`;
        resumeInfo.style.color = '#27ae60';
    }
});

jobDescFileInput.addEventListener('change', function(e) {
    const file = e.target.files[0];
    if (file) {
        jobDescInfo.innerHTML = `<i class="fas fa-check-circle"></i> ${file.name} (${formatBytes(file.size)})`;
        jobDescInfo.style.color = '#27ae60';
        
        // If it's a text file, read it and populate the textarea
        if (file.type === 'text/plain' || file.name.endsWith('.txt')) {
            const reader = new FileReader();
            reader.onload = function(e) {
                jobTextArea.value = e.target.result;
            };
            reader.readAsText(file);
        }
    }
});

// Drag and Drop
['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
    ['resumeDropZone', 'jobDescDropZone'].forEach(zoneId => {
        const zone = document.getElementById(zoneId);
        zone.addEventListener(eventName, preventDefaults, false);
    });
});

function preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
}

['dragenter', 'dragover'].forEach(eventName => {
    ['resumeDropZone', 'jobDescDropZone'].forEach(zoneId => {
        const zone = document.getElementById(zoneId);
        zone.addEventListener(eventName, highlight, false);
    });
});

['dragleave', 'drop'].forEach(eventName => {
    ['resumeDropZone', 'jobDescDropZone'].forEach(zoneId => {
        const zone = document.getElementById(zoneId);
        zone.addEventListener(eventName, unhighlight, false);
    });
});

function highlight(e) {
    e.currentTarget.style.borderColor = '#2980b9';
    e.currentTarget.style.backgroundColor = '#e1f5fe';
}

function unhighlight(e) {
    e.currentTarget.style.borderColor = '#3498db';
    e.currentTarget.style.backgroundColor = '#f8fafc';
}

// File Drop Handling
document.getElementById('resumeDropZone').addEventListener('drop', handleResumeDrop, false);
document.getElementById('jobDescDropZone').addEventListener('drop', handleJobDescDrop, false);

function handleResumeDrop(e) {
    const dt = e.dataTransfer;
    const file = dt.files[0];
    
    if (file && (file.type === 'application/pdf' || 
                 file.name.endsWith('.docx') || 
                 file.name.endsWith('.txt'))) {
        resumeFileInput.files = dt.files;
        resumeInfo.innerHTML = `<i class="fas fa-check-circle"></i> ${file.name} (${formatBytes(file.size)})`;
        resumeInfo.style.color = '#27ae60';
    } else {
        resumeInfo.innerHTML = `<i class="fas fa-exclamation-circle"></i> Please upload PDF, DOCX, or TXT files only`;
        resumeInfo.style.color = '#e74c3c';
    }
}

function handleJobDescDrop(e) {
    const dt = e.dataTransfer;
    const file = dt.files[0];
    
    if (file && (file.type === 'text/plain' || 
                 file.name.endsWith('.txt') || 
                 file.name.endsWith('.docx') || 
                 file.name.endsWith('.pdf'))) {
        jobDescFileInput.files = dt.files;
        jobDescInfo.innerHTML = `<i class="fas fa-check-circle"></i> ${file.name} (${formatBytes(file.size)})`;
        jobDescInfo.style.color = '#27ae60';
        
        // If it's a text file, read it
        if (file.type === 'text/plain' || file.name.endsWith('.txt')) {
            const reader = new FileReader();
            reader.onload = function(e) {
                jobTextArea.value = e.target.result;
            };
            reader.readAsText(file);
        }
    } else {
        jobDescInfo.innerHTML = `<i class="fas fa-exclamation-circle"></i> Please upload TXT, DOCX, or PDF files only`;
        jobDescInfo.style.color = '#e74c3c';
    }
}

// Format file size
function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Main Optimization Function
async function optimizeResume() {
    // Validate inputs
    const resumeFile = resumeFileInput.files[0];
    const jobDescFile = jobDescFileInput.files[0];
    const jobText = jobTextArea.value.trim();
    
    if (!resumeFile) {
        alert('Please upload your resume file.');
        return;
    }
    
    if (!jobDescFile && !jobText) {
        alert('Please provide a job description (upload file or paste text).');
        return;
    }
    
    // Show loading modal
    loadingModal.style.display = 'flex';
    
    // Simulate processing steps
    simulateLoadingSteps();
    
    // Prepare form data
    const formData = new FormData();
    formData.append('resume', resumeFile);
    
    if (jobDescFile) {
        formData.append('jobDescriptionFile', jobDescFile);
    }
    if (jobText) {
        formData.append('jobDescriptionText', jobText);
    }
    
    formData.append('template', document.getElementById('template').value);
    formData.append('industry', document.getElementById('industry').value);
    
    try {
        // For LOCAL USE: Send to your PowerShell backend
        // Note: This requires the backend server to be running (see next section)
        const response = await fetch('http://localhost:5000/optimize', {
            method: 'POST',
            body: formData
        });
        
        if (!response.ok) {
            throw new Error(`Server error: ${response.status}`);
        }
        
        const result = await response.json();
        
        // Hide loading modal
        loadingModal.style.display = 'none';
        
        // Display results
        displayResults(result);
        
    } catch (error) {
        console.error('Error:', error);
        loadingModal.style.display = 'none';
        
        // For DEMO PURPOSES: Show simulated results if backend is not ready
        if (error.message.includes('Failed to fetch')) {
            alert('Backend server is not running. Starting demo mode with simulated results.');
            simulateResults();
        } else {
            alert(`Error: ${error.message}. Please check if the backend server is running.`);
        }
    }
}

// Simulate loading steps
function simulateLoadingSteps() {
    const steps = document.querySelectorAll('.loading-steps .step');
    let currentStep = 0;
    
    const interval = setInterval(() => {
        steps.forEach(step => step.classList.remove('active'));
        steps[currentStep].classList.add('active');
        
        currentStep++;
        if (currentStep >= steps.length) {
            currentStep = 0;
        }
    }, 1000);
    
    // Clear interval when modal is hidden
    setTimeout(() => clearInterval(interval), 10000);
}

// Display results from backend
function displayResults(result) {
    // Update match score
    const score = result.matchScore || 78;
    updateScoreCircle(score);
    
    // Update keywords
    if (result.keywords && result.keywords.length > 0) {
        keywordsList.innerHTML = '';
        result.keywords.slice(0, 8).forEach(keyword => {
            const keywordEl = document.createElement('div');
            keywordEl.className = 'keyword';
            keywordEl.textContent = keyword;
            keywordsList.appendChild(keywordEl);
        });
    }
    
    // Update suggestions
    if (result.suggestions && result.suggestions.length > 0) {
        suggestionsList.innerHTML = '';
        result.suggestions.slice(0, 5).forEach(suggestion => {
            const li = document.createElement('li');
            li.textContent = suggestion;
            suggestionsList.appendChild(li);
        });
    }
    
    // Setup download buttons (for demo - would link to actual files from backend)
    setupDownloadButtons(result);
    
    // Show results section
    resultsSection.style.display = 'block';
    
    // Scroll to results
    resultsSection.scrollIntoView({ behavior: 'smooth' });
}

// Update the circular progress bar
function updateScoreCircle(score) {
    const radius = 54;
    const circumference = 2 * Math.PI * radius;
    const offset = circumference - (score / 100) * circumference;
    
    scoreProgress.style.strokeDasharray = circumference;
    scoreProgress.style.strokeDashoffset = offset;
    scoreText.textContent = `${score}%`;
    
    // Change color based on score
    if (score >= 80) {
        scoreProgress.style.stroke = '#2ecc71'; // Green
    } else if (score >= 60) {
        scoreProgress.style.stroke = '#3498db'; // Blue
    } else {
        scoreProgress.style.stroke = '#e74c3c'; // Red
    }
}

// Setup download buttons
function setupDownloadButtons(result) {
    const downloadButtons = document.querySelectorAll('.download-buttons button');
    
    // Report button
    downloadButtons[0].addEventListener('click', function() {
        alert('In a full implementation, this would open the detailed optimization report.');
        // window.open(result.reportUrl, '_blank');
    });
    
    // Resume button
    downloadButtons[1].addEventListener('click', function() {
        alert('In a full implementation, this would download the optimized resume file.');
        // const link = document.createElement('a');
        // link.href = result.resumeUrl;
        // link.download = 'Optimized_Resume.pdf';
        // link.click();
    });
}

// Simulate results for demo purposes
function simulateResults() {
    // Simulate a delay
    setTimeout(() => {
        loadingModal.style.display = 'none';
        
        // Mock results
        const mockResult = {
            matchScore: Math.floor(Math.random() * 30) + 65, // Random score between 65-95
            keywords: ['JavaScript', 'React', 'Node.js', 'AWS', 'Agile', 'Python', 'SQL', 'Git'],
            suggestions: [
                'Add "Docker" to your skills section',
                'Quantify your achievements with specific numbers and percentages',
                'Include more leadership-related keywords for managerial roles',
                'Add a projects section to showcase specific implementations'
            ]
        };
        
        displayResults(mockResult);
    }, 3000);
}

// About modal
function showAbout() {
    alert(`AI Resume Optimizer\n\nVersion: 2.0 (Web Interface)\n\nThis tool analyzes your resume against job descriptions to:\n1. Calculate a match score\n2. Identify missing keywords\n3. Generate ATS-friendly optimized versions\n4. Provide actionable improvement suggestions\n\nBackend: PowerShell Optimization Engine\nFrontend: HTML/CSS/JavaScript`);
}

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    // Update score circle initially
    updateScoreCircle(0);
});