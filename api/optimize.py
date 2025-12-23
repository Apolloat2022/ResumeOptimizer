from http.server import BaseHTTPRequestHandler
import json

class handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        data = json.loads(post_data)

        resume = data.get('resume', '').lower()
        jd = data.get('jobDescription', '').lower()
        
        # Expanded skill list
        skills = ["agile", "scrum", "python", "sql", "leadership", "jira", "aws", "project management"]
        required = [s for s in skills if s in jd]
        found = [s for s in required if s in resume]
        missing = [s for s in required if s not in found]
        
        score = round((len(found) / len(required)) * 100) if required else 100

        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        response = {
            "matchScore": score,
            "keywords": found,
            "missing": missing,
            "recommendation": f"Add {', '.join(missing)} to your resume." if missing else "Great match!"
        }
        self.wfile.write(json.dumps(response).encode())
