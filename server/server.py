"""Servidor de cadastro de salas recreativas. Python 3.10+, sem dependências."""
import argparse
import json
import secrets
import string
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOMS = {}
LOCK = threading.Lock()
TTL = 6 * 60 * 60

class Handler(BaseHTTPRequestHandler):
    def reply(self, status, data):
        payload = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(payload)))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.end_headers()
        self.wfile.write(payload)

    def do_OPTIONS(self):
        self.reply(200, {})

    def do_GET(self):
        if self.path in ('/', '/health'):
            self.reply(200, {'status': 'ok', 'mode': 'recreational-demo'})
        else:
            self.reply(404, {'error': 'Rota não encontrada'})

    def do_POST(self):
        try:
            length = int(self.headers.get('Content-Length', '0'))
            if not 0 < length <= 4096:
                self.reply(413, {'error': 'Corpo inválido ou muito grande'})
                return
            data = json.loads(self.rfile.read(length))
            if not isinstance(data, dict):
                raise ValueError()
        except (ValueError, UnicodeDecodeError):
            self.reply(400, {'error': 'JSON inválido'})
            return
        with LOCK:
            for code in list(ROOMS):
                if time.time() - ROOMS[code]['created_at'] > TTL:
                    del ROOMS[code]
            if self.path == '/rooms':
                name, capacity, private = data.get('name'), data.get('capacity'), data.get('private')
                if not isinstance(name, str) or not 1 <= len(name.strip()) <= 32 or type(capacity) is not int or capacity not in (2, 3, 4) or type(private) is not bool:
                    self.reply(400, {'error': 'Nome, capacidade (2–4) e privacidade obrigatórios'})
                    return
                if len(ROOMS) >= 1000:
                    self.reply(503, {'error': 'Limite de salas atingido'})
                    return
                code = ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(6))
                while code in ROOMS:
                    code = ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(6))
                room = {'code': code, 'name': name.strip(), 'capacity': capacity, 'private': private, 'players': [], 'pot': 0, 'street': 0, 'turn': 0, 'actions': [], 'created_at': time.time()}
                ROOMS[code] = room
                self.reply(201, room)
            elif self.path.startswith('/rooms/') and self.path.endswith('/join'):
                code = self.path.split('/')[2]
                room = ROOMS.get(code)
                if room and isinstance(data.get('name', 'Jogador'), str):
                    if len(room['players']) >= room['capacity']:
                        self.reply(409, {'error': 'Sala cheia'})
                        return
                    player = data.get('name', 'Jogador').strip()[:20] or 'Jogador'
                    if player not in room['players']: room['players'].append(player)
                self.reply(200 if room else 404, room or {'error': 'Sala não encontrada ou expirada'})
            elif self.path.startswith('/rooms/') and self.path.endswith('/state'):
                code = self.path.split('/')[2]; room = ROOMS.get(code)
                self.reply(200 if room else 404, room or {'error': 'Sala não encontrada'})
            elif self.path.startswith('/rooms/') and self.path.endswith('/action'):
                code = self.path.split('/')[2]; room = ROOMS.get(code)
                if not room: self.reply(404, {'error':'Sala não encontrada'}); return
                action = data.get('action')
                if action not in ('check','call','raise','fold'): self.reply(400, {'error':'Ação inválida'}); return
                room['actions'].append({'player':data.get('player','Jogador'),'action':action,'amount':data.get('amount',0)})
                if action in ('call','raise'): room['pot'] += max(0, min(int(data.get('amount',20)), 100000))
                room['turn'] = (room['turn'] + 1) % max(1, len(room['players']))
                if room['turn'] == 0: room['street'] = min(5, room['street'] + 1)
                self.reply(200, room)
            else:
                self.reply(404, {'error': 'Rota não encontrada'})

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', default='0.0.0.0')
    parser.add_argument('--port', default=8080, type=int)
    args = parser.parse_args()
    print(f'Aurora Cards: http://{args.host}:{args.port}', flush=True)
    ThreadingHTTPServer((args.host, args.port), Handler).serve_forever()
