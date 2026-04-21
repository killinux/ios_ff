"""
Video Feed Service - serves video feed JSON and video files.
Start: python3 feed_server.py [host] [port]
"""
import json, os, sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote

VIDEO_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "videos")

FEED_DATA = [
    {"id": "1", "fileName": "test1", "fileExt": "mp4",
     "author": "@fantasy_world", "description": "Sintel - the dragon hunter �� #fantasy #animation",
     "likes": 210000, "comments": 12000, "shares": 15000, "musicName": "Epic Orchestra - Sintel OST"},
    {"id": "2", "fileName": "test2", "fileExt": "mp4",
     "author": "@3d_art", "description": "Big Buck Bunny trailer 🐰 #blender #3d #opensource",
     "likes": 156000, "comments": 8900, "shares": 12000, "musicName": "Bunny Adventure - Full Score"},
    {"id": "3", "fileName": "test4", "fileExt": "mp4",
     "author": "@cinema_daily", "description": "Classic movie scene 🎬 #movie #cinema #retro",
     "likes": 45200, "comments": 1203, "shares": 567, "musicName": "Original Score - Movie Classics"},
]


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *a):
        sys.stderr.write("[%s] %s\n" % (self.client_address[0], fmt % a))

    def _json(self, code, obj):
        body = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/api/feed":
            host = self.headers.get("Host", "localhost:8085")
            scheme = "http"
            feed = []
            for item in FEED_DATA:
                entry = dict(item)
                entry["videoUrl"] = f"{scheme}://{host}/videos/{item['fileName']}.{item['fileExt']}"
                feed.append(entry)
            return self._json(200, {"videos": feed})

        if self.path.startswith("/videos/"):
            filename = unquote(self.path[len("/videos/"):])
            if "/" in filename or ".." in filename:
                return self._json(400, {"error": "bad request"})
            filepath = os.path.join(VIDEO_DIR, filename)
            if not os.path.isfile(filepath):
                return self._json(404, {"error": "not found"})
            size = os.path.getsize(filepath)
            self.send_response(200)
            self.send_header("Content-Type", "video/mp4")
            self.send_header("Content-Length", str(size))
            self.send_header("Accept-Ranges", "bytes")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            with open(filepath, "rb") as f:
                while True:
                    chunk = f.read(65536)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
            return

        if self.path == "/health":
            return self._json(200, {"status": "ok"})

        self._json(404, {"error": "not found"})


if __name__ == "__main__":
    host = sys.argv[1] if len(sys.argv) > 1 else "0.0.0.0"
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8085
    print(f"Feed server on {host}:{port}, videos from {VIDEO_DIR}")
    ThreadingHTTPServer((host, port), Handler).serve_forever()
