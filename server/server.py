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
    try:
        default_port = int(os.getenv('PORT') or 8080)
    except ValueError:
        default_port = 8080
    parser.add_argument('--port', type=int, default=default_port)
    args = parser.parse_args()
    uvicorn.run('server.api:app', host=args.host, port=args.port, workers=1)
