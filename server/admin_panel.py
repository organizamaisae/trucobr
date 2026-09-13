"""Owner-only browser administration. All mutations share the game's write lock."""
import os
import secrets
import time
import asyncio
from pathlib import Path
from fastapi import Request
from starlette.responses import HTMLResponse
from .database import Session, get, put, all_of, delete, user_page
from .security import digest


def install_admin(app):
    from . import api as a
    attempts = {}

    def integer(body, key, minimum, maximum):
        value = body.get(key)
        if type(value) is not int or not minimum <= value <= maximum:
            a.fail(f'{key}: informe um inteiro entre {minimum} e {maximum}.')
        return value

    def authorize(db, token):
        record = get(db, 'admin_session:'+digest(str(token or '')))
        if not record or record['expires'] <= time.time():
            a.fail('Sessão expirada. Entre novamente.', 401)

    @app.get('/admgameconfig', response_class=HTMLResponse)
    def page():
        return HTMLResponse(Path(__file__).with_name('admin.html').read_text(encoding='utf-8'),
                            headers={'Cache-Control': 'no-store', 'X-Frame-Options': 'DENY'})

    @app.post('/admgameconfig')
    async def login(request: Request):
        body = await request.json()
        ip = request.client.host
        stamps = [x for x in attempts.get(ip, []) if x > time.time()-60]
        if len(stamps) >= 5:
            a.fail('Aguarde um minuto antes de tentar novamente.', 429)
        attempts[ip] = stamps + [time.time()]
        if not (secrets.compare_digest(str(body.get('email','')).strip().lower(), a.ADMIN_EMAIL)
                and secrets.compare_digest(str(body.get('password','')), os.getenv('ADMIN_PANEL_PASSWORD','1234'))):
            a.fail('E-mail ou senha incorretos.', 401)
        token = secrets.token_urlsafe(32)
        def save():
            with Session.begin() as db:
                put(db, 'admin_session:'+digest(token), 'admin_session', {'expires':time.time()+3600})
        async with a.lock:
            await asyncio.to_thread(save)
        return {'token':token, 'ok':True}

    @app.post('/admgameconfig/action')
    async def action(request: Request):
        body = await request.json()
        op = body.get('action')
        def execute():
            with Session.begin() as db:
                authorize(db, body.get('admin_token'))
                if op == 'logout':
                    delete(db, 'admin_session:'+digest(body['admin_token']))
                    return {'ok':True}
                if op == 'overview':
                    query = str(body.get('query','')).lower()[:100]
                    offset = integer(body, 'offset', 0, 100000) if 'offset' in body else 0
                    users, total = user_page(db, query, offset)
                    return dict(users=[dict(id=u['id'],name=u['name'],email=u.get('email'),chips=u['chips'],bot=u.get('bot',False))
                                       for u in users], total=total,
                                items=a.catalog(db), tournaments=[dict(id=t['id'],name=t['name'],status=t['status'],
                                size=t['size'],count=len(t['players']),mode=t.get('mode','1v1')) for t in all_of(db,'tournament')][-50:],
                                audit=all_of(db,'admin_audit')[-30:])
                if op == 'add_item':
                    kind = body.get('kind')
                    name = str(body.get('name','')).strip()
                    price = integer(body,'price',0,1000000)
                    if kind not in {'avatar','frame','back','table','emote','effect'} or not 2 <= len(name) <= 60:
                        a.fail('Confira nome e categoria do item.')
                    template = next((x for x in a.catalog(db) if x['id']==body.get('template') and x['kind']==kind), None)
                    if not template:
                        a.fail('Selecione um visual existente da mesma categoria.')
                    item = dict(id='custom-'+secrets.token_hex(6),kind=kind,name=name,price=price,icon=kind,
                                visual_id=template.get('visual_id',template['id']))
                    put(db,'shop_item:'+item['id'],'shop_item',item)
                    result = dict(ok=True,item=item)
                elif op == 'grant_chips':
                    target = str(body.get('user_id','')).strip().lower()
                    index = get(db,'email:'+target) if '@' in target else None
                    u = get(db,'user:'+(index['id'] if index else target))
                    if not u: a.fail('Jogador não encontrado.',404)
                    amount = integer(body,'amount',-1000000,1000000)
                    reason = str(body.get('reason','')).strip()[:120]
                    if not reason or amount==0: a.fail('Informe quantidade e motivo.')
                    a.ledger(u,amount,'Administração: '+reason)
                    a.save_user(db,u)
                    result = dict(ok=True,chips=u['chips'])
                elif op == 'announce':
                    text = str(body.get('text','')).strip()[:240]
                    if not text: a.fail('Informe um aviso.')
                    put(db,'config:announcement','config',dict(text=text,date=a.now().isoformat()))
                    result = dict(ok=True,announcement=text)
                elif op == 'add_bots':
                    count = integer(body,'count',1,32)
                    t = get(db,'tournament:'+str(body.get('tournament_id','')))
                    if not t or t['status']!='waiting': a.fail('Escolha um torneio com inscrições abertas.')
                    if len(t['players'])+count > t['size']: a.fail('Quantidade maior que as vagas livres.')
                    bots=[]
                    for _ in range(count):
                        uid='bot-'+secrets.token_hex(8)
                        u=dict(id=uid,name='Robô '+str(len(t['players'])+1),email=None,password=None,bot=True,
                            chips=0,earned=0,spent=0,xp=0,wins=0,losses=0,streak=0,best=0,history=[],ledger=[],daily='',
                            claims=[],inventory=[],equipped={})
                        a.save_user(db,u)
                        bots.append(uid)
                        t['players'].append(uid)
                        if t.get('mode')=='2v2':
                            pair=next((x for x in t.setdefault('teams',[]) if len(x['members'])==1),None)
                            if pair: pair['members'].append(uid)
                            else: t['teams'].append(dict(code=secrets.token_hex(4).upper(),members=[uid]))
                    put(db,'tournament:'+t['id'],'tournament',t)
                    result=dict(ok=True,bots=bots)
                else:
                    a.fail('Operação desconhecida.')
                event=dict(id=secrets.token_hex(8),date=a.now().isoformat(),action=op,actor=a.ADMIN_EMAIL,
                           details={k:v for k,v in body.items() if k not in {'admin_token','password'}})
                put(db,'admin_audit:'+event['id'],'admin_audit',event)
                return result
        async with a.lock:
            result = await asyncio.to_thread(execute)
        if op not in {'overview','logout'}:
            await a.broadcast()
        return result
