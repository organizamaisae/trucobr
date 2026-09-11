"""Aurora Truco API. One authoritative worker; PostgreSQL persists all state."""
import asyncio
from contextlib import asynccontextmanager
from datetime import datetime, timezone
import os
import re
import secrets
import time
import contextlib
from fastapi import FastAPI, Request, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse
from .database import Base, engine, Session, get, put, all_of
from . import engine as truco
from .security import password_hash, verify, digest, session

lock = asyncio.Lock()
peers = {}
rates = {}
TIERS = [100, 500, 1000, 5000, 10000]
CATALOG = [dict(id=f'{kind}-{i}', kind=kind, name=name, price=price, icon=icon)
           for kind, names, price, icon in [
               ('avatar', ['Explorador', 'Guardião', 'Estrela'], 500, 'person'),
               ('frame', ['Dourada', 'Esmeralda'], 700, 'circle'),
               ('back', ['Oceano', 'Rubi'], 600, 'style'),
               ('table', ['Floresta', 'Noite'], 1000, 'table'),
               ('emote', ['Boa jogada!', 'Truco!'], 200, 'face'),
               ('effect', ['Brilho'], 800, 'star'),
               ('pass', ['Temporada Aurora'], 3000, 'crown')]
           for i, name in enumerate(names)]


def fail(message, status=400):
    raise HTTPException(status, message)


def now():
    return datetime.now(timezone.utc)


def public(u):
    wins, losses = u['wins'], u['losses']
    return {**{k: u[k] for k in ['id', 'name', 'xp', 'wins', 'losses', 'streak', 'best', 'equipped']},
            'level': 1+u['xp']//1000, 'games': wins+losses,
            'win_rate': round(wins*100/max(1, wins+losses)), 'online': u['id'] in peers}


def user(db, token):
    s = get(db, 'session:'+digest(token))
    if not s or s['expires'] < time.time():
        fail('Entre novamente na sua conta.', 401)
    return get(db, 'user:'+s['uid'])


def ledger(u, amount, reason):
    if u['chips']+amount < 0:
        fail('Saldo de fichas insuficiente.')
    u['chips'] += amount
    u['ledger'].append(dict(amount=amount, reason=reason, date=now().isoformat()))
    u['earned' if amount > 0 else 'spent'] += abs(amount)


def save_user(db, u):
    put(db, 'user:'+u['id'], 'user', u)


def room_view(db, r, uid):
    return {k: v for k, v in r.items() if k not in ['password', 'game']} | {
        'members': [public(get(db, 'user:'+p)) for p in r['players']],
        'game': truco.view(r['game'], uid) if r.get('game') and uid in r['players'] else None}


def active_room(db, uid):
    return next((r for r in all_of(db, 'room') if uid in r['players'] and r['status'] in ['waiting', 'playing']), None)


def create_room(db, u, data, quick=False, tournament=None):
    capacity, fee = data.get('capacity', 2), data.get('fee', 100)
    if capacity not in [2, 4] or type(capacity) is not int or fee not in TIERS+[0] or type(fee) is not int:
        fail('Mesa inválida.')
    rule = data.get('rule', 'paulista')
    if rule not in ['paulista', 'fixa']:
        fail('Regra inválida.')
    if u['chips'] < fee:
        fail('Saldo insuficiente para esta mesa.')
    code = secrets.token_hex(3).upper()
    while get(db, 'room:'+code):
        code = secrets.token_hex(3).upper()
    r = dict(code=code, name=str(data.get('name', 'Mesa de '+u['name']))[:40], host=u['id'],
             capacity=capacity, fee=fee, rule=rule, players=[u['id']], status='waiting', game=None,
             password=password_hash(str(data['password'])) if data.get('password') else None,
             quick=quick, settled=False, tournament=tournament, updated=time.time())
    put(db, 'room:'+code, 'room', r)
    return r


def start_room(db, r):
    if len(r['players']) != r['capacity'] or r['status'] != 'waiting':
        fail('Aguarde todos os jogadores reais entrarem.')
    for uid in r['players']:
        u = get(db, 'user:'+uid)
        ledger(u, -r['fee'], 'Entrada na mesa '+r['code'])
        save_user(db, u)
    r.update(status='playing', game=truco.new_game(r['players'], r['rule']))
    put(db, 'room:'+r['code'], 'room', r)


def settle(db, r):
    g = r['game']
    if g['winner'] is None or r['settled']:
        return
    r.update(settled=True, status='finished')
    for seat, uid in enumerate(r['players']):
        u = get(db, 'user:'+uid)
        won = seat % 2 == g['winner']
        u['wins' if won else 'losses'] += 1
        u['xp'] += 150 if won else 50
        u['streak'] = u['streak']+1 if won else 0
        u['best'] = max(u['best'], u['streak'])
        if won:
            ledger(u, r['fee']*2+100, 'Vitória na mesa '+r['code'])
        u['history'].append(dict(room=r['code'], won=won, date=now().isoformat(), scores=g['scores'], xp=150 if won else 50))
        save_user(db, u)
    if r['tournament']:
        t = get(db, 'tournament:'+r['tournament'])
        for match in t['rounds'][-1]:
            if match['room'] == r['code']:
                match['winner'] = r['players'][g['winner']]
        if all(m['winner'] for m in t['rounds'][-1]):
            winners = [m['winner'] for m in t['rounds'][-1]]
            if len(winners) == 1:
                t.update(status='finished', winner=winners[0])
                u = get(db, 'user:'+winners[0])
                ledger(u, t['size']*250, 'Campeão do torneio')
                u['xp'] += 1000
                save_user(db, u)
            else:
                tournament_round(db, t, winners)
        put(db, 'tournament:'+t['id'], 'tournament', t)


def tournament_round(db, t, entrants):
    matches = []
    for i in range(0, len(entrants), 2):
        r = create_room(db, get(db, 'user:'+entrants[i]), dict(capacity=2, fee=0), tournament=t['id'])
        r['players'] = entrants[i:i+2]
        start_room(db, r)
        matches.append(dict(room=r['code'], players=r['players'], winner=None))
    t['rounds'].append(matches)
    t['status'] = 'playing'


def dashboard(db, u):
    d = now().date().isoformat()
    week = now().strftime('%G-%V')
    daily = sum(h['date'][:10] == d for h in u['history'])
    weekly = sum(datetime.fromisoformat(h['date']).strftime('%G-%V') == week and h['won'] for h in u['history'])
    missions = [dict(id='daily:'+d, name='Jogue 3 partidas hoje', progress=daily, target=3, reward=300),
                dict(id='weekly:'+week, name='Vença 5 partidas nesta semana', progress=weekly, target=5, reward=1500)]
    for m in missions:
        m['claimed'] = m['id'] in u['claims']
    r = active_room(db, u['id'])
    if not r:
        r = next((x for x in reversed(all_of(db, 'room')) if u['id'] in x['players'] and x['status']=='finished'), None)
    return dict(profile=public(u), chips=u['chips'], earned=u['earned'], spent=u['spent'],
                ledger=list(reversed(u['ledger'][-100:])), history=list(reversed(u['history'][-100:])),
                daily_available=u['daily'] != d, inventory=u['inventory'], missions=missions,
                achievements=[dict(name=n, unlocked=u[k] >= v) for n, k, v in [('Primeira vitória', 'wins', 1), ('Dez vitórias', 'wins', 10), ('Invencível: 5 seguidas', 'best', 5), ('Nível 5', 'xp', 4000)]],
                room=room_view(db, r, u['id']) if r else None)


async def maintenance():
    while True:
        await asyncio.sleep(10)
        changed = False
        async with lock:
            with Session.begin() as db:
                for r in all_of(db,'room'):
                    if r['status']=='playing' and time.time()-r['updated']>180:
                        g=r['game']
                        if g['hand_done']:
                            truco.deal(g)
                            g['version']+=1
                        else:
                            team=g['pending']['team'] if g['pending'] else g['turn']%2
                            g['winner']=1-team
                            g['log'].append('Partida encerrada por 3 minutos de inatividade.')
                            settle(db,r)
                        r['updated']=time.time()
                        put(db,'room:'+r['code'],'room',r)
                        changed=True
                    elif r['status']=='waiting' and time.time()-r['updated']>900:
                        r['status']='closed'
                        put(db,'room:'+r['code'],'room',r)
                        changed=True
        if changed:
            await broadcast()


@asynccontextmanager
async def lifespan(app):
    Base.metadata.create_all(engine)
    task=asyncio.create_task(maintenance())
    try:
        yield
    finally:
        task.cancel()
        with contextlib.suppress(asyncio.CancelledError):
            await task


app = FastAPI(title='Aurora Truco', version='2.0.0', lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=os.getenv('CORS_ORIGINS', 'http://localhost:8080').split(','),
                   allow_methods=['GET', 'POST'], allow_headers=['Authorization', 'Content-Type'])


@app.middleware('http')
async def validate_body(request, call_next):
    if request.method=='POST':
        raw=await request.body()
        if len(raw)>8192:
            return JSONResponse({'detail':'Requisição muito grande.'},status_code=413)
        try:
            import json
            body=json.loads(raw)
            if not isinstance(body,dict):
                raise ValueError()
            for key in ['capacity','fee','version','card','value']:
                if key in body and type(body[key]) is not int:
                    raise ValueError()
            for key in ['name','email','password','id','code','action','rule']:
                if key in body and (not isinstance(body[key],str) or len(body[key])>256):
                    raise ValueError()
        except (ValueError,TypeError):
            return JSONResponse({'detail':'Dados inválidos. Confira os campos.'},status_code=422)
    return await call_next(request)


@app.get('/')
@app.get('/health')
def health():
    return dict(status='ok', app='Aurora Truco', version=2)


@app.post('/auth/{action}')
async def auth(action: str, request: Request):
    data = await request.json()
    ip = request.client.host
    stamp, count = rates.get(ip, (time.time(), 0))
    if time.time()-stamp > 60:
        stamp, count = time.time(), 0
    rates[ip] = (stamp, count+1)
    if count >= 20:
        fail('Muitas tentativas. Aguarde um minuto.', 429)
    async with lock:
        with Session.begin() as db:
            email = str(data.get('email', '')).strip().lower()
            password = str(data.get('password', ''))
            if action == 'login':
                index = get(db, 'email:'+email)
                u = get(db, 'user:'+index['id']) if index else None
                if not u or not verify(password[:256], u['password']):
                    fail('E-mail ou senha incorretos.', 401)
            elif action in ['register', 'guest']:
                if action == 'register' and (not re.fullmatch(r'[^\s@]+@[^\s@]+\.[^\s@]+', email) or not 10 <= len(password) <= 128):
                    fail('Use um e-mail válido e senha de 10 a 128 caracteres.')
                if action == 'register' and get(db, 'email:'+email):
                    fail('Este e-mail já está cadastrado.')
                uid = secrets.token_hex(8)
                name = str(data.get('name', 'Visitante')).strip()[:24]
                if len(name) < 2:
                    fail('Nome deve ter pelo menos 2 caracteres.')
                u = dict(id=uid, name=name, email=email if action == 'register' else None,
                         password=password_hash(password) if action == 'register' else None,
                         chips=10250, earned=10250, spent=0, xp=0, wins=0, losses=0, streak=0, best=0,
                         history=[], ledger=[dict(amount=10250, reason='Boas-vindas', date=now().isoformat())],
                         daily='', claims=[], inventory=[], equipped={})
                save_user(db, u)
                if action == 'register':
                    put(db, 'email:'+email, 'email', dict(id=uid))
            else:
                fail('Rota não encontrada.', 404)
            token, s = session()
            s['uid'] = u['id']
            put(db, 'session:'+digest(token), 'session', s)
            return dict(token=token, **dashboard(db, u))


@app.api_route('/api/{path:path}', methods=['GET', 'POST'])
async def api(path: str, request: Request):
    token = request.headers.get('authorization', '').removeprefix('Bearer ')
    body = await request.json() if request.method == 'POST' else dict(request.query_params)
    if not isinstance(body, dict):
        fail('Envie um objeto JSON.')
    if request.method != 'POST' and path not in ['me','profile','shop','ranking','friends','tournaments']:
        fail('Esta operação exige POST.',405)
    async with lock:
        with Session.begin() as db:
            u = user(db, token)
            result = dispatch(db, u, path, body, request.method)
    if path=='logout':
        for ws in peers.pop(u['id'],set()):
            await ws.close(code=1000)
    if request.method=='POST':
        await broadcast()
    return result


def dispatch(db, u, path, b, method):
    uid = u['id']
    if path == 'me':
        return dashboard(db, u)
    if path == 'profile':
        if method == 'POST':
            name = str(b.get('name', u['name'])).strip()
            if not 2 <= len(name) <= 24:
                fail('Nome deve ter de 2 a 24 caracteres.')
            u['name'] = name
            save_user(db, u)
        other = get(db, 'user:'+b.get('id', uid))
        if not other:
            fail('Jogador não encontrado.', 404)
        return public(other)
    if path == 'logout':
        for s in list(db.query(__import__('server.database', fromlist=['Record']).Record).filter_by(kind='session')):
            if s.data['uid'] == uid:
                db.delete(s)
        return dict(ok=True)
    if path == 'reward':
        claim = b.get('id', 'daily')
        if claim == 'daily':
            if u['daily'] == now().date().isoformat():
                fail('Bônus de hoje já resgatado.')
            u['daily'] = now().date().isoformat()
            ledger(u, 300, 'Bônus diário')
            if 'pass-0' in u['inventory']:
                ledger(u,100,'Bônus do passe Aurora')
                u['xp']+=50
        else:
            m = next((m for m in dashboard(db, u)['missions'] if m['id'] == claim), None)
            if not m or m['claimed'] or m['progress'] < m['target']:
                fail('Missão ainda não disponível.')
            u['claims'].append(claim)
            ledger(u, m['reward'], m['name'])
        save_user(db, u)
        return dashboard(db, u)
    if path == 'shop':
        if method == 'POST':
            item = next((x for x in CATALOG if x['id'] == b.get('id')), None)
            if not item:
                fail('Item inválido.')
            if b.get('equip'):
                if item['id'] not in u['inventory']:
                    fail('Adquira este item primeiro.')
                u['equipped'][item['kind']] = item['id']
            elif item['id'] not in u['inventory']:
                ledger(u, -item['price'], 'Loja: '+item['name'])
                u['inventory'].append(item['id'])
            save_user(db, u)
        return dict(items=CATALOG, inventory=u['inventory'], equipped=u['equipped'])
    if path == 'ranking':
        users = all_of(db, 'user')
        mode = b.get('mode', 'global')
        if mode == 'friends':
            ids = friend_ids(db, uid)+[uid]
            users = [p for p in users if p['id'] in ids]
        rows = []
        week = now().strftime('%G-%V')
        for p in users:
            score = sum(h['won']*100 for h in p['history'] if datetime.fromisoformat(h['date']).strftime('%G-%V') == week) if mode == 'weekly' else p['wins']*100
            rows.append(dict(**public(p), points=score))
        rows.sort(key=lambda x: (-x['points'], x['id']))
        return dict(players=[dict(**p, position=i+1) for i, p in enumerate(rows[:100])], position=next((i+1 for i,p in enumerate(rows) if p['id']==uid), None))
    if path == 'friends':
        if method == 'POST':
            target = str(b.get('id', ''))
            if not get(db, 'user:'+target) or target == uid:
                fail('Jogador inválido.')
            key = 'friend:'+':'.join(sorted([uid, target]))
            edge = get(db, key)
            action = b.get('action')
            if action == 'request' and not edge:
                put(db, key, 'friend', dict(a=uid, b=target, status='pending'))
            elif action == 'accept' and edge and edge['b'] == uid:
                edge['status'] = 'accepted'
                put(db, key, 'friend', edge)
            elif action == 'remove' and edge:
                from .database import Record
                db.delete(db.get(Record, key))
            else:
                fail('Pedido inválido ou já enviado.')
        edges = [e for e in all_of(db, 'friend') if uid in [e['a'], e['b']]]
        query = str(b.get('search', '')).lower().strip()
        return dict(friends=[public(get(db, 'user:'+(e['b'] if e['a']==uid else e['a']))) for e in edges if e['status']=='accepted'],
                    requests=[public(get(db, 'user:'+e['a'])) for e in edges if e['status']=='pending' and e['b']==uid],
                    results=[public(p) for p in all_of(db, 'user') if query and (query in p['name'].lower() or query == p['id']) and p['id'] != uid][:20],
                    invites=[i for i in all_of(db, 'invite') if i['to']==uid and i['expires']>time.time()])
    if path == 'invite':
        r = get(db, 'room:'+str(b.get('code', '')))
        if not r or uid not in r['players'] or b.get('id') not in friend_ids(db, uid):
            fail('Escolha um amigo e uma sala sua.')
        i = dict(id=secrets.token_hex(8), to=b['id'], code=r['code'], sender=u['name'], expires=time.time()+300)
        put(db, 'invite:'+i['id'], 'invite', i)
        return dict(ok=True)
    if path == 'rooms/create' or path == 'rooms/quick':
        if any(uid in t['players'] and t['status'] in ['waiting','playing'] for t in all_of(db,'tournament')):
            fail('Você está inscrito em um torneio. Acompanhe a chave.')
        if u['chips'] < b.get('fee',100):
            fail('Saldo insuficiente.')
        r = active_room(db, uid)
        if r:
            return room_view(db, r, uid)
        if path.endswith('quick'):
            r = next((x for x in all_of(db,'room') if x['quick'] and x['status']=='waiting' and x['capacity']==b.get('capacity',2) and x['fee']==b.get('fee',100) and x['rule']==b.get('rule','paulista') and len(x['players'])<x['capacity']), None)
            if r:
                r['players'].append(uid)
                if len(r['players']) == r['capacity']:
                    start_room(db, r)
                put(db, 'room:'+r['code'], 'room', r)
                return room_view(db, r, uid)
        return room_view(db, create_room(db, u, b, path.endswith('quick')), uid)
    if path.startswith('rooms/'):
        r = get(db, 'room:'+str(b.get('code','')).upper())
        if not r:
            fail('Sala não encontrada. Confira o código.', 404)
        action = path.split('/')[-1]
        if action not in ['join','start','leave','action','state','emote']:
            fail('Rota não encontrada.',404)
        if action == 'join' and uid not in r['players']:
            if any(uid in t['players'] and t['status'] in ['waiting','playing'] for t in all_of(db,'tournament')):
                fail('Cancele sua inscrição ou conclua seu torneio primeiro.')
            if active_room(db, uid):
                fail('Saia da sua sala atual primeiro.')
            if r['status'] != 'waiting' or len(r['players']) >= r['capacity']:
                fail('Sala cheia ou partida em andamento.')
            if r['password'] and not verify(str(b.get('password',''))[:128], r['password']):
                fail('Senha da sala incorreta.')
            if u['chips'] < r['fee']:
                fail('Saldo insuficiente.')
            r['players'].append(uid)
        elif uid not in r['players']:
            fail('Você não participa desta sala.', 403)
        if action == 'start':
            if uid != r['host']:
                fail('Somente o anfitrião pode iniciar.', 403)
            start_room(db, r)
        elif action == 'leave':
            if r['status'] == 'playing':
                r['game']['winner'] = 1-r['players'].index(uid)%2
                settle(db, r)
            else:
                r['players'].remove(uid)
                r['host'] = r['players'][0] if r['players'] else None
                if not r['players']:
                    r['status'] = 'closed'
        elif action == 'action':
            if r['status'] != 'playing':
                fail('Partida ainda não iniciada.')
            if b.get('version') != r['game']['version']:
                fail('Estado atualizado. Tente novamente.', 409)
            try:
                truco.act(r['game'], uid, b.get('action'), b.get('card'), b.get('value'))
            except ValueError as e:
                fail(str(e))
            settle(db, r)
        elif action=='emote':
            if 'emote' not in u['equipped']:
                fail('Escolha um emote na loja.')
            if time.time()-r.get('emote_at',0)<3:
                fail('Aguarde para enviar outro emote.')
            item=next(x for x in CATALOG if x['id']==u['equipped']['emote'])
            r['emote']=dict(name=u['name'],text=item['name'])
            r['emote_at']=time.time()
        if action not in ['state','emote']:
            r['updated'] = time.time()
        put(db, 'room:'+r['code'], 'room', r)
        return room_view(db, r, uid)
    if path == 'tournaments':
        if method == 'POST':
            tid = str(b.get('id', ''))
            t = get(db, 'tournament:'+tid)
            if not t:
                fail('Torneio não encontrado.')
            if active_room(db,uid) or any(uid in x['players'] and x['status'] in ['waiting','playing'] and x['id'] != tid for x in all_of(db,'tournament')):
                fail('Conclua sua sala ou torneio atual.')
            if t['status'] != 'waiting':
                fail('Inscrições encerradas.')
            if b.get('action')=='leave' and uid in t['players']:
                t['players'].remove(uid)
            elif uid not in t['players']:
                t['players'].append(uid)
            if len(t['players']) == t['size']:
                secrets.SystemRandom().shuffle(t['players'])
                tournament_round(db,t,t['players'])
            put(db, 'tournament:'+tid,'tournament',t)
        ts = all_of(db,'tournament')
        for size in [8,16,32]:
            if not any(t['size']==size and t['status']=='waiting' for t in ts):
                tid=secrets.token_hex(5)
                t=dict(id=tid,size=size,players=[],rounds=[],status='waiting',winner=None)
                put(db,'tournament:'+tid,'tournament',t)
                ts.append(t)
        return dict(tournaments=ts[-30:], names={p['id']:p['name'] for p in all_of(db,'user')})
    fail('Rota não encontrada.',404)


def friend_ids(db, uid):
    return [e['b'] if e['a']==uid else e['a'] for e in all_of(db,'friend') if uid in [e['a'],e['b']] and e['status']=='accepted']


async def broadcast():
    for uid, sockets in list(peers.items()):
        with Session() as db:
            u = get(db,'user:'+uid)
            data = dashboard(db,u)
        for ws in list(sockets):
            try:
                await asyncio.wait_for(ws.send_json(dict(type='state',data=data)), timeout=2)
            except Exception:
                sockets.discard(ws)
        if not sockets:
            peers.pop(uid,None)


@app.websocket('/ws')
async def websocket(ws: WebSocket):
    await ws.accept()
    uid = None
    try:
        first = await asyncio.wait_for(ws.receive_json(), timeout=10)
        with Session() as db:
            u = user(db,str(first.get('token','')))
            uid = u['id']
        peers.setdefault(uid,set()).add(ws)
        await broadcast()
        while True:
            await ws.receive_text()
            # Keepalives also renew the authenticated session check.
            with Session() as db:
                user(db,str(first.get('token','')))
            await ws.send_json(dict(type='pong'))
    except (WebSocketDisconnect, asyncio.TimeoutError, HTTPException, ValueError):
        pass
    finally:
        if uid in peers:
            peers[uid].discard(ws)
            if not peers[uid]:
                peers.pop(uid,None)
        try:
            await ws.close()
        except RuntimeError:
            pass
