from server.test_truco import client, account, post


def test_tournaments_require_server_permission(client):
    u,h=account(client,'Normal')
    assert client.get('/api/tournaments',headers=h).json()['tournaments']==[]
    for _ in range(2):
        assert client.get('/api/tournaments',headers=h).json()['tournaments']==[]
    response=client.post('/api/tournaments/create',headers=h,json=dict(name='Unauthorized',size=8,can_create_tournaments=True,email='gustavoluzmachado@gmail.com'))
    assert response.status_code==403
    assert client.post('/api/admin/activate',headers=h,json=dict(admin_code='test-admin-code-not-production')).status_code==403
    assert client.post('/auth/register',json=dict(name='Fake',email='gustavoluzmachado@gmail.com',password='StrongPassword123')).status_code==403
    response=client.post('/auth/register',json=dict(name='Gustavo',email='GustavoLuzMachado@gmail.com',password='StrongPassword123',admin_code='test-admin-code-not-production'))
    assert response.status_code==200
    assert response.json()['can_create_tournaments']
    admin={'Authorization':'Bearer '+response.json()['token']}
    assert client.post('/api/tournaments/create',headers=admin,json=dict(name='Valid',size=12)).status_code==400
    created=post(client,admin,'tournaments/create',name='Sábado do Truco',size=16)
    assert len(created['tournaments'])==1
    assert created['tournaments'][0]['players']==[]
    assert len(client.get('/api/tournaments',headers=h).json()['tournaments'])==1
