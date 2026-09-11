# Validação da entrega

Verificado no Windows com Flutter 3.47.3 e Python 3.14:

- `flutter analyze`: sem problemas.
- `flutter test`: testes de API cliente, login, navegação retrato/paisagem, lobby, mesa e capturas visuais.
- `python -m pytest server/test_truco.py -q`: oito testes, incluindo partidas completas 1v1/2v2, saldo/loja, amizades, desafios, privacidade, ações inválidas e torneio completo até o campeão.
- `python server/smoke_online.py`: duas contas em conexões HTTP/WebSocket reais, mãos privadas e sincronização da carta jogada. Executado contra servidor local separado na porta 8011.
- APK Android debug compilado com `SERVER_URL=https://aurora-z5xt.onrender.com`.

O banco usado nos testes foi SQLite. Não foi executado teste contra um PostgreSQL real, build iOS, teste de carga ou teste em aparelhos físicos. O backend do Render não foi atualizado nesta entrega. Para conectar com o APK novo, publique o backend v2 e configure PostgreSQL seguindo o README.

As capturas da interface são geradas com contas de fixture dos testes; esses jogadores não são adicionados às salas reais.
