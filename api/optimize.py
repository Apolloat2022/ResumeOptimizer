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
            
            if not resume or not jd:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                error_response = {"error": "Missing resume or job description"}
                self.wfile.write(json.dumps(error_response).encode())
                return
            
            # Normalize text for better matching
            resume_normalized = self.normalize_text(resume)
            jd_normalized = self.normalize_text(jd)
            
            # Extract skills and keywords with better matching
            analysis = self.analyze_match(resume_normalized, jd_normalized)
            
            # Generate optimized resume text
            optimized_text = self.optimize_resume(resume, analysis['missing'], analysis['found'], jd)
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            response = {
                "matchScore": analysis['score'],
                "keywords": analysis['found'],
                "missing": analysis['missing'],
                "recommendation": self.get_recommendation(analysis['missing'], analysis['score']),
                "optimizedResume": optimized_text,
                "pdfSupport": False,
                "optimizedPdf": None
            }
            self.wfile.write(json.dumps(response).encode())
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            error_response = {"error": str(e), "type": type(e).__name__}
            self.wfile.write(json.dumps(error_response).encode())
    
    def normalize_text(self, text):
        """Normalize text for better keyword matching"""
        text = text.lower()
        replacements = {
            'node.js': 'nodejs',
            'node js': 'nodejs',
            'ci/cd': 'cicd',
            'c#': 'csharp',
            'c++': 'cplusplus',
            '.net': 'dotnet',
            'react.js': 'react',
            'vue.js': 'vue',
            'next.js': 'nextjs'
        }
        for old, new in replacements.items():
            text = text.replace(old, new)
        return text
    
    def analyze_match(self, resume_norm, jd_norm):
        """Analyze keyword match between resume and job description"""
        
        # Define comprehensive keyword list with variations
        keyword_map = {
            'python': ['python', 'py'],
            'javascript': ['javascript', 'js', 'ecmascript'],
            'typescript': ['typescript', 'ts'],
            'react': ['react', 'reactjs'],
            'nodejs': ['nodejs', 'node'],
            'nextjs': ['nextjs', 'next'],
            'vue': ['vue', 'vuejs'],
            'angular': ['angular'],
            'java': ['java'],
            'git': ['git', 'github', 'gitlab', 'version control'],
            'docker': ['docker', 'container'],
            'kubernetes': ['kubernetes', 'k8s'],
            'aws': ['aws', 'amazon web services'],
            'azure': ['azure', 'microsoft azure'],
            'gcp': ['gcp', 'google cloud'],
            'cicd': ['cicd', 'continuous integration', 'continuous deployment'],
            'devops': ['devops', 'dev ops'],
            'agile': ['agile'],
            'scrum': ['scrum'],
            'leadership': ['leadership', 'lead', 'leading', 'led'],
            'mentoring': ['mentoring', 'mentor', 'mentored'],
            'frontend': ['frontend', 'front-end', 'front end'],
            'backend': ['backend', 'back-end', 'back end'],
            'fullstack': ['fullstack', 'full-stack', 'full stack'],
            'sql': ['sql', 'mysql', 'postgresql', 'database'],
            'mongodb': ['mongodb', 'mongo'],
            'api': ['api', 'rest', 'restful', 'graphql'],
            'testing': ['testing', 'test', 'qa', 'unit test'],
            'security': ['security', 'secure', 'authentication'],
            'html': ['html', 'html5'],
            'css': ['css', 'css3', 'sass', 'scss', 'tailwind'],
            'flask': ['flask'],
            'django': ['django'],
            'express': ['express', 'expressjs'],
            'firebase': ['firebase'],
            'vercel': ['vercel'],
            'netlify': ['netlify']
        }
        
        # Find which keywords are in the JD
        required = []
        for key, variations in keyword_map.items():
            for var in variations:
                if var in jd_norm:
                    required.append(key)
                    break
        
        # Remove duplicates
        required = list(set(required))
        
        # Find which required keywords are in the resume
        found = []
        missing = []
        
        for key in required:
            variations = keyword_map.get(key, [key])
            matched = False
            for var in variations:
                if var in resume_norm:
                    found.append(key)
                    matched = True
                    break
            if not matched:
                missing.append(key)
        
        # Calculate score
        score = round((len(found) / len(required)) * 100) if required else 100
        
        return {
            'score': score,
            'found': sorted(found),
            'missing': sorted(missing),
            'required': sorted(required)
        }
    
    def optimize_resume(self, resume, missing, found, jd):
        """Generate an optimized version of the resume"""
        
        optimized = []
        
        # Keep original resume
        optimized.append(resume)
        optimized.append('\n\n')
        optimized.append('=' * 70)
        optimized.append('ATS OPTIMIZATION REPORT')
        optimized.append('=' * 70)
        optimized.append('')
        
        # Match analysis
        total = len(found) + len(missing)
        score = round((len(found) / total) * 100) if total > 0 else 100
        
        optimized.append(f'MATCH SCORE: {score}%')
        optimized.append(f'Keywords Matched: {len(found)} out of {total}')
        optimized.append('')
        
        # Keywords found
        if found:
            optimized.append('✅ KEYWORDS FOUND IN YOUR RESUME:')
            optimized.append(', '.join([k.upper() for k in found]))
            optimized.append('')
        
        # Missing keywords with recommendations
        if missing:
            optimized.append('⚠️  MISSING KEYWORDS - RECOMMENDED ADDITIONS:')
            optimized.append('')
            for skill in missing[:8]:
                optimized.append(f'  • Add "{skill.upper()}" to relevant sections')
            optimized.append('')
        
        # ATS tips
        optimized.append('=' * 70)
        optimized.append('ATS-FRIENDLY FORMATTING TIPS:')
        optimized.append('=' * 70)
        optimized.append('• Use standard section headers (Professional Summary, Experience, Skills)')
        optimized.append('• Avoid tables, columns, headers/footers, and images')
        optimized.append('• Use standard fonts (Arial, Calibri, Times New Roman)')
        optimized.append('• Include keywords naturally in context, not just listed')
        optimized.append('• Use bullet points to highlight achievements')
        optimized.append('• Quantify accomplishments with numbers when possible')
        
        return '\n'.join(optimized)
    
    def get_recommendation(self, missing, score):
        """Generate tailored recommendations"""
        if score >= 90:
            return "🎯 Excellent match! Your resume aligns very well with this role."
        elif score >= 70:
            return f"✅ Good match! Consider emphasizing: {', '.join([m.upper() for m in missing[:3]])}"
        elif score >= 50:
            return f"⚠️ Moderate match. Focus on adding: {', '.join([m.upper() for m in missing[:3]])}"
        else:
            return f"❌ Add these essential skills: {', '.join([m.upper() for m in missing[:5]])}"
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()