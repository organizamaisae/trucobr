from datetime import datetime, timezone, timedelta
from server.test_truco import client, account, post
from server.test_scheduled_tournaments import admin
from server.database import Session, get, put
from server.api import begin_tournament

def test_multiple_entries_and_private_spectator_state(client):
    ha=admin(client)
    a,ah=account(client,'PlayerOne')
    b,bh=account(client,'PlayerTwo')
    _,sh=account(client,'Observer')
    events=[]
    for name in ['First event','Second event']:
        t=post(client,ha,'tournaments/create',name=name,size=8,
               starts_at=(datetime.now(timezone.utc)+timedelta(hours=2)).isoformat())['created']
        post(client,ah,'tournaments',id=t['id'])
        events.append(t)
    post(client,bh,'tournaments',id=events[0]['id'])
    with Session.begin() as db:
        t=get(db,'tournament:'+events[0]['id'])
        begin_tournament(db,t)
        code=t['rounds'][0][0]['room']
    state=post(client,sh,'rooms/spectate',code=code)
    assert state['spectator']
    assert state['game']['hand']==[]
    assert 'hands' not in state['game'] and 'partner_hand' not in state['game']
    assert state['game']['counts']==[3,3]
    assert client.post('/api/rooms/action',headers=sh,json=dict(code=code,action='run',version=0)).status_code==403
    casual=post(client,sh,'rooms/create',fee=0)
    assert client.post('/api/rooms/spectate',headers=ah,json=dict(code=casual['code'])).status_code==400

def test_pass_authoritative_rewards_and_month_reset(client):
    a,h=account(client,'PassPlayer')
    assert client.post('/api/pass',headers=h,json=dict(action='claim',level=1)).status_code==400
    state=post(client,h,'pass',action='buy')
    assert state['chips']==7250
    assert client.post('/api/pass',headers=h,json=dict(action='buy')).status_code==400
    assert client.post('/api/pass',headers=h,json=dict(action='claim',level=1,xp=9999)).status_code==400
    with Session.begin() as db:
        u=get(db,'user:'+a['profile']['id'])
        u['history'].append(dict(date=datetime.now(timezone.utc).isoformat(),xp=600,won=True))
        put(db,'user:'+u['id'],'user',u)
    state=post(client,h,'pass',action='claim',level=3)
    assert state['chips']==7550 and 'back-4' in state['inventory']
    assert client.post('/api/pass',headers=h,json=dict(action='claim',level=3)).status_code==400
    with Session.begin() as db:
        u=get(db,'user:'+a['profile']['id'])
        u['monthly_pass']='2000-01'
        u['history'][0]['date']='2000-01-01T00:00:00+00:00'
        put(db,'user:'+u['id'],'user',u)
    state=client.get('/api/me',headers=h).json()['monthly_pass']
    assert not state['active'] and state['xp']==0
