from datetime import datetime, timezone, timedelta
from server.test_truco import client, account, post
from server.api import start_due_tournaments, settle
from server.database import Session, get, put
import pytest


def admin(c):
    d=c.post('/auth/register',json=dict(name='Gustavo',email='gustavoluzmachado@gmail.com',password='StrongPassword123',admin_code='test-admin-code-not-production')).json()
    return {'Authorization':'Bearer '+d['token']}


@pytest.mark.parametrize('mode,count,size', [('1v1',5,8),('1v1',3,3),('2v2',11,16)])
def test_scheduled_adaptive_bracket_and_persisted_champions(client,mode,count,size):
    ha=admin(client)
    start=datetime.now(timezone.utc)+timedelta(hours=1)
    t=post(client,ha,'tournaments/create',name='Copa marcada',size=size,mode=mode,starts_at=start.isoformat())['tournaments'][0]
    users=[account(client,'User'+str(i)) for i in range(count)]
    pair_code=None
    for index,(_,h) in enumerate(users):
        options={}
        if mode=='2v2': options=dict(team_action='create' if index%2==0 else 'join',team_code=pair_code)
        joined=post(client,h,'tournaments',id=t['id'],action='join',**options)
        pair_code=joined['tournaments'][0].get('team_code')
    with Session.begin() as db:
        assert not start_due_tournaments(db,start.timestamp()-1)
        assert start_due_tournaments(db,start.timestamp()+1)
        assert not start_due_tournaments(db,start.timestamp()+2)
    ids=[u['profile']['id'] for u,_ in users]
    while True:
        with Session.begin() as db:
            t=get(db,'tournament:'+t['id'])
            if t['status']=='finished': break
            matches=t['rounds'][-1]
            assert all(set(m['players']) <= set(ids) for m in matches)
            for m in matches:
                if m['winner']: continue
                r=get(db,'room:'+m['room'])
                assert len(r['players']) == (4 if mode=='2v2' else 2)
                if mode=='2v2':
                    assert r['players'][::2] == m['teams'][0]
                    assert r['players'][1::2] == m['teams'][1]
                r['game']['winner']=0
                settle(db,r)
                put(db,'room:'+r['code'],'room',r)
    champions=t['champions']
    assert len(champions)==(2 if mode=='2v2' else 1)
    if mode=='2v2': assert t['unpaired']==[ids[-1]]
    for u,h in users:
        p=client.get('/api/me',headers=h).json()['profile']
        assert len(p['trophies']) == (1 if p['id'] in champions else 0)
        if p['id'] in champions:
            assert p['trophies'][0]['chips']==t['prize']//len(champions)
            assert p['trophies'][0]['id']==t['id']
            # Repeat settlement must not duplicate rewards.
            with Session.begin() as db: settle(db,r)
            assert len(client.get('/api/me',headers=h).json()['profile']['trophies'])==1


def test_insufficient_players_cancel_and_invalid_schedule(client):
    ha=admin(client)
    for data in [dict(size=3,mode='2v2'),dict(size=4,starts_at='invalid'),dict(size=4,starts_at='2020-01-01T00:00:00Z'),dict(size=4,starts_at='2030-01-01T00:00:00')]:
        assert client.post('/api/tournaments/create',headers=ha,json=dict(name='Invalid',**data)).status_code==400
    date=datetime.now(timezone.utc)+timedelta(hours=1)
    t=post(client,ha,'tournaments/create',name='Duplas',size=4,mode='2v2',starts_at=date.isoformat())['tournaments'][0]
    pair_code=None
    for i in range(3):
        _,h=account(client,'Player'+str(i))
        response=post(client,h,'tournaments',id=t['id'],team_action='join' if i==1 else 'create',team_code=pair_code)
        pair_code=response['tournaments'][0].get('team_code')
    with Session.begin() as db:
        start_due_tournaments(db,date.timestamp()+1)
        t=get(db,'tournament:'+t['id'])
        assert t['status']=='cancelled' and t['rounds']==[]
    assert post(client,h,'rooms/create',capacity=2)['status']=='waiting'


def test_invites_delivered_globally_private_room_and_authorization(client):
    a,ha=account(client,'Alice');b,hb=account(client,'Bob');c,hc=account(client,'Carol')
    post(client,ha,'friends',id=b['profile']['id'],action='request')
    post(client,hb,'friends',id=a['profile']['id'],action='accept')
    r=post(client,ha,'rooms/create',capacity=2,password='private')
    with client.websocket_connect('/ws') as ws:
        ws.send_json({'token':b['token']})
        ws.receive_json()
        post(client,ha,'invite',id=b['profile']['id'],code=r['code'])
        i=ws.receive_json()['data']['invites'][0]
        assert i['sender']=='Alice'
        assert client.post('/api/invite/respond',headers=hc,json=dict(id=i['id'],action='accept')).status_code==404
        joined=post(client,hb,'invite/respond',id=i['id'],action='accept')
        assert b['profile']['id'] in joined['players']
        assert client.get('/api/me',headers=hb).json()['invites']==[]
        assert client.post('/api/invite/respond',headers=hb,json=dict(id=i['id'],action='accept')).status_code==404
