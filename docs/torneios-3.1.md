# Torneios e convites — Truco BR 3.1

A referência visual é a imagem de torneios anexada em 12/09/2026. A implementação usa verde escuro, banner de madeira/chimarrão/cartas, título branco, quatro abas, cartões com troféus, premiação dourada e barra inferior com sete destinos. Os exemplos nas capturas de teste não são inseridos no banco.

## Operação

- A permissão continua restrita ao e-mail administrador previamente ativado; a API confere a permissão.
- Cadastro: nome de 3 a 50 caracteres, modo 1v1 ou 2v2, 2–256 vagas individuais e início futuro. Em 2v2, vagas pares, mínimo 4. O app usa seletores nativos de data/hora e transmite UTC.
- O servidor verifica os horários a cada 10 segundos. Mesmo lotado, o evento agendado aguarda seu horário. Ao reiniciar, o servidor processa eventos vencidos que ainda aguardavam. O serviço precisa permanecer ativo para cumprir o horário; suspensão do processo adia o início até ele voltar.
- 1v1 exige pelo menos duas pessoas; 2v2 exige quatro. Com menos pessoas, o torneio é cancelado, sem vencedores nem recompensas.
- No 2v2, inscritos consecutivos formam duplas; a dupla permanece até a final. Com quantidade ímpar, o último inscrito fica sem par, fora da chave e sem cobrança. Isso é informado no formulário e na ficha do evento. Não há preenchimento com robôs.
- A primeira rodada é completada com folgas até a próxima potência de dois. Exemplo: cinco competidores geram uma partida e três folgas, seguidas de duas semifinais e uma final. Os confrontos são sorteados no servidor.
- O valor total final é 250 fichas por participante efetivo. No 2v2, divide-se igualmente entre os dois campeões, com 1.000 XP para cada. Antes do início, mostra-se a premiação máxima. Tudo permanece virtual.
- As transações salvam partida, progressão, fichas e títulos. A liquidação é idempotente. O título guarda ID/nome do torneio, modalidade, data, campeões, fichas e XP. O perfil permite reabrir a interface de vitória.
- Eventos legados sem horário continuam iniciando ao lotar; o aplicativo novo sempre envia um horário. Nenhum evento antigo é apagado.

## Convites

O estado autenticado recebido pelo WebSocket inclui convites válidos para salas que ainda têm vaga. Um aviso sobre a navegação permite aceitar ou recusar, inclusive sobre uma partida ou formulário. Aceitar fecha o formulário e leva ao lobby somente quando o servidor confirma a entrada. Jogadores em outra sala precisam sair antes; a sala atual não é abandonada automaticamente.

`POST /api/invite/respond` recebe `id` e `action` (`accept` ou `decline`). O servidor valida destinatário, validade, lotação e participação. Um convite válido permite entrar em sala protegida sem compartilhar a senha. O convite é consumido após entrada/recusa e expira em cinco minutos. A alteração é transmitida às sessões conectadas. Isso é notificação dentro do app aberto, não push do Android/iOS com o app fechado.

## Verificações

Validação local concluída: `flutter analyze` sem problemas, 11 testes Flutter e 16 testes Python aprovados; APK debug gerado. A revisão das capturas ajustou o banner e as quatro abas para caberem na largura de 390 pixels. A imagem inteira da referência não é usada como interface.

Backend: suítes `test_truco.py`, `test_admin.py`, `test_mongo_adapter.py` e `test_scheduled_tournaments.py`. Cobrem torneios agendados, capacidade completa sem início antecipado, chave ímpar com folgas, duplas fixas, mínimo de inscritos, título/recompensa sem duplicação e convite WebSocket privado autorizado.

Flutter: `flutter analyze` e `flutter test`. Capturas em `test/goldens/tournaments_live.png` e `test/goldens/tournament_champion.png`; testes de criação 2v2, navegação, persistência exibida no perfil e convite sobre diálogo. As suítes de API usam SQLite isolado; a validação de integração com o cluster MongoDB/Render requer a conexão TLS operacional.

## Arte original

Arquivo: `assets/images/truco-br-tournaments.png`. Gerado com a ferramenta nativa imagegen, sem CLI. Troféus em `lib/widgets/tournament_trophy.dart` são desenhados com CustomPainter. Tipografia, cartões, abas e botões são widgets, não partes da imagem.

Prompt usado:

> Create an original premium mobile Brazilian Truco tournament game decorative banner asset, wide landscape 3:1 composition. Cinematic realistic stylized 3D illustration. Rustic warm Brazilian wooden tavern background, deep forest green felt at bottom, dark softly blurred warm amber shelves behind. Left edge: detailed leather wrapped chimarrao gourd with metal straw, no writing. Right edge: three traditional playing cards A spades, 7 hearts, K clubs in a fan beside a small fabric Brazilian flag. Central 55 percent is dark quiet negative space to overlay a white large tournament heading in application code. Rich wood grain, subtle green and gold light, dramatic warm rim lighting, professional mobile game finish. No people, no text, no lettering, no logo, no UI, no border, no watermark. Must be an original illustration, not a screenshot.
