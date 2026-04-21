"""
Video Feed Service with pagination.
GET /api/feed?page=0  -> 5 videos per page, cycles through 15 items.
"""
import json, os, sys, re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlparse, parse_qs

VIDEO_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "videos")
PAGE_SIZE = 5

VIDEO_FILES = [
    "v1_bunny_10s.mp4", "v2_sample_5s.mp4", "v3_movie.mp4", "v4_sample2.mp4",
    "v5_sintel.mp4", "v6_bunny_trailer.mp4", "v7_sample_10s.mp4", "v8_sample_15s.mp4",
]

ALL_ITEMS = [
    {"author": "@fantasy_world", "description": "Sintel - epic dragon battle #fantasy #animation", "likes": 210000, "comments": 12000, "shares": 15000, "musicName": "Epic Orchestra - Sintel OST"},
    {"author": "@3d_art", "description": "Beautiful 3D landscapes #art #blender #creative", "likes": 156000, "comments": 8900, "shares": 12000, "musicName": "Ambient Dreams - Chill"},
    {"author": "@nature_vibes", "description": "Peaceful nature moments #nature #relax #zen", "likes": 89000, "comments": 3400, "shares": 2100, "musicName": "Forest Sounds - Nature Mix"},
    {"author": "@cinema_daily", "description": "Classic movie scene remake #movie #cinema", "likes": 45200, "comments": 1203, "shares": 567, "musicName": "Original Score - Classics"},
    {"author": "@short_clips", "description": "10 second challenge! #challenge #viral #trending", "likes": 320000, "comments": 18000, "shares": 25000, "musicName": "Trending Beat #1"},
    {"author": "@travel_daily", "description": "Hidden gem discovered #travel #explore #adventure", "likes": 67800, "comments": 2300, "shares": 1500, "musicName": "Wanderlust - Travel Beats"},
    {"author": "@animation_fan", "description": "When the animation hits different #animation #wow", "likes": 128000, "comments": 5600, "shares": 8900, "musicName": "Feel Good Inc - Remix"},
    {"author": "@tech_guru", "description": "Future of AI is here #tech #ai #future", "likes": 445000, "comments": 23000, "shares": 45000, "musicName": "Digital Dreams - Synth"},
    {"author": "@comedy_king", "description": "Wait for it... #funny #comedy #lol", "likes": 890000, "comments": 45000, "shares": 67000, "musicName": "Funny Moments - DJ Mix"},
    {"author": "@food_lover", "description": "Making perfect ramen #food #cooking #ramen", "likes": 234000, "comments": 12000, "shares": 18000, "musicName": "Kitchen Vibes - Chef OST"},
    {"author": "@sports_daily", "description": "Insane goal from last night #sports #soccer", "likes": 567000, "comments": 34000, "shares": 78000, "musicName": "Stadium Anthem - Crowd"},
    {"author": "@music_lover", "description": "This beat is fire #music #beats #producer", "likes": 345000, "comments": 15000, "shares": 23000, "musicName": "Fire Beat - Original"},
    {"author": "@dance_queen", "description": "New dance trend alert #dance #trending #viral", "likes": 678000, "comments": 38000, "shares": 56000, "musicName": "Dance Floor - DJ Remix"},
    {"author": "@pet_lover", "description": "My cat did WHAT #cats #pets #funny", "likes": 920000, "comments": 56000, "shares": 89000, "musicName": "Cute Animals - Happy Tune"},
    {"author": "@diy_master", "description": "5-minute room makeover #diy #home #design", "likes": 189000, "comments": 8900, "shares": 12000, "musicName": "Creative Flow - Lofi"},
]

TOTAL_ITEMS = len(ALL_ITEMS)


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

    def _serve_video(self, filepath, head_only=False):
        size = os.path.getsize(filepath)
        range_header = self.headers.get("Range")
        if range_header:
            m = re.match(r"bytes=(\d+)-(\d*)", range_header)
            if m:
                start = int(m.group(1))
                end = int(m.group(2)) if m.group(2) else size - 1
                end = min(end, size - 1)
                length = end - start + 1
                self.send_response(206)
                self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
                self.send_header("Content-Length", str(length))
            else:
                start, length = 0, size
                self.send_response(200)
                self.send_header("Content-Length", str(size))
        else:
            start, length = 0, size
            self.send_response(200)
            self.send_header("Content-Length", str(size))
        self.send_header("Content-Type", "video/mp4")
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        if head_only:
            return
        with open(filepath, "rb") as f:
            f.seek(start)
            remaining = length
            while remaining > 0:
                chunk = f.read(min(65536, remaining))
                if not chunk:
                    break
                self.wfile.write(chunk)
                remaining -= len(chunk)

    def _route(self, head_only=False):
        parsed = urlparse(self.path)
        path = parsed.path
        params = parse_qs(parsed.query)

        if path == "/api/feed":
            if head_only:
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                return
            page = int(params.get("page", ["0"])[0])
            start = (page * PAGE_SIZE) % TOTAL_ITEMS
            host = self.headers.get("Host", "localhost:8085")
            videos = []
            for i in range(PAGE_SIZE):
                idx = (start + i) % TOTAL_ITEMS
                item = ALL_ITEMS[idx]
                video_file = VIDEO_FILES[idx % len(VIDEO_FILES)]
                videos.append({
                    "id": f"p{page}_{i}",
                    "author": item["author"],
                    "description": item["description"],
                    "likes": item["likes"],
                    "comments": item["comments"],
                    "shares": item["shares"],
                    "musicName": item["musicName"],
                    "videoUrl": f"http://{host}/videos/{video_file}",
                })
            return self._json(200, {"videos": videos, "page": page, "hasMore": True})

        if path.startswith("/videos/"):
            filename = unquote(path[len("/videos/"):])
            if "/" in filename or ".." in filename:
                return self._json(400, {"error": "bad request"})
            filepath = os.path.join(VIDEO_DIR, filename)
            if not os.path.isfile(filepath):
                return self._json(404, {"error": "not found"})
            return self._serve_video(filepath, head_only)

        if path == "/health":
            return self._json(200, {"status": "ok"})

        self._json(404, {"error": "not found"})

    def do_GET(self):
        self._route(head_only=False)

    def do_HEAD(self):
        self._route(head_only=True)


if __name__ == "__main__":
    host = sys.argv[1] if len(sys.argv) > 1 else "0.0.0.0"
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8085
    print(f"Feed server on {host}:{port}, videos from {VIDEO_DIR}")
    ThreadingHTTPServer((host, port), Handler).serve_forever()
