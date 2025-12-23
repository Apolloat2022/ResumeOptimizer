from http.server import BaseHTTPRequestHandler
import json
import re

class handler(BaseHTTPRequestHandler):
    def do_POST(self):
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            
            resume = data.get('resume', '')
            jd = data.get('jobDescription', '')
            
            # Extract keywords from job description
            jd_lower = jd.lower()
            resume_lower = resume.lower()
            
            # Common tech skills and keywords
            all_keywords = [
                "agile", "scrum", "python", "javascript", "react", "node.js", 
                "sql", "aws", "docker", "kubernetes", "ci/cd", "devops",
                "leadership", "frontend", "backend", "full-stack", "api",
                "git", "typescript", "html", "css", "security", "mentoring"
            ]
            
            required = [k for k in all_keywords if k in jd_lower]
            found = [k for k in required if k in resume_lower]
            missing = [k for k in required if k not in found]
            
            score = round((len(found) / len(required)) * 100) if required else 100
            
            # Generate optimized resume
            optimized = self.optimize_resume(resume, missing, jd)
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            response = {
                "matchScore": score,
                "keywords": found,
                "missing": missing,
                "recommendation": self.get_recommendation(missing, score),
                "optimizedResume": optimized
            }
            self.wfile.write(json.dumps(response).encode())
            
        except Exception as e:
            self.send_error(500, f"Server Error: {str(e)}")
    
    def optimize_resume(self, resume, missing, jd):
        """Generate an optimized version of the resume"""
        optimized = resume
        
        if not missing:
            return resume + "\n\n✨ Your resume is already well-optimized for this role!"
        
        # Add missing keywords to skills section
        suggestions = []
        suggestions.append("\n\n=== OPTIMIZATION SUGGESTIONS ===\n")
        suggestions.append(f"Consider highlighting these skills from the job description:\n")
        
        for keyword in missing[:5]:  # Top 5 missing keywords
            suggestions.append(f"• {keyword.title()}")
        
        suggestions.append("\n\n=== RECOMMENDED ADDITIONS ===\n")
        suggestions.append("Add a 'Key Technical Skills' section if missing, including:")
        suggestions.append(f"{', '.join([k.title() for k in missing])}")
        
        suggestions.append("\n\n=== SUGGESTED BULLET POINTS ===\n")
        if "leadership" in missing:
            suggestions.append("• Led cross-functional teams in an Agile environment")
        if "ci/cd" in missing:
            suggestions.append("• Implemented CI/CD pipelines for automated deployment")
        if "mentoring" in missing:
            suggestions.append("• Mentored junior developers on best practices and code quality")
        
        return optimized + "\n".join(suggestions)
    
    def get_recommendation(self, missing, score):
        """Generate tailored recommendations"""
        if score >= 90:
            return "Excellent match! Your resume aligns very well with this role."
        elif score >= 70:
            return f"Good match! Consider emphasizing: {', '.join(missing[:3])}"
        elif score >= 50:
            return f"Moderate match. Focus on adding: {', '.join(missing[:3])}"
        else:
            return f"Significant gaps. Prioritize adding: {', '.join(missing[:5])}"
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()