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
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
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
            
            # Handle PDF upload
            if pdf_file and PDF_SUPPORT:
                try:
                    # Decode base64 PDF
                    pdf_bytes = base64.b64decode(pdf_file.split(',')[1] if ',' in pdf_file else pdf_file)
                    pdf_reader = PdfReader(BytesIO(pdf_bytes))
                    
                    # Extract text from all pages
                    resume_text = ""
                    for page in pdf_reader.pages:
                        resume_text += page.extract_text() + "\n"
                    
                    resume = resume_text
                except Exception as e:
                    return self.send_error(400, f"PDF parsing error: {str(e)}")
            
            if not resume or not jd:
                return self.send_error(400, "Missing resume or job description")
            
            # Extract keywords from job description
            jd_lower = jd.lower()
            resume_lower = resume.lower()
            
            # Comprehensive tech skills and keywords
            all_keywords = [
                # Programming Languages
                "python", "javascript", "typescript", "java", "c++", "c#", "go", "rust", "ruby", "php",
                # Frontend
                "react", "vue", "angular", "html", "css", "sass", "tailwind", "bootstrap",
                # Backend
                "node.js", "express", "django", "flask", "spring", "fastapi", ".net",
                # Databases
                "sql", "postgresql", "mysql", "mongodb", "redis", "elasticsearch",
                # Cloud & DevOps
                "aws", "azure", "gcp", "docker", "kubernetes", "ci/cd", "jenkins", "github actions",
                "terraform", "ansible", "devops",
                # Methodologies
                "agile", "scrum", "kanban", "waterfall", "test-driven",
                # Skills
                "leadership", "mentoring", "frontend", "backend", "full-stack", "api", "rest", "graphql",
                "git", "security", "testing", "debugging", "architecture", "microservices"
            ]
            
            required = [k for k in all_keywords if k in jd_lower]
            found = [k for k in required if k in resume_lower]
            missing = [k for k in required if k not in found]
            
            score = round((len(found) / len(required)) * 100) if required else 100
            
            # Generate optimized resume text
            optimized_text = self.optimize_resume(resume, missing, jd, found)
            
            # Generate PDF if requested
            pdf_base64 = None
            if generate_pdf and PDF_SUPPORT:
                pdf_base64 = self.generate_ats_pdf(optimized_text, data.get('name', 'Candidate'))
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            response = {
                "matchScore": score,
                "keywords": found,
                "missing": missing,
                "recommendation": self.get_recommendation(missing, score),
                "optimizedResume": optimized_text,
                "pdfSupport": PDF_SUPPORT,
                "optimizedPdf": pdf_base64
            }
            self.wfile.write(json.dumps(response).encode())
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            error_response = {"error": str(e)}
            self.wfile.write(json.dumps(error_response).encode())
    
    def optimize_resume(self, resume, missing, jd, found):
        """Generate an optimized version of the resume"""
        
        # Parse resume sections
        lines = resume.strip().split('\n')
        sections = {
            'header': [],
            'summary': [],
            'skills': [],
            'experience': [],
            'education': [],
            'other': []
        }
        
        current_section = 'header'
        section_keywords = {
            'summary': ['summary', 'objective', 'profile'],
            'skills': ['skills', 'technical', 'competencies', 'technologies'],
            'experience': ['experience', 'employment', 'work history', 'professional'],
            'education': ['education', 'academic', 'qualification']
        }
        
        # Classify lines into sections
        for line in lines[:50]:  # Process first 50 lines for structure
            line_lower = line.lower().strip()
            
            # Check if line is a section header
            for section, keywords in section_keywords.items():
                if any(kw in line_lower for kw in keywords) and len(line_lower) < 50:
                    current_section = section
                    break
            
            if line.strip():
                sections[current_section].append(line)
        
        # Build optimized resume
        optimized = []
        
        # Header
        optimized.extend(sections['header'][:5])
        optimized.append('')
        
        # Enhanced Summary
        if sections['summary']:
            optimized.append('PROFESSIONAL SUMMARY')
            optimized.append('-' * 50)
            summary_text = ' '.join(sections['summary'])
            
            # Add key missing skills to summary if not there
            skills_to_add = [m for m in missing[:3] if m not in summary_text.lower()]
            if skills_to_add:
                summary_text += f" Proficient in {', '.join(skills_to_add)}."
            
            optimized.append(summary_text)
            optimized.append('')
        
        # Key Technical Skills (ATS-optimized section)
        optimized.append('KEY TECHNICAL SKILLS')
        optimized.append('-' * 50)
        
        all_skills = found + missing[:5]
        optimized.append(' • '.join([skill.title() for skill in all_skills]))
        optimized.append('')
        
        # Experience (keep original but highlight matched skills)
        if sections['experience']:
            optimized.append('PROFESSIONAL EXPERIENCE')
            optimized.append('-' * 50)
            optimized.extend(sections['experience'])
            optimized.append('')
        
        # Education
        if sections['education']:
            optimized.append('EDUCATION')
            optimized.append('-' * 50)
            optimized.extend(sections['education'])
            optimized.append('')
        
        # ATS Optimization Tips
        optimized.append('')
        optimized.append('=== ATS OPTIMIZATION NOTES ===')
        optimized.append(f"✓ Match Score: {round((len(found) / (len(found) + len(missing))) * 100) if (found or missing) else 100}%")
        optimized.append(f"✓ Keywords Matched: {len(found)}")
        
        if missing:
            optimized.append('')
            optimized.append('Recommended additions:')
            for skill in missing[:5]:
                optimized.append(f"  • Add '{skill.title()}' to relevant sections")
        
        return '\n'.join(optimized)
    
    def generate_ats_pdf(self, text, name):
        """Generate ATS-friendly PDF resume"""
        try:
            buffer = BytesIO()
            doc = SimpleDocTemplate(buffer, pagesize=letter,
                                   topMargin=0.75*inch, bottomMargin=0.75*inch,
                                   leftMargin=0.75*inch, rightMargin=0.75*inch)
            
            # Styles
            styles = getSampleStyleSheet()
            
            # Custom ATS-friendly styles
            title_style = ParagraphStyle(
                'CustomTitle',
                parent=styles['Heading1'],
                fontSize=16,
                textColor='#000000',
                spaceAfter=6,
                alignment=TA_CENTER,
                fontName='Helvetica-Bold'
            )
            
            heading_style = ParagraphStyle(
                'CustomHeading',
                parent=styles['Heading2'],
                fontSize=12,
                textColor='#000000',
                spaceAfter=6,
                spaceBefore=12,
                fontName='Helvetica-Bold'
            )
            
            body_style = ParagraphStyle(
                'CustomBody',
                parent=styles['Normal'],
                fontSize=10,
                textColor='#000000',
                spaceAfter=6,
                fontName='Helvetica'
            )
            
            # Build PDF content
            story = []
            lines = text.split('\n')
            
            for line in lines:
                line = line.strip()
                if not line:
                    story.append(Spacer(1, 0.1*inch))
                    continue
                
                # Section headers (all caps or with dashes)
                if line.isupper() or line.startswith('==='):
                    if not line.startswith('==='):
                        story.append(Paragraph(line, heading_style))
                elif line.startswith('-' * 10):
                    continue  # Skip separator lines
                else:
                    # Regular text - escape special characters for reportlab
                    safe_line = line.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
                    story.append(Paragraph(safe_line, body_style))
            
            doc.build(story)
            
            # Get PDF bytes and encode to base64
            pdf_bytes = buffer.getvalue()
            buffer.close()
            
            return base64.b64encode(pdf_bytes).decode('utf-8')
            
        except Exception as e:
            print(f"PDF generation error: {str(e)}")
            return None
    
    def get_recommendation(self, missing, score):
        """Generate tailored recommendations"""
        if score >= 90:
            return "🎯 Excellent match! Your resume aligns very well with this role."
        elif score >= 70:
            return f"✅ Good match! Consider emphasizing: {', '.join(missing[:3])}"
        elif score >= 50:
            return f"⚠️ Moderate match. Focus on adding: {', '.join(missing[:3])}"
        else:
            return f"❌ Significant gaps. Prioritize adding: {', '.join(missing[:5])}"
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()