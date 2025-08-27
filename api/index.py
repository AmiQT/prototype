from http.server import BaseHTTPRequestHandler
import json
import urllib.parse

class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            # Parse the URL
            parsed_path = urllib.parse.urlparse(self.path)
            path = parsed_path.path
            
            # Set CORS headers
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', '*')
            self.end_headers()
            
            # Route handling
            if path == '/health':
                response = {
                    "status": "healthy",
                    "services": {
                        "api": "running",
                        "environment": "vercel_http"
                    }
                }
            elif path == '/':
                response = {
                    "message": "Student Talent Analytics API",
                    "version": "1.0.0",
                    "status": "healthy"
                }
            elif path.startswith('/api/'):
                if path == '/api/test':
                    response = {
                        "message": "API is working!",
                        "platform": "vercel_http"
                    }
                elif path == '/api/users':
                    response = {
                        "users": [],
                        "message": "Users endpoint working"
                    }
                elif path == '/api/events':
                    response = {
                        "events": [],
                        "message": "Events endpoint working"
                    }
                elif path == '/api/users/stats':
                    response = {
                        "overview": {
                            "total_users": 0,
                            "total_events": 0,
                            "total_posts": 0
                        },
                        "message": "Stats endpoint working"
                    }
                else:
                    response = {
                        "error": "API endpoint not found",
                        "path": path
                    }
            else:
                response = {
                    "error": "Not found",
                    "path": path
                }
            
            # Send response
            self.wfile.write(json.dumps(response).encode())
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            error_response = {
                "error": "Internal server error",
                "message": str(e)
            }
            self.wfile.write(json.dumps(error_response).encode())
    
    def do_POST(self):
        try:
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', '*')
            self.end_headers()
            
            response = {
                "message": "POST endpoint working",
                "path": self.path
            }
            
            self.wfile.write(json.dumps(response).encode())
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            error_response = {
                "error": "POST error",
                "message": str(e)
            }
            self.wfile.write(json.dumps(error_response).encode())
    
    def do_OPTIONS(self):
        try:
            self.send_response(200)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', '*')
            self.end_headers()
        except Exception as e:
            self.send_response(500)
            self.end_headers()