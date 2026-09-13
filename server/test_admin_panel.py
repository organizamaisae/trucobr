from datetime import datetime, timedelta, timezone
from server.test_truco import client, account, post
from server.test_scheduled_tournaments import admin
from server.database import Session, get
from server import api


def owner(c):
    return c.post('/admgameconfig',json={'email':api.ADMIN_EMAIL,'password':'1234'}).json()['token']


def action(c, token, **body):
    return c.post('/admgameconfig/action',json=dict(admin_token=token,**body))


def test_panel_authorization_validation_and_persistence(client):
    assert 'id="login"' in client.get('/admgameconfig').text
    assert action(client,'bad',action='overview').status_code == 401
    token=owner(client)
    a,h=account(client,'Alice')
    uid=a['profile']['id']
    assert action(client,token,action='grant_chips',user_id=uid,amount='oops',reason='Test').status_code==400
    assert action(client,token,action='grant_chips',user_id=uid,amount=-999999,reason='Test').status_code==400
    assert action(client,token,action='grant_chips',user_id=uid,amount=200,reason='Test').status_code==200
    assert client.get('/api/me',headers=h).json()['chips']==10450
    r=action(client,token,action='add_item',name='Novo avatar',kind='avatar',price=100,template='avatar-3')
    assert r.status_code==200,r.text
    item=r.json()['item']
    post(client,h,'shop',id=item['id'])
    post(client,h,'shop',id=item['id'],equip=True)
    profile=client.get('/api/me',headers=h).json()['profile']
    assert profile['visuals']['avatar']=='avatar-3'
    assert profile['equipped']['avatar']==item['id']
    assert len(action(client,token,action='overview').json()['audit'])==2
    action(client,token,action='logout')
    assert action(client,token,action='overview').status_code==401


def test_bots_complete_tournament_through_normal_engine(client):
    h=admin(client)
    token=owner(client)
    t=post(client,h,'tournaments/create',name='Robots',size=8,starts_at=(datetime.now(timezone.utc)+timedelta(hours=1)).isoformat())['created']
    assert action(client,'bad',action='add_bots',tournament_id=t['id'],count=2).status_code==401
    assert action(client,token,action='add_bots',tournament_id=t['id'],count=9).status_code==400
    assert action(client,token,action='add_bots',tournament_id=t['id'],count=2).status_code==200
    with Session.begin() as db:
        event=get(db,'tournament:'+t['id'])
        api.begin_tournament(db,event)
        for _ in range(1200):
            api.step_bots(db)
            event=get(db,'tournament:'+t['id'])
            if event['status']=='finished': break
        assert event['status']=='finished'
        champion=get(db,'user:'+event['champions'][0])
        assert champion['bot'] and champion['trophies'][0]['id']==t['id']
        assert api.active_room(db,champion['id']) is None


def test_bot_completes_existing_pair(client):
    h=admin(client);token=owner(client)
    t=post(client,h,'tournaments/create',name='Duplas',size=4,mode='2v2')['created']
    post(client,h,'tournaments',id=t['id'],team_action='create')
    assert action(client,token,action='add_bots',tournament_id=t['id'],count=3).status_code==200
    with Session() as db:
        event=get(db,'tournament:'+t['id'])
        assert [len(pair['members']) for pair in event['teams']]==[2,2]
