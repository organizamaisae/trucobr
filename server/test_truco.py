import os
import tempfile
os.environ['DATABASE_URL'] = 'sqlite:///' + os.path.join(tempfile.mkdtemp(), 'test.db').replace('\\','/')
import pytest
from fastapi.testclient import TestClient
from server.api import app, rates
from server.database import Base, engine
from server import engine as game


@pytest.fixture
def client():
    Base.metadata.drop_all(engine)
    rates.clear()
    with TestClient(app) as c:
        yield c


def account(c, name):
    r=c.post('/auth/register',json=dict(name=name,email=name+'@test.com',password='StrongPassword123'))
    assert r.status_code==200, r.text
    d=r.json()
    return d, {'Authorization':'Bearer '+d['token']}


def post(c,h,path,**data):
    r=c.post('/api/'+path,headers=h,json=data)
    assert r.status_code==200,r.text
    return r.json()


def test_auth_wallet_and_cosmetics(client):
    d,h=account(client,'Alice')
    assert d['chips']==10250
    assert client.get('/api/me').status_code==401
    assert client.post('/auth/login',json={'email':'Alice@test.com','password':'bad'}).status_code==401
    assert post(client,h,'reward',id='daily')['chips']==10550
    assert client.post('/api/reward',headers=h,json={'id':'daily'}).status_code==400
    post(client,h,'shop',id='avatar-0')
    post(client,h,'shop',id='avatar-0')
    assert client.get('/api/me',headers=h).json()['chips']==10050
    post(client,h,'shop',id='avatar-0',equip=True)
    assert client.get('/api/me',headers=h).json()['profile']['equipped']['avatar']=='avatar-0'


def test_friends_and_private_password(client):
    a,ha=account(client,'Alice'); b,hb=account(client,'Bob')
    post(client,ha,'friends',id=b['profile']['id'],action='request')
    assert len(client.get('/api/friends',headers=hb).json()['requests'])==1
    post(client,hb,'friends',id=a['profile']['id'],action='accept')
    room=post(client,ha,'rooms/create',capacity=2,password='secret',fee=100)
    assert client.post('/api/rooms/join',headers=hb,json={'code':room['code'],'password':'wrong'}).status_code==400
    assert client.post('/api/rooms/start',headers=ha,json={'code':room['code']}).status_code==400
    post(client,ha,'invite',id=b['profile']['id'],code=room['code'])
    assert client.get('/api/friends',headers=hb).json()['invites']
    post(client,hb,'rooms/join',code=room['code'],password='secret')
    assert client.post('/api/rooms/start',headers=hb,json={'code':room['code']}).status_code==403
    started=post(client,ha,'rooms/start',code=room['code'])
    assert len(started['game']['hand'])==3
    assert 'hands' not in started['game']
    assert 'password' not in started


@pytest.mark.parametrize('capacity',[2,4])
def test_real_accounts_full_match_and_settlement(client,capacity):
    users=[account(client,'Player'+str(i)) for i in range(capacity)]
    for d,h in users:
        room=post(client,h,'rooms/quick',capacity=capacity,fee=100)
    assert room['status']=='playing'
    code=room['code']
    headers={d['profile']['id']:h for d,h in users}
    for _ in range(800):
        r=post(client,users[0][1],'rooms/state',code=code)
        g=r['game']
        if g['winner'] is not None:
            break
        if g['hand_done']:
            h=users[0][1]; action='next'
        elif g['pending']:
            h=users[g['pending']['team']][1];action='accept'
        else:
            h=headers[g['players'][g['turn']]];action='play'
        post(client,h,'rooms/action',code=code,version=g['version'],action=action,card=0)
    else:
        pytest.fail('Match never completed')
    balances=[]
    for d,h in users:
        current=client.get('/api/me',headers=h).json()
        assert current['profile']['games']==1
        assert len(current['history'])==1
        balances.append(current['chips'])
    assert sum(balances)==capacity*10250+capacity//2*100
    assert client.post('/api/rooms/action',headers=users[0][1],json={'code':code,'version':g['version'],'action':'next'}).status_code==400


def test_socket_private_views_and_stale_action(client):
    a,ha=account(client,'Alice');b,hb=account(client,'Bob')
    r=post(client,ha,'rooms/quick',capacity=2,fee=100)
    post(client,hb,'rooms/quick',capacity=2,fee=100)
    with client.websocket_connect('/ws') as wa:
        wa.send_json({'token':a['token']})
        sa=wa.receive_json()['data']['room']['game']
        assert 'hands' not in sa
        with client.websocket_connect('/ws') as wb:
            wb.send_json({'token':b['token']})
            sb=wb.receive_json()['data']['room']['game']
            assert sa['hand']!=sb['hand']
            assert client.post('/api/rooms/action',headers=ha,json={'code':r['code'],'version':-1,'action':'play','card':0}).status_code==409
            h=ha if sa['turn']==sa['seat'] else hb
            post(client,h,'rooms/action',code=r['code'],version=sa['version'],action='play',card=0)
            assert wb.receive_json()['data']['room']['game']['version']==1


def test_engine_raises_ties_and_eleven():
    g=game.new_game(['a','b'])
    who=g['players'][g['turn']]; other='b' if who=='a' else 'a'
    game.act(g,who,'raise',value=3)
    with pytest.raises(ValueError):game.act(g,who,'accept')
    game.act(g,other,'raise',value=6)
    game.act(g,who,'run')
    assert sum(g['scores'])==3
    assert game.hand_winner([None,1])==(True,1)
    assert game.hand_winner([0,1,None])==(True,0)
    assert game.hand_winner([None,None,None])==(True,None)
    assert game.strength('4♣','3♦','paulista')>game.strength('4♥','3♦','paulista')
    g['scores']=[11,0];game.deal(g)
    assert g['pending']['special']
    game.act(g,'a','accept')
    with pytest.raises(ValueError):game.act(g,g['players'][g['turn']],'raise',value=6)
    g['scores']=[11,11];game.deal(g)
    assert game.view(g,'a')['hand']==['?','?','?']


def test_tournament_starts_with_eight_real_players(client):
    users=[account(client,'User'+str(i)) for i in range(8)]
    ts=client.get('/api/tournaments',headers=users[0][1]).json()['tournaments']
    tid=next(t['id'] for t in ts if t['size']==8)
    for d,h in users:
        response=post(client,h,'tournaments',id=tid)
    t=next(t for t in response['tournaments'] if t['id']==tid)
    assert t['status']=='playing'
    assert len(t['rounds'][0])==4
    for d,h in users:
        assert client.get('/api/me',headers=h).json()['room']['status']=='playing'
    headers={d['profile']['id']:h for d,h in users}
    for round_no in range(3):
        t=next(x for x in client.get('/api/tournaments',headers=users[0][1]).json()['tournaments'] if x['id']==tid)
        assert len(t['rounds'][round_no])==4//(2**round_no)
        for match in t['rounds'][round_no]:
            post(client,headers[match['players'][1]],'rooms/leave',code=match['room'])
    t=next(x for x in client.get('/api/tournaments',headers=users[0][1]).json()['tournaments'] if x['id']==tid)
    assert t['status']=='finished'
    winner=client.get('/api/me',headers=headers[t['winner']]).json()
    assert winner['profile']['wins']==3
    assert winner['chips']==10250+300+2000


def test_invalid_payloads_and_private_game_actions(client):
    a,ha=account(client,'Alice');b,hb=account(client,'Bob')
    assert client.post('/api/rooms/create',headers=ha,json={'fee':'100'}).status_code==422
    assert client.get('/api/reward',headers=ha).status_code==405
    r=post(client,ha,'rooms/quick',capacity=2,fee=100)
    r=post(client,hb,'rooms/quick',capacity=2,fee=100)
    g=r['game']
    h=ha if g['turn']==1 else hb
    assert client.post('/api/rooms/action',headers=h,json={'code':r['code'],'version':0,'action':'play','card':0}).status_code==400
    outsider,hc=account(client,'Carol')
    assert client.post('/api/rooms/state',headers=hc,json={'code':r['code']}).status_code==403
    turn_header=ha if g['turn']==0 else hb
    assert client.post('/api/rooms/action',headers=turn_header,json={'code':r['code'],'version':0,'action':'play','card':15}).status_code==400
    assert client.get('/api/me',headers=ha).json()['chips']==10150
