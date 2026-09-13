"""Compatibility entry point for existing Render configuration."""
import argparse
import os
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import uvicorn

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', default='0.0.0.0')
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).resolve().parent.parent / '.env')
    # Railway injects PORT at runtime. Keep accepting the old Render-style
    # ``--port $PORT`` command if it remains configured on an existing service:
    # argparse receives ``$PORT`` literally there, so resolve it from env.
    parser.add_argument('--port', default=None)
    args = parser.parse_args()
    raw_port = args.port
    if raw_port is None or raw_port == '$PORT':
        raw_port = os.getenv('PORT')
    try:
        port = int(raw_port or 8080)
    except (TypeError, ValueError):
        port = 8080
    uvicorn.run('server.api:app', host=args.host, port=port, workers=1)
