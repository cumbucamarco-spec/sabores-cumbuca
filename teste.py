from http.server import HTTPServer, BaseHTTPRequestHandler

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Servidor OK")

server = HTTPServer(("localhost", 5000), H)
print("RODANDO...")
server.serve_forever()