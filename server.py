from http.server import BaseHTTPRequestHandler, HTTPServer
import json, random, os, urllib.parse

os.makedirs("circuits", exist_ok=True)

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length)
        code = str(random.randint(1000, 9999))
        with open(f"circuits/{code}.json", "wb") as f:
            f.write(body)
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"ok": True, "code": code}).encode())

    def do_GET(self):
        qs = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        code = qs.get("code", [""])[0]
        path = f"circuits/{code}.json"
        if code.isdigit() and os.path.exists(path):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            with open(path, "rb") as f:
                self.wfile.write(f.read())
        else:
            self.send_response(404)
            self.end_headers()

HTTPServer(("0.0.0.0", 5050), Handler).serve_forever()
