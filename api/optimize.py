from http.server import BaseHTTPRequestHandler
import json
import re
import base64
from io import BytesIO

try:
    from PyPDF2 import PdfReader
    from reportlab.lib.pagesizes import letter
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
    from reportlab.lib.enums import TA_LEFT, TA_CENTER
    PDF_SUPPORT = True
except ImportError:
    PDF_SUPPORT = False

class handler(BaseHTTPRequestHandler):
    def do_POST(self):
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            
            resume = data.get('resume', '')
            jd = data.get('jobDescription', '')
            pdf_file = data.get('pdfFile', None)
            generate_pdf = data.get('generatePdf', False)
            
            # Handle PDF upload - extract text from PDF
            if pdf_file and PDF_SUPPORT:
                try:
                    pdf_bytes = base64.b64decode(pdf_file.split(',')[1] if ',' in pdf_file else pdf_file)
                    pdf_reader = PdfReader(BytesIO(pdf_bytes))
                    
                    resume_text = ""
                    for page in pdf_reader.pages:
                        resume_text += page.extract_text() + "\n"
                    
                    # Use PDF text if resume field is empty, otherwise prefer typed text
                    if resume_text.strip() and not resume.strip():
                        resume = resume_text
                except Exception as e:
                    # If PDF fails, fall back to text input
                    if not resume.strip():
                        return self.send_error(400, f"PDF parsing error: {str(e)}")
            
            if not resume or not jd:
                return self.send_error(400, "Missing resume or job description")
            
            # Normalize text for better matching
            resume_normalized = self.normalize_text(resume)
            jd_normalized = self.normalize_text(jd)
            
            # Extract skills and keywords with better matching
            analysis = self.analyze_match(resume_normalized, jd_normalized, resume, jd)
            
            # Generate optimized resume text
            optimized_text = self.optimize_resume(resume, analysis['missing'], analysis['found'], jd)
            
            # Generate PDF if requested
            pdf_base64 = None
            if generate_pdf and PDF_SUPPORT:
                pdf_base64 = self.generate_ats_pdf(optimized_text, data.get('name', 'Candidate'))
            
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
                "pdfSupport": PDF_SUPPORT,
                "optimizedPdf": pdf_base64,
                "debug": {
                    "resumeLength": len(resume),
                    "jdLength": len(jd),
                    "totalKeywords": len(analysis['required'])
                }
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
        # Convert to lowercase
        text = text.lower()
        # Replace common variations
        replacements = {
            'node.js': 'nodejs',
            'node js': 'nodejs',
            'ci/cd': 'cicd',
            'c#': 'csharp',
            'c++': 'cplusplus',
            '.net': 'dotnet'
        }
        for old, new in replacements.items():
            text = text.replace(old, new)
        return text
    
    def analyze_match(self, resume_norm, jd_norm, resume_orig, jd_orig):
        """Analyze keyword match between resume and job description"""
        
        # Define comprehensive keyword list with variations
        keyword_map = {
            'python': ['python', 'py'],
            'javascript': ['javascript', 'js', 'ecmascript'],
            'typescript': ['typescript', 'ts'],
            'react': ['react', 'reactjs', 'react.js'],
            'nodejs': ['nodejs', 'node', 'node.js'],
            'java': ['java'],
            'git': ['git', 'github', 'gitlab', 'version control'],
            'docker': ['docker', 'container'],
            'kubernetes': ['kubernetes', 'k8s'],
            'aws': ['aws', 'amazon web services'],
            'azure': ['azure', 'microsoft azure'],
            'cicd': ['cicd', 'ci/cd', 'continuous integration', 'continuous deployment'],
            'devops': ['devops', 'dev ops'],
            'agile': ['agile'],
            'scrum': ['scrum'],
            'leadership': ['leadership', 'lead', 'leading', 'led'],
            'mentoring': ['mentoring', 'mentor', 'mentored'],
            'frontend': ['frontend', 'front-end', 'front end'],
            'backend': ['backend', 'back-end', 'back end'],
            'fullstack': ['fullstack', 'full-stack', 'full stack'],
            'sql': ['sql', 'mysql', 'postgresql', 'database'],
            'api': ['api', 'rest', 'restful'],
            'testing': ['testing', 'test', 'qa'],
            'security': ['security', 'secure'],
            'html': ['html', 'html5'],
            'css': ['css', 'css3', 'sass', 'scss'],
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
            'found': found,
            'missing': missing,
            'required': required
        }
    
    def optimize_resume(self, resume, missing, found, jd):
        """Generate an optimized version of the resume"""
        
        lines = resume.strip().split('\n')
        optimized = []
        
        # Keep original resume structure
        optimized.append(resume)
        optimized.append('\n\n')
        optimized.append('=' * 70)
        optimized.append('ATS OPTIMIZATION REPORT')
        optimized.append('=' * 70)
        optimized.append('')
        
        # Match analysis
        total = len(found) + len(missing)
        score = round((len(found) / total) * 100) if total > 0 else 100
        
        optimized.append(f'✓ Match Score: {score}%')
        optimized.append(f'✓ Keywords Matched: {len(found)} out of {total}')
        optimized.append('')
        
        # Keywords found
        if found:
            optimized.append('✅ KEYWORDS FOUND IN YOUR RESUME:')
            optimized.append(', '.join([k.upper() for k in sorted(found)]))
            optimized.append('')
        
        # Missing keywords with recommendations
        if missing:
            optimized.append('⚠️  MISSING KEYWORDS TO ADD:')
            optimized.append(', '.join([k.upper() for k in sorted(missing)]))
            optimized.append('')
            optimized.append('RECOMMENDATIONS:')
            optimized.append('')
            
            suggestions = {
                'docker': '• Add: "Experience with Docker containerization and container orchestration"',
                'kubernetes': '• Add: "Deployed applications using Kubernetes for scalable infrastructure"',
                'nodejs': '• Add: "Built backend services using Node.js and Express"',
                'testing': '• Add: "Implemented comprehensive testing strategies including unit and integration tests"',
                'security': '• Add: "Applied security best practices including authentication, authorization, and data encryption"',
            }
            
            for skill in missing[:5]:
                if skill in suggestions:
                    optimized.append(suggestions[skill])
                else:
                    optimized.append(f'• Add: "Proficient in {skill.upper()}" to your Technical Skills section')
            
            optimized.append('')
        
        # ATS tips
        optimized.append('=' * 70)
        optimized.append('ATS-FRIENDLY FORMATTING TIPS:')
        optimized.append('=' * 70)
        optimized.append('• Use standard section headers (Experience, Education, Skills)')
        optimized.append('• Avoid tables, columns, headers/footers, and images')
        optimized.append('• Use standard fonts (Arial, Calibri, Times New Roman)')
        optimized.append('• Save as .docx or PDF (ensure PDF is text-based, not scanned)')
        optimized.append('• Include keywords naturally throughout your resume')
        optimized.append('• Use bullet points for achievements and responsibilities')
        
        return '\n'.join(optimized)
    
    def generate_ats_pdf(self, text, name):
        """Generate ATS-friendly PDF resume"""
        try:
            buffer = BytesIO()
            doc = SimpleDocTemplate(buffer, pagesize=letter,
                                   topMargin=0.75*inch, bottomMargin=0.75*inch,
                                   leftMargin=0.75*inch, rightMargin=0.75*inch)
            
            styles = getSampleStyleSheet()
            
            title_style = ParagraphStyle(
                'CustomTitle',
                parent=styles['Heading1'],
                fontSize=14,
                textColor='#000000',
                spaceAfter=6,
                alignment=TA_CENTER,
                fontName='Helvetica-Bold'
            )
            
            heading_style = ParagraphStyle(
                'CustomHeading',
                parent=styles['Heading2'],
                fontSize=11,
                textColor='#000000',
                spaceAfter=6,
                spaceBefore=10,
                fontName='Helvetica-Bold'
            )
            
            body_style = ParagraphStyle(
                'CustomBody',
                parent=styles['Normal'],
                fontSize=10,
                textColor='#000000',
                spaceAfter=4,
                fontName='Helvetica'
            )
            
            story = []
            lines = text.split('\n')
            
            for line in lines:
                line = line.strip()
                if not line:
                    story.append(Spacer(1, 0.1*inch))
                    continue
                
                # Escape special characters
                safe_line = line.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
                
                # Apply styles based on content
                if line.startswith('===') or line.startswith('---'):
                    continue
                elif line.isupper() and len(line) < 50:
                    story.append(Paragraph(safe_line, heading_style))
                elif line.startswith('•') or line.startswith('✓') or line.startswith('✅') or line.startswith('⚠️'):
                    story.append(Paragraph(safe_line, body_style))
                else:
                    story.append(Paragraph(safe_line, body_style))
            
            doc.build(story)
            pdf_bytes = buffer.getvalue()
            buffer.close()
            
            return base64.b64encode(pdf_bytes).decode('utf-8')
            
        except Exception as e:
            return None
    
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