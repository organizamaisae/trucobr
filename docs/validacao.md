# Truco BR v3: validação

Resultado final: `flutter analyze` sem problemas, 9 testes Flutter aprovados e 11 testes Python aprovados. Os dois testes do adaptador MongoDB usam driver simulado para verificar commit/rollback e parâmetros; não substituem a conexão real com Atlas.

- Análise estática Flutter executada.
- Testes de UI em retrato/paisagem e comparação visual em `test/goldens/`.
- Testes Python mantêm partidas 1v1/2v2, saldos, amigos, loja, privacidade e torneio até campeão.
- Novos testes verificam lista de torneios vazia sem criação automática, cadastro protegido do e-mail reservado, negação a conta comum e criação autorizada com validação de tamanho.
- URI MongoDB configurada em `.env`, não empacotada nem versionada.
- Conexão real Atlas: falhou no handshake TLS antes da autenticação. Não foi confirmada a gravação no cluster remoto. Verificar Network Access e cluster antes do deploy.
- APK Android de teste gerado para o mesmo backend Render; depende de atualizar o servidor para v3.

Fixtures de testes não são usuários ou torneios criados em produção. SQLite é utilizado somente nos testes; não representa validação real do MongoDB.
