# Truco BR 3.3

- Nova logo enviada pelo usuário aplicada no login e ícones.
- Chaveamento navegável por rodadas, conexões, placares e acesso às partidas.
- Resultados não abrem automaticamente no login. Consulte Torneios ou títulos no Perfil.
- É possível inscrever-se em vários torneios. Se um inscrito estiver disputando outro torneio, o próximo aguarda a partida terminar antes de formar as mesas.
- Espectadores acompanham o estado público a cada 2 segundos; não recebem mãos privadas e não podem enviar jogadas.
- Passe mensal (mês civil UTC), ativado com 3.000 fichas virtuais. XP das partidas do mês desbloqueia dez níveis, resgatados individualmente. Recompensas ficam no histórico da carteira e cosméticos no inventário; resgates não se repetem. Passe não renova automaticamente.
- Novos emotes e duas novas mesas à venda. Cenários cobrem a área da partida com BoxFit.cover.
- Truco e Correr são os comandos principais. Ao receber pedido, o valor aceita o desafio; Aumentar permite a resposta prevista nas regras.
- Sons simples do sistema em jogadas e início do turno, controlados nas configurações. Dependem dos sons e volume do dispositivo.

## Assets
Nova logo: assets/images/truco-br-login-logo.png (arquivo do usuário).
Cenários: assets/images/table-praia.png e assets/images/table-serra.png.
Gerados com image_gen integrado, prompts:

Portrait 1024x1536 mobile Truco game full-screen background, top-down immersive Brazilian beach kiosk, pale rustic wood, woven straw borders, sea blue textile playing surface, seashells and tropical leaves only at outer edges. Large clean central playing surface fills 80 percent of frame, extends almost edge to edge, room for real game UI overlaid. Original high quality hand-painted realistic game environment. No text, no logo, no cards, no people, no chips, no UI, no inset image frame. All decorative objects confined to extreme perimeter.

Portrait 1024x1536 mobile Truco game full-screen background, top-down immersive Brazilian mountain tavern, rich dark carved wood, burgundy felt playing area, warm lantern light and stone floor around perimeter. Large clean central playing surface fills 80 percent of frame, extends almost edge to edge, room for real game UI overlaid. Original high quality hand-painted realistic game environment. No text, no logo, no cards, no people, no chips, no UI, no inset image frame. All decorative objects confined to extreme perimeter.

## Publicação
Atualizar o backend e instalar o APK 3.3.0+6. Manter o mesmo banco e variáveis existentes. As novas rotas são POST /api/pass e POST /api/rooms/spectate, ambas autenticadas.
