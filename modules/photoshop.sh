cat > install-photopea-pdn-handler.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
MIME_DIR="$HOME/.local/share/mime/packages"

mkdir -p "$BIN_DIR" "$APP_DIR" "$MIME_DIR"

cat > "$BIN_DIR/photopea-pdn-handler" <<'PY'
#!/usr/bin/env python3
import sys
import json
import threading
import subprocess
import urllib.parse
from pathlib import Path
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

if len(sys.argv) < 2:
    print("Usage: photopea-pdn-handler FILE.pdn", file=sys.stderr)
    sys.exit(1)

file_path = Path(sys.argv[1]).expanduser().resolve()

if not file_path.is_file():
    print(f"File not found: {file_path}", file=sys.stderr)
    sys.exit(1)

filename = file_path.name
done = threading.Event()
server_ref = None

class Server(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print(fmt % args)

    def cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Private-Network", "true")

    def do_OPTIONS(self):
        self.send_response(204)
        self.cors()
        self.end_headers()

    def do_GET(self):
        path = urllib.parse.urlparse(self.path).path

        if path.startswith("/file/"):
            self.send_response(200)
            self.cors()
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Disposition", f'inline; filename="{filename}"')
            self.send_header("Content-Length", str(file_path.stat().st_size))
            self.end_headers()

            with open(file_path, "rb") as f:
                while True:
                    chunk = f.read(1024 * 1024)
                    if not chunk:
                        break
                    self.wfile.write(chunk)

            done.set()
            threading.Thread(target=server_ref.shutdown, daemon=True).start()
            return

        self.send_response(404)
        self.cors()
        self.end_headers()

server_ref = Server(("127.0.0.1", 0), Handler)
port = server_ref.server_port

file_url = f"http://127.0.0.1:{port}/file/{urllib.parse.quote(filename)}"
config = {"files": [file_url]}
photopea_url = "https://www.photopea.com#" + urllib.parse.quote(json.dumps(config))

print("Opening:", filename)

subprocess.Popen(
    ["xdg-open", photopea_url],
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL
)

server_ref.serve_forever()

if done.is_set():
    print("File sent to Photopea.")
else:
    print("Server stopped before file was sent.", file=sys.stderr)
PY

chmod +x "$BIN_DIR/photopea-pdn-handler"

cat > "$MIME_DIR/photopea-pdn.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-pdn">
    <comment>Paint.NET image</comment>
    <glob pattern="*.pdn"/>
    <glob pattern="*.PDN"/>
  </mime-type>
</mime-info>
XML

cat > "$APP_DIR/photopea-pdn-handler.desktop" <<EOF_DESKTOP
[Desktop Entry]
Type=Application
Name=Photopea PDN Handler
Comment=Open local PDN files in Photopea
Exec=$BIN_DIR/photopea-pdn-handler %f
Terminal=false
MimeType=application/x-pdn;
Categories=Graphics;RasterGraphics;
NoDisplay=false
EOF_DESKTOP

update-mime-database "$HOME/.local/share/mime"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APP_DIR"
fi

xdg-mime default photopea-pdn-handler.desktop application/x-pdn

echo "Installed Photopea PDN handler."
echo
echo "Default app:"
xdg-mime query default application/x-pdn
echo
echo "Manual test:"
echo "$BIN_DIR/photopea-pdn-handler /path/to/file.pdn"
EOF

chmod +x install-photopea-pdn-handler.sh
./install-photopea-pdn-handler.sh
