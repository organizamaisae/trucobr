"""Server-only Truco engine. Never send the full state to clients."""
import secrets

RANKS = ['4', '5', '6', '7', 'Q', 'J', 'K', 'A', '2', '3']
SUITS = ['♦', '♠', '♥', '♣']


def strength(card, vira, rule):
    if rule == 'fixa':
        special = ['7♦', 'A♠', '7♥', '4♣']
        return 20 + special.index(card) if card in special else RANKS.index(card[:-1])
    manilha = RANKS[(RANKS.index(vira[:-1]) + 1) % 10]
    return 20 + SUITS.index(card[-1]) if card[:-1] == manilha else RANKS.index(card[:-1])


def new_game(players, rule='paulista'):
    g = dict(players=players, rule=rule, scores=[0, 0], dealer=len(players)-1,
             hand_no=0, winner=None, version=0, log=[])
    deal(g)
    return g


def deal(g):
    deck = [r+s for r in RANKS for s in SUITS]
    secrets.SystemRandom().shuffle(deck)
    g['hands'] = [deck[i*3:i*3+3] for i in range(len(g['players']))]
    g.update(vira=deck[-1], table=[], tricks=[], stake=1, pending=None,
             raise_owner=None, hand_done=False, last_table=[], iron=g['scores'] == [11, 11])
    g['dealer'] = (g['dealer']+1) % len(g['players'])
    g['turn'] = (g['dealer']+1) % len(g['players'])
    g['hand_no'] += 1
    if 11 in g['scores'] and not g['iron']:
        g['pending'] = dict(team=g['scores'].index(11), value=3, special=True)


def award(g, team):
    if team is not None:
        g['scores'][team] += g['stake']
        g['log'].append(f"Dupla {team+1} ganhou {g['stake']} ponto(s).")
        if g['scores'][team] >= 12:
            g['winner'] = team
    else:
        g['log'].append('Mão empatada: nenhum ponto.')
    g['hand_done'] = True


def hand_winner(tricks):
    for team in [0, 1]:
        if tricks.count(team) >= 2:
            return True, team
    if len(tricks) >= 2:
        a, b = tricks[:2]
        if a is None and b is not None:
            return True, b
        if a is not None and b is None:
            return True, a
    if len(tricks) == 3:
        return True, next((t for t in tricks if t is not None), None)
    return False, None


def act(g, uid, action, card=None, value=None):
    if uid not in g['players']:
        raise ValueError('Você não participa desta partida.')
    seat = g['players'].index(uid)
    team = seat % 2
    if g['winner'] is not None:
        raise ValueError('Partida encerrada.')
    if g['hand_done']:
        if action != 'next':
            raise ValueError('Avance para a próxima mão.')
        deal(g)
    elif g['pending']:
        p = g['pending']
        if team != p['team']:
            raise ValueError('A outra dupla precisa responder.')
        if action == 'accept':
            g['stake'] = p['value']
            g['raise_owner'] = team
            g['pending'] = None
        elif action == 'run':
            award(g, 1-team)
            g['pending'] = None
        elif action == 'raise' and not p['special'] and p['value'] < 12:
            expected = p['value']+3
            if value != expected:
                raise ValueError('Aumento inválido.')
            g['stake'] = p['value']
            g['pending'] = dict(team=1-team, value=expected, special=False)
        else:
            raise ValueError('Aceite, corra ou aumente o desafio.')
    elif action == 'run':
        if seat != g['turn']:
            raise ValueError('Aguarde sua vez.')
        award(g, 1-team)
    elif action == 'raise':
        if seat != g['turn'] or 11 in g['scores']:
            raise ValueError('Não pode aumentar agora.')
        expected = 3 if g['stake'] == 1 else g['stake']+3
        if expected > 12 or value != expected or g['raise_owner'] not in (None, team):
            raise ValueError('Aumento inválido para sua dupla.')
        g['pending'] = dict(team=1-team, value=expected, special=False)
    elif action == 'play':
        if seat != g['turn']:
            raise ValueError('Aguarde sua vez.')
        if not isinstance(card, int) or isinstance(card, bool) or not 0 <= card < len(g['hands'][seat]):
            raise ValueError('Carta inválida.')
        played = g['hands'][seat].pop(card)
        g['table'].append(dict(seat=seat, card=played))
        g['turn'] = (seat+1) % len(g['players'])
        if len(g['table']) == len(g['players']):
            best = max(strength(x['card'], g['vira'], g['rule']) for x in g['table'])
            winners = [x['seat'] for x in g['table'] if strength(x['card'], g['vira'], g['rule']) == best]
            winner = winners[0] % 2 if len({x % 2 for x in winners}) == 1 else None
            g['tricks'].append(winner)
            g['turn'] = winners[0] if winner is not None else g['table'][0]['seat']
            g['last_table'] = g['table']
            g['table'] = []
            done, winner = hand_winner(g['tricks'])
            if done:
                award(g, winner)
    else:
        raise ValueError('Ação inválida.')
    g['version'] += 1
    g['log'] = g['log'][-15:]


def view(g, uid):
    seat = g['players'].index(uid)
    result = {k: v for k, v in g.items() if k != 'hands'}
    result['hand'] = ['?' for _ in g['hands'][seat]] if g['iron'] else list(g['hands'][seat])
    result['counts'] = [len(h) for h in g['hands']]
    result['seat'] = seat
    if g['pending'] and g['pending']['special'] and g['pending']['team'] == seat % 2:
        result['partner_hand'] = g['hands'][(seat+2) % len(g['players'])] if len(g['players']) == 4 else []
    return result
