import http.server
import socketserver
import os
import sys

PORT = 8888
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")

class CleanHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

if __name__ == '__main__':
    if not os.path.exists(DIRECTORY):
        print(f"Error: Directory {DIRECTORY} not found.")
        sys.exit(1)

    socketserver.TCPServer.allow_reuse_address = True
    with http.server.ThreadingHTTPServer(("0.0.0.0", PORT), CleanHandler) as httpd:
        print(f"Server listening on http://0.0.0.0:{PORT}")
        sys.stdout.flush()
        httpd.serve_forever()
