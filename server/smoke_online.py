"""Test two independent clients over real HTTP and WebSocket, not TestClient."""
import asyncio
import json
import secrets
import httpx
import websockets


async def main():
    async with httpx.AsyncClient(base_url='http://127.0.0.1:8011') as c:
        players=[]
        for _ in range(2):
            name='Smoke'+secrets.token_hex(4)
            response=await c.post('/auth/register',json=dict(name=name,email=name+'@test.local',password='StrongPassword123'))
            response.raise_for_status()
            players.append(response.json())
        async with websockets.connect('ws://127.0.0.1:8011/ws') as first, websockets.connect('ws://127.0.0.1:8011/ws') as second:
            await first.send(json.dumps(dict(token=players[0]['token'])))
            await second.send(json.dumps(dict(token=players[1]['token'])))
            for p in players:
                response=await c.post('/api/rooms/quick',headers={'Authorization':'Bearer '+p['token']},json=dict(capacity=2,fee=100))
                response.raise_for_status()
            async def state(ws,version):
                for _ in range(20):
                    result=json.loads(await asyncio.wait_for(ws.recv(),5))
                    room=result.get('data',{}).get('room')
                    if room and room.get('game') and room['game']['version']==version:
                        return room
                raise AssertionError('No game state received')
            a,b=await asyncio.gather(state(first,0),state(second,0))
            assert a['game']['hand']!=b['game']['hand']
            assert 'hands' not in a['game']
            p=players[a['game']['turn']]
            response=await c.post('/api/rooms/action',headers={'Authorization':'Bearer '+p['token']},json=dict(code=a['code'],version=0,action='play',card=0))
            response.raise_for_status()
            a,b=await asyncio.gather(state(first,1),state(second,1))
            assert a['game']['table']==b['game']['table']
            print('PASS: two real sockets, private hands, authenticated HTTP action and synchronized table.')


if __name__=='__main__':
    asyncio.run(main())
