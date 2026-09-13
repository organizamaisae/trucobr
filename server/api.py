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
from .database import Session, get, put, all_of, delete, delete_sessions, initialize
from . import engine as truco
from .security import password_hash, verify, digest, session

lock = asyncio.Lock()
peers = {}
rates = {}
ADMIN_EMAIL='gustavoluzmachado@gmail.com'


def can_create(u):
    return (u.get('email') or '').strip().lower()==ADMIN_EMAIL and u.get('tournament_admin') is True

def valid_admin_code(code):
    expected=os.getenv('ADMIN_SETUP_CODE','')
    return bool(expected) and isinstance(code,str) and secrets.compare_digest(code,expected)
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
CATALOG += [dict(id=f'avatar-{i+3}', kind='avatar', name=name, price=750+i*150, icon='person')
            for i,name in enumerate(['Rafa do Bar','Juliana','Seu Chico','Bia','Carlos','Marina'])]
CATALOG += [dict(id=f'{kind}-{i+2}',kind=kind,name=name,price=price+i*200,icon=kind)
            for kind,names,price in [('table',['Boteco Clássico','Bar da Praia','Madeira Imperial'],1200),
              ('frame',['Cobre','Azul Neon','Rosa Neon'],800),('back',['Brasil','Azulejo','Imperial'],800),
              ('effect',['Aura Dourada','Faíscas Verdes'],1000)] for i,name in enumerate(names)]
CATALOG += [dict(id=f'emote-{i+2}',kind='emote',name=name,price=250+i*100,icon='face')
            for i,name in enumerate(['É truco!','Boa dupla!','Respeita a mesa!','Até a próxima!'])]
CATALOG += [dict(id='table-5',kind='table',name='Quiosque da Praia',price=1800,icon='table'),
            dict(id='table-6',kind='table',name='Taverna da Serra',price=2200,icon='table')]
CATALOG += [dict(id=f'table-{i+7}',kind='table',name=name,price=price,icon='table')
            for i,(name,price) in enumerate([('Varanda da Roça',2400),('Boteco dos Azulejos',2600),('Refúgio Amazônico',2800)])]
CATALOG += [dict(id=f'avatar-{i+9}',kind='avatar',name=name,price=price,icon='person')
            for i,(name,price) in enumerate([('Dona Rosa',1500),('Zé da Roça',1600),('Ará',1700),('Diego',1800)])]
CATALOG = [x for x in CATALOG if x['kind']!='pass']
TABLES = ['table-0','table-1','table-2','table-3','table-4','table-5','table-6','table-7','table-8','table-9']

def monthly_pass(u):
    month=now().strftime('%Y-%m')
    xp=sum(h.get('xp',0) for h in u['history'] if h['date'].startswith(month))
    purchased=u.get('monthly_pass')==month
    claims=u.get('pass_claims',[])
    return dict(month=month,xp=xp,active=purchased,price=3000,levels=[
        dict(level=i,target=i*200,chips=i*100,
             item={3:'back-4',6:'frame-3',10:'table-6'}.get(i),
             claimed=f'{month}:{i}' in claims) for i in range(1,11)])



def tournament_view(t, uid):
    result = {k:v for k,v in t.items() if k!='teams'}
    if 'teams' in t:
        result['teams'] = [dict(members=x['members']) for x in t['teams']]
        result['team_code'] = next((x['code'] for x in t['teams'] if uid in x['members']),None)
    return result


def in_live_tournament(db, uid):
    return any(t['status']=='playing' and uid in t['players'] and uid not in t.get('unpaired',[]) for t in all_of(db,'tournament'))


def fail(message, status=400):
    raise HTTPException(status, message)


def now():
    return datetime.now(timezone.utc)


def public(u):
    wins, losses = u['wins'], u['losses']
    return {**{k: u[k] for k in ['id', 'name', 'xp', 'wins', 'losses', 'streak', 'best', 'equipped']},
            'level': 1+u['xp']//1000, 'games': wins+losses,
            'win_rate': round(wins*100/max(1, wins+losses)), 'online': u['id'] in peers,
            'trophies': u.get('trophies', [])}


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
             quick=quick, settled=False, tournament=tournament, updated=time.time(),
             table=u['equipped'].get('table','table-2'), table_text='TRUCO BR')
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
                team = r['players'][g['winner']::2]
                match['scores'] = g['scores'][:]
                match['winner'] = team if t.get('mode') == '2v2' else team[0]
        if all(m['winner'] for m in t['rounds'][-1]):
            winners = [m['winner'] for m in t['rounds'][-1]]
            if len(winners) == 1:
                finish_tournament(db, t, winners[0])
            else:
                tournament_round(db, t, winners)
        put(db, 'tournament:'+t['id'], 'tournament', t)


def tournament_round(db, t, entrants):
    """Pad the opening round to a power of two; byes never invent players."""
    matches = []
    entrants = list(entrants)
    target = 1 << (len(entrants)-1).bit_length()
    byes = target-len(entrants)
    for entrant in entrants[:byes]:
        matches.append(dict(room=None, players=team_members(entrant), winner=entrant, bye=True))
    entrants = entrants[byes:]
    for i in range(0, len(entrants), 2):
        a, b = map(team_members, entrants[i:i+2])
        players = [p for pair in zip(a, b) for p in pair]
        r = create_room(db, get(db, 'user:'+players[0]), dict(capacity=len(players), fee=0, rule=t.get('rule','paulista')), tournament=t['id'])
        r['players'] = players
        r['table'] = t.get('table','table-2')
        r['table_text'] = t.get('table_text','TRUCO BR')
        start_room(db, r)
        matches.append(dict(room=r['code'], players=players, teams=[a,b], winner=None))
    t['rounds'].append(matches)
    t['status'] = 'playing'


def team_members(entrant):
    return entrant if isinstance(entrant, list) else [entrant]


def finish_tournament(db, t, winner):
    if t['status'] == 'finished':
        return
    champions = team_members(winner)
    date = now().isoformat()
    t.update(status='finished', winner=winner, champions=champions, finished_at=date)
    prize = t.get('prize', t['size']*250)
    for uid in champions:
        u = get(db, 'user:'+uid)
        ledger(u, prize//len(champions), 'Campeão: '+t['name'])
        u['xp'] += 1000
        u.setdefault('trophies', []).append(dict(id=t['id'], name=t['name'], mode=t.get('mode','1v1'),
            date=date, chips=prize//len(champions), xp=1000, champions=champions))
        save_user(db, u)


def begin_tournament(db, t):
    players = list(t['players'])
    if any(r.get('tournament') and r['tournament'] != t['id'] and r['status']=='playing'
           and set(players).intersection(r['players']) for r in all_of(db,'room')):
        t['reason']='Aguardando inscritos concluírem a partida de outro torneio.'
        put(db,'tournament:'+t['id'],'tournament',t)
        return
    team_size = 2 if t.get('mode') == '2v2' else 1
    if team_size==2 and 'teams' in t:
        entrants=[x['members'][:] for x in t['teams'] if len(x['members'])==2]
        complete=[p for pair in entrants for p in pair]
        t['unpaired']=[p for p in players if p not in complete]
        players=complete
        if len(players) < 4:
            t.update(status='cancelled', reason='Duplas completas insuficientes no horário de início.')
            refund_tournament_entries(db,t,t['players'])
            put(db,'tournament:'+t['id'],'tournament',t)
            return
    if len(players) < team_size*2:
        t.update(status='cancelled', reason='Inscritos insuficientes no horário de início.')
    else:
        # Pairs are formed in registration order and remain together throughout.
        if 'teams' not in t or team_size==1:
            t['unpaired'] = players[-1:] if team_size == 2 and len(players)%2 else []
            if t['unpaired']:
                players = players[:-1]
            entrants = [players[i:i+2] for i in range(0,len(players),2)] if team_size == 2 else players
        # End casual rooms atomically before seating their players in the event.
        for r in all_of(db,'room'):
            if not r.get('tournament') and r['status'] in ['waiting','playing'] and set(players).intersection(r['players']):
                if r['status']=='playing':
                    for p in r['players']:
                        account=get(db,'user:'+p)
                        ledger(account,r['fee'],'Entrada devolvida: início de torneio')
                        save_user(db,account)
                r.update(status='closed',settled=True,close_reason='Sala encerrada para início de torneio. Entradas devolvidas.')
                put(db,'room:'+r['code'],'room',r)
        secrets.SystemRandom().shuffle(entrants)
        t.update(actual_players=len(players), prize=t.get('custom_prize',len(players)*250), started_at=now().isoformat())
        tournament_round(db,t,entrants)
    refund_tournament_entries(db,t,t['players'] if t['status']=='cancelled' else t.get('unpaired',[]))
    put(db,'tournament:'+t['id'],'tournament',t)


def refund_tournament_entries(db,t,players):
    for player_id in players:
        if player_id not in t.setdefault('refunded',[]) and t.get('entry_fee'):
            account=get(db,'user:'+player_id)
            ledger(account,t['entry_fee'],'Inscrição devolvida: '+t['name'])
            save_user(db,account)
            t['refunded'].append(player_id)


def start_due_tournaments(db, timestamp=None):
    timestamp = time.time() if timestamp is None else timestamp
    changed = False
    for t in all_of(db,'tournament'):
        if t['status']=='waiting' and t.get('starts_at') and datetime.fromisoformat(t['starts_at']).timestamp() <= timestamp:
            begin_tournament(db,t)
            changed = True
    return changed


def pending_invites(db, uid):
    result = []
    for i in all_of(db,'invite'):
        if i['to']==uid and i['expires']>time.time():
            r = get(db,'room:'+i['code'])
            if r and r['status']=='waiting' and len(r['players'])<r['capacity'] and uid not in r['players']:
                result.append(i)
    return result


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
        r = next((x for x in reversed(all_of(db, 'room')) if u['id'] in x['players'] and x['status'] in ['finished','closed']), None)
    return dict(profile=public(u), can_create_tournaments=can_create(u), admin_eligible=(u.get('email') or '').lower()==ADMIN_EMAIL, chips=u['chips'], earned=u['earned'], spent=u['spent'],
                monthly_pass=monthly_pass(u), ledger=list(reversed(u['ledger'][-100:])), history=list(reversed(u['history'][-100:])),
                daily_available=u['daily'] != d, inventory=u['inventory'], missions=missions,
                achievements=[dict(name=n, unlocked=u[k] >= v) for n, k, v in [('Primeira vitória', 'wins', 1), ('Dez vitórias', 'wins', 10), ('Invencível: 5 seguidas', 'best', 5), ('Nível 5', 'xp', 4000)]],
                invites=pending_invites(db,u['id']),
                tournaments=[tournament_view(t,u['id']) for t in all_of(db,'tournament') if t.get('created_by') or t['status']!='waiting' or t['players']],
                tournament_names={p['id']:p['name'] for p in all_of(db,'user')},
                room=room_view(db, r, u['id']) if r else None)


async def maintenance():
    while True:
        await asyncio.sleep(10)
        changed = False
        async with lock:
            with Session.begin() as db:
                changed = start_due_tournaments(db)
                for invitation in all_of(db,'invite'):
                    if invitation['expires']<=time.time():
                        delete(db,'invite:'+invitation['id'])
                        changed=True
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
    initialize()
    task=asyncio.create_task(maintenance())
    try:
        yield
    finally:
        task.cancel()
        with contextlib.suppress(asyncio.CancelledError):
            await task


app = FastAPI(title='Truco BR', version='3.0.0', lifespan=lifespan)
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
    return dict(status='ok', app='Truco BR', version=3)


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
                if action=='register' and email==ADMIN_EMAIL and not valid_admin_code(data.get('admin_code')):
                    fail('Informe o código de ativação do administrador.',403)
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
                if action=='register' and email==ADMIN_EMAIL:
                    u['tournament_admin']=True
                    save_user(db,u)
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
        delete_sessions(db,uid)
        return dict(ok=True)
    if path=='admin/activate':
        if (u.get('email') or '').lower()!=ADMIN_EMAIL or not valid_admin_code(b.get('admin_code')):
            fail('Ativação não autorizada.',403)
        u['tournament_admin']=True
        save_user(db,u)
        return dashboard(db,u)
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
    if path == 'pass':
        state=monthly_pass(u)
        if b.get('action')=='buy':
            if state['active']: fail('Passe deste mês já ativado.')
            ledger(u,-state['price'],'Passe mensal '+state['month'])
            u['monthly_pass']=state['month']
        elif b.get('action')=='claim':
            level=next((x for x in state['levels'] if x['level']==b.get('level')),None)
            if not state['active'] or not level or level['claimed'] or state['xp']<level['target']:
                fail('Recompensa indisponível.')
            ledger(u,level['chips'],'Passe mensal: nível '+str(level['level']))
            if level['item'] and level['item'] not in u['inventory']: u['inventory'].append(level['item'])
            u.setdefault('pass_claims',[]).append(f"{state['month']}:{level['level']}")
        else: fail('Ação inválida.')
        save_user(db,u)
        return dashboard(db,u)
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
                delete(db,key)
            else:
                fail('Pedido inválido ou já enviado.')
        edges = [e for e in all_of(db, 'friend') if uid in [e['a'], e['b']]]
        query = str(b.get('search', '')).lower().strip()
        return dict(friends=[public(get(db, 'user:'+(e['b'] if e['a']==uid else e['a']))) for e in edges if e['status']=='accepted'],
                    requests=[public(get(db, 'user:'+e['a'])) for e in edges if e['status']=='pending' and e['b']==uid],
                    results=[public(p) for p in all_of(db, 'user') if query and (query in p['name'].lower() or query == p['id']) and p['id'] != uid][:20],
                    invites=pending_invites(db,uid))
    if path == 'invite':
        r = get(db, 'room:'+str(b.get('code', '')))
        if not r or r['status']!='waiting' or len(r['players'])>=r['capacity'] or uid not in r['players'] or b.get('id') not in friend_ids(db, uid):
            fail('Escolha um amigo e uma sala sua.')
        i = dict(id=secrets.token_hex(8), to=b['id'], code=r['code'], sender=u['name'], expires=time.time()+300)
        put(db, 'invite:'+i['id'], 'invite', i)
        return dict(ok=True)
    if path == 'invite/respond':
        i = get(db,'invite:'+str(b.get('id','')))
        if not i or i['to']!=uid or i['expires']<=time.time():
            fail('Convite expirado ou indisponível.',404)
        if b.get('action')=='decline':
            delete(db,'invite:'+i['id'])
            return dict(ok=True)
        if b.get('action')!='accept':
            fail('Resposta inválida.')
        result = dispatch(db,u,'rooms/join',dict(code=i['code'],invite_id=i['id']),'POST')
        delete(db,'invite:'+i['id'])
        return result
    if path == 'rooms/create' or path == 'rooms/quick':
        if in_live_tournament(db,uid):
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
        if action == 'spectate':
            if not r.get('tournament') or r['status'] not in ['playing','finished']:
                fail('Esta partida não está disponível para espectadores.')
            result=room_view(db,r,uid)
            g=r.get('game')
            if not g: fail('Partida ainda não iniciada.')
            result['spectator']=True
            result['game']={k:v for k,v in g.items() if k not in ['hands','partner_hand']}
            result['game'].update(hand=[],seat=0,counts=[len(h) for h in g['hands']])
            return result
        if action not in ['join','start','leave','action','state','emote']:
            fail('Rota não encontrada.',404)
        if action == 'join' and uid not in r['players']:
            if in_live_tournament(db,uid):
                fail('Cancele sua inscrição ou conclua seu torneio primeiro.')
            if active_room(db, uid):
                fail('Saia da sua sala atual primeiro.')
            if r['status'] != 'waiting' or len(r['players']) >= r['capacity']:
                fail('Sala cheia ou partida em andamento.')
            invitation=get(db,'invite:'+str(b.get('invite_id','')))
            invited=invitation and invitation['to']==uid and invitation['code']==r['code'] and invitation['expires']>time.time()
            if r['password'] and not invited and not verify(str(b.get('password',''))[:128], r['password']):
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
    if path=='tournaments/create':
        if not can_create(u):
            fail('Somente o administrador pode criar torneios.',403)
        size=b.get('size',8)
        name=str(b.get('name','')).strip()
        mode=b.get('mode','1v1')
        rule=b.get('rule','paulista')
        if type(size) is not int or not 2<=size<=256 or mode not in ['1v1','2v2'] or rule not in ['paulista','fixa'] or not 3<=len(name)<=50 or (mode=='2v2' and (size<4 or size%2)):
            fail('Informe nome, modo e 2 a 256 vagas. Duplas exigem pelo menos 4 vagas e um número par.')
        starts_at=None
        if b.get('starts_at'):
            try:
                start=datetime.fromisoformat(b['starts_at'].replace('Z','+00:00'))
                if start.tzinfo is None or start.timestamp()<=time.time():
                    raise ValueError()
                starts_at=start.astimezone(timezone.utc).isoformat()
            except (ValueError,TypeError,AttributeError):
                fail('Escolha data e horário futuros com fuso horário.')
        tid=secrets.token_hex(5)
        table=b.get('table','table-2')
        table_text=str(b.get('table_text','TRUCO BR')).strip()
        entry_fee=b.get('entry_fee', 0)
        prize=b.get('prize',size*250)
        if table not in TABLES or len(table_text)>40 or type(entry_fee) is not int or entry_fee not in TIERS+[0] or type(prize) is not int or not 0<=prize<=1000000 or (mode=='2v2' and prize%2):
            fail('Confira a mesa, frase de até 40 caracteres e premiação de 0 a 1.000.000 (par em duplas).')
        t=dict(id=tid,name=name,size=size,mode=mode,rule=rule,starts_at=starts_at,table=table,table_text=table_text,entry_fee=entry_fee,custom_prize=prize,players=[],rounds=[],status='waiting',winner=None,created_by=uid,created_at=now().isoformat())
        if mode=='2v2': t['teams']=[]
        put(db,'tournament:'+tid,'tournament',t)
        return dict(**dispatch(db,u,'tournaments',{},'GET'), created=tournament_view(t,uid))
    if path == 'tournaments':
        start_due_tournaments(db)
        if method == 'POST':
            tid = str(b.get('id', ''))
            t = get(db, 'tournament:'+tid)
            if not t:
                fail('Torneio não encontrado.')
            if b.get('action') == 'delete':
                if not can_create(u) or t.get('created_by') != uid:
                    fail('Somente o criador administrador pode excluir este torneio.', 403)
                if t.get('status') == 'playing':
                    fail('Não é possível excluir um torneio em andamento.')
                if t['status']=='waiting' and t.get('entry_fee'):
                    for player_id in t['players']:
                        account=get(db,'user:'+player_id)
                        ledger(account,t['entry_fee'],'Torneio excluído: inscrição devolvida')
                        save_user(db,account)
                delete(db, 'tournament:'+tid)
                ts = [x for x in all_of(db,'tournament') if x.get('created_by') or x['status']!='waiting' or x['players']]
                return dict(tournaments=[tournament_view(x,uid) for x in ts[-30:]], names={p['id']:p['name'] for p in all_of(db,'user')})

            if t['status'] != 'waiting':
                fail('Inscrições encerradas.')
            if b.get('action')=='leave' and uid in t['players']:
                t['players'].remove(uid)
                fee=t.get('entry_fee', 0)
                if fee:
                    ledger(u, fee, 'Inscrição devolvida: '+t['name'])
                    save_user(db, u)
                for pair in t.get('teams',[]):
                    if uid in pair['members']: pair['members'].remove(uid)
                t['teams']=[x for x in t.get('teams',[]) if x['members']] if 'teams' in t else t.get('teams',[])
            elif b.get('action','join')=='join' and uid not in t['players'] and len(t['players'])<t['size']:
                fee=t.get('entry_fee', 0)
                if u['chips'] < fee:
                    fail('Saldo de fichas insuficiente para a inscrição.')
                if fee:
                    ledger(u, -fee, 'Inscrição no torneio '+t['name'])
                    save_user(db, u)
                if t.get('mode')=='2v2' and 'teams' in t:
                    if b.get('team_action')=='create':
                        if len(t['teams'])>=t['size']//2:
                            fail('Entre no código de uma dupla existente; todas as duplas já foram criadas.')
                        code=secrets.token_hex(4).upper()
                        while any(x['code']==code for x in t['teams']): code=secrets.token_hex(4).upper()
                        t['teams'].append(dict(code=code,members=[uid]))
                    elif b.get('team_action')=='join':
                        pair=next((x for x in t['teams'] if x['code']==str(b.get('team_code','')).strip().upper()),None)
                        if not pair or len(pair['members'])!=1: fail('Código inválido ou dupla completa.')
                        pair['members'].append(uid)
                    else: fail('Escolha Criar Código ou Entrar em Código.')
                t['players'].append(uid)
            else:
                fail('Inscrição inválida ou vagas esgotadas.')
            if len(t['players']) == t['size'] and not t.get('starts_at'):
                begin_tournament(db,t)
            put(db, 'tournament:'+tid,'tournament',t)
        ts = [t for t in all_of(db,'tournament') if t.get('created_by') or t['status']!='waiting' or t['players']]
        return dict(tournaments=[tournament_view(t,uid) for t in ts[-30:]], names={p['id']:p['name'] for p in all_of(db,'user')})
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
