from http.server import BaseHTTPRequestHandler
import json
class handler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        data = json.loads(post_data)
        resume, jd = data.get('resume', '').lower(), data.get('jobDescription', '').lower()
        skills = ["agile", "scrum", "python", "sql", "leadership", "jira", "aws"]
        req = [s for s in skills if s in jd]; found = [s for s in req if s in resume]
        miss = [s for s in req if s not in found]; score = round((len(found)/len(req))*100) if req else 100
        self.send_response(200); self.send_header('Content-Type', 'application/json'); self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers()
        self.wfile.write(json.dumps({"matchScore": score, "keywords": found, "missing": miss, "recommendation": f"Add {', '.join(miss)}" if miss else "Great match!"}).encode())
    def do_OPTIONS(self):
        self.send_response(200); self.send_header('Access-Control-Allow-Origin', '*'); self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS'); self.send_header('Access-Control-Allow-Headers', 'Content-Type'); self.end_headers()
