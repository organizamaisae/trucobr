from datetime import datetime, timedelta, timezone
from server.test_truco import client, account, post
from server.test_scheduled_tournaments import admin
from server.api import start_due_tournaments
from server.database import Session, get


def test_two_of_eight_start_on_time_and_casual_refund(client):
    ha=admin(client)
    date=datetime.now(timezone.utc)+timedelta(hours=1)
    t=post(client,ha,'tournaments/create',name='Final dos amigos',size=8,mode='1v1',starts_at=date.isoformat(),table='table-4',table_text='Mesa do Gustavo',prize=6000)['created']
    a,ah=account(client,'Alice');b,bh=account(client,'Bob');c,ch=account(client,'Carol')
    for h in [ah,bh]: post(client,h,'tournaments',id=t['id'])
    # An enrolled player can play a casual room before the deadline.
    casual=post(client,ah,'rooms/quick',capacity=2,fee=100)
    post(client,ch,'rooms/quick',capacity=2,fee=100)
    assert client.get('/api/me',headers=ah).json()['chips']==10150
    with Session.begin() as db:
        assert not start_due_tournaments(db,date.timestamp()-1)
        assert start_due_tournaments(db,date.timestamp()+1)
        event=get(db,'tournament:'+t['id'])
        assert event['actual_players']==2
        assert len(event['rounds'])==1 and len(event['rounds'][0])==1
        game_room=get(db,'room:'+event['rounds'][0][0]['room'])
        assert game_room['table']=='table-4' and game_room['table_text']=='Mesa do Gustavo'
        assert get(db,'room:'+casual['code'])['status']=='closed'
    for h in [ah,ch]:
        d=client.get('/api/me',headers=h).json()
        assert d['chips']==10250 and d['profile']['wins']==0 and d['profile']['losses']==0
    post(client,bh,'rooms/leave',code=game_room['code'])
    winner=client.get('/api/me',headers=ah).json()
    assert winner['profile']['trophies'][0]['chips']==6000
    assert winner['chips']==10250+100+6000


def test_duo_codes_private_fixed_pairs_and_custom_prize(client):
    ha=admin(client)
    date=datetime.now(timezone.utc)+timedelta(hours=1)
    t=post(client,ha,'tournaments/create',name='Duplas por código',size=8,mode='2v2',starts_at=date.isoformat(),prize=2000)['created']
    users=[account(client,'Pair'+str(i)) for i in range(5)]
    first=post(client,users[0][1],'tournaments',id=t['id'],team_action='create')['tournaments'][0]
    code=first['team_code']
    assert all('code' not in pair for pair in first['teams'])
    outsider=client.get('/api/tournaments',headers=users[1][1]).json()['tournaments'][0]
    assert outsider['team_code'] is None and code not in str(outsider)
    assert client.post('/api/tournaments',headers=users[1][1],json=dict(id=t['id'],team_action='join',team_code='WRONG')).status_code==400
    post(client,users[3][1],'tournaments',id=t['id'],team_action='join',team_code=code)
    assert client.post('/api/tournaments',headers=users[1][1],json=dict(id=t['id'],team_action='join',team_code=code)).status_code==400
    second=post(client,users[1][1],'tournaments',id=t['id'],team_action='create')['tournaments'][0]
    post(client,users[2][1],'tournaments',id=t['id'],team_action='join',team_code=second['team_code'])
    post(client,users[4][1],'tournaments',id=t['id'],team_action='create')
    with Session.begin() as db:
        start_due_tournaments(db,date.timestamp()+1)
        event=get(db,'tournament:'+t['id'])
        assert event['actual_players']==4
        assert event['unpaired']==[users[4][0]['profile']['id']]
        match=event['rounds'][0][0]
        teams=match['teams']
        assert [users[0][0]['profile']['id'],users[3][0]['profile']['id']] in teams
    headers={a['profile']['id']:h for a,h in users}
    post(client,headers[teams[1][0]],'rooms/leave',code=match['room'])
    for uid in teams[0]:
        assert client.get('/api/me',headers=headers[uid]).json()['profile']['trophies'][0]['chips']==1000
    # Incomplete entrants are free to play another room.
    assert post(client,users[4][1],'rooms/create',capacity=2)['status']=='waiting'


def test_create_broadcast_and_catalog_purchase(client):
    ha=admin(client)
    a,ah=account(client,'Alice')
    with client.websocket_connect('/ws') as ws:
        ws.send_json({'token':a['token']});ws.receive_json()
        created=post(client,ha,'tournaments/create',name='Novo evento',size=8,starts_at=(datetime.now(timezone.utc)+timedelta(hours=1)).isoformat())['created']
        assert ws.receive_json()['data']['tournaments'][0]['id']==created['id']
    items=client.get('/api/shop',headers=ah).json()['items']
    assert len([i for i in items if i['kind']=='avatar'])==9
    post(client,ah,'shop',id='avatar-8')
    post(client,ah,'shop',id='avatar-8',equip=True)
    assert client.get('/api/me',headers=ah).json()['profile']['equipped']['avatar']=='avatar-8'
    assert client.post('/api/tournaments/create',headers=ha,json=dict(name='Invalid',size=8,prize=-1)).status_code==400
    assert client.post('/api/tournaments/create',headers=ha,json=dict(name='Invalid',size=8,mode='2v2',prize=3)).status_code==400
