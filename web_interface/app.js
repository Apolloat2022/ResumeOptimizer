// app.js - Frontend logic for Resume Optimizer

// File input handlers
document.getElementById('resumeFile').addEventListener('change', function(e) {
    const file = e.target.files[0];
    if (file) {
        document.getElementById('resumeInfo').innerHTML = 
            `✓ ${file.name} (${formatBytes(file.size)})`;
        document.getElementById('resumeInfo').style.color = '#27ae60';
    }
});

document.getElementById('jobFile').addEventListener('change', function(e) {
    const file = e.target.files[0];
    if (file) {
        document.getElementById('jobInfo').innerHTML = 
            `✓ ${file.name} (${formatBytes(file.size)})`;
        document.getElementById('jobInfo').style.color = '#27ae60';
        
        // If it's a text file, read it into the textarea
        if (file.type === 'text/plain' || file.name.endsWith('.txt')) {
            const reader = new FileReader();
            reader.onload = function(e) {
                document.getElementById('jobText').value = e.target.result;
            };
            reader.readAsText(file);
        }
    }
});

// Format file size
function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Main optimization function
async function optimizeResume() {
    // Get inputs
    const resumeFile = document.getElementById('resumeFile').files[0];
    const jobFile = document.getElementById('jobFile').files[0];
    const jobText = document.getElementById('jobText').value.trim();
    
    // Validation
    if (!resumeFile) {
        alert('Please upload your resume file.');
        return;
    }
    
    if (!jobFile && !jobText) {
        alert('Please provide a job description (upload file or paste text).');
        return;
    }
    
    // Show loading
    document.getElementById('loading').style.display = 'flex';
    
    // For DEMO: Simulate processing
    // In a real implementation, you would send to backend.ps1
    setTimeout(() => {
        // Hide loading
        document.getElementById('loading').style.display = 'none';
        
        // Show results with simulated data
        showDemoResults();
    }, 2000);
}

// Show demo results (for testing without backend)
function showDemoResults() {
    // Random score between 65-95
    const score = Math.floor(Math.random() * 30) + 65;
    
    // Update score display
    document.getElementById('matchScore').textContent = score + '%';
    document.getElementById('scoreFill').style.width = score + '%';
    
    // Update keywords
    const keywords = ['JavaScript', 'React', 'Node.js', 'AWS', 'Agile', 'Python', 'Git'];
    const shuffled = [...keywords].sort(() => 0.5 - Math.random());
    const selectedKeywords = shuffled.slice(0, 5);
    
    document.getElementById('keywordsList').innerHTML = 
        selectedKeywords.map(k => `<span class="keyword">${k}</span>`).join(' ');
    
    // Update suggestions
    const suggestions = [
        'Add "Docker" to your skills section',
        'Quantify achievements with specific numbers',
        'Include more leadership keywords',
        'Add a projects section'
    ];
    
    document.getElementById('suggestionsList').innerHTML = 
        suggestions.map(s => `<li>${s}</li>`).join('');
    
    // Show results section
    document.getElementById('resultsSection').style.display = 'block';
    
    // Scroll to results
    document.getElementById('resultsSection').scrollIntoView({ 
        behavior: 'smooth' 
    });
}

// Download functions (demo)
function downloadReport() {
    alert('In the full version, this would download the optimization report.');
    // In real implementation: window.open('/download/report');
}

function downloadResume() {
    alert('In the full version, this would download the optimized resume.');
    // In real implementation: window.open('/download/resume');
}

// Add CSS for keywords
const style = document.createElement('style');
style.textContent = `
.keyword {
    display: inline-block;
    background: #3498db;
    color: white;
    padding: 5px 10px;
    border-radius: 15px;
    margin: 5px;
    font-size: 0.9rem;
}
`;
document.head.appendChild(style);
