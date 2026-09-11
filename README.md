# Aurora Truco Online

Conversão do projeto Aurora Cards/Poker para Flutter + Python. Login por e-mail/senha ou convidado, **sem Google**. Não há bots, dinheiro real, depósitos, compras de fichas com dinheiro nem saques.

## Executar o backend

Python 3.13 ou superior. Na pasta do projeto:

```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install -r requirements.txt
$env:DATABASE_URL = "postgresql+psycopg://USUARIO:SENHA@HOST:5432/BANCO"
.\.venv\Scripts\python server/server.py --host 0.0.0.0 --port 8000
```

As tabelas são criadas automaticamente. Para desenvolvimento rápido, sem `DATABASE_URL`, usa SQLite em `truco.db`. **No Render configure PostgreSQL**, pois o disco temporário do serviço não preserva SQLite em novos deploys. Não publique `.env`, senhas ou tokens no GitHub. `.env.example` é um exemplo; configure variáveis no terminal/Render, o arquivo não é carregado automaticamente.

Alternativa local com Docker e PostgreSQL:

```powershell
$env:POSTGRES_PASSWORD = "defina-uma-senha-forte"
docker compose up --build
```

HTTP: `/health`; documentação interativa da API: `/docs`; WebSocket: `/ws`. O primeiro frame WebSocket deve ser `{"token":"TOKEN_DA_SESSAO"}`. Cartas de outros jogadores nunca são enviadas. A API REST usa `Authorization: Bearer TOKEN`.

## Atualizar seu Render

1. Envie os arquivos modificados deste projeto ao repositório `fxzazx/aurora` (incluindo `server/`, `requirements.txt` e `render.yaml`).
2. Crie/associe um PostgreSQL no Render. No serviço web, em **Environment**, adicione `DATABASE_URL` com a **Internal Database URL** do banco. URLs começando por `postgres://` ou `postgresql://` são aceitas.
3. **Build Command:** `pip install -r requirements.txt`
4. **Start Command:** `python server/server.py --host 0.0.0.0 --port $PORT`
5. **Health Check Path:** `/health`. Use **uma instância e um worker**; a autoridade e as conexões WebSocket ficam nesse processo. Não aumente workers sem implementar coordenação distribuída.
6. Faça **Manual Deploy → Deploy latest commit**.
7. Abra `https://aurora-z5xt.onrender.com/health`. O backend novo deve retornar `{"status":"ok","app":"Aurora Truco","version":2}`. Se não houver `version: 2`, você ainda está usando o servidor antigo.

O `render.yaml` preserva o comando anterior. Em instalação por Blueprint, ele solicitará `DATABASE_URL`. Ele não cria nem contrata banco automaticamente. Consulte no painel do Render as condições do plano escolhido. O aplicativo tenta reconectar quando o servidor reinicia; a primeira requisição tem timeout de 60 segundos.

## Onde colocar a URL no aplicativo

O padrão já é **https://aurora-z5xt.onrender.com**, em `lib/services/truco_service.dart`, constante `defaultUrl`. Você pode substituir **sem editar código**:

```powershell
flutter run --dart-define=SERVER_URL=https://aurora-z5xt.onrender.com
```

Não adicione `/health`, `/api`, `/rooms` ou Markdown à URL. O aplicativo acrescenta os caminhos corretos. Se usar o backend no computador com emulador Android: `http://10.0.2.2:8000`. Em aparelho físico, use o IP local do computador na mesma rede. HTTP local funciona no Android debug; prefira HTTPS em distribuição.

## Gerar o APK no Windows

O caminho atual contém acentos. Se o analisador Dart falhar com `FormatException`, use um alias sem acentos. Verifique antes se `R:` já está associado a este projeto com `subst`.

```powershell
subst R: "C:\Users\Gustavo\Downloads\Trabalhos\Aplicações\poker"
Set-Location R:\
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define=SERVER_URL=https://aurora-z5xt.onrender.com
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Copie para o celular e instale. A identidade Android do projeto anterior foi mantida; a versão subiu para `2.0.0+2`. Este APK é para testes, assinado com a chave de desenvolvimento. Para publicar, configure sua chave de assinatura no Gradle antes de `flutter build appbundle --release`.

Se o Gradle reclamar do NDK, no Android Studio abra **SDK Manager → SDK Tools → Show Package Details**, instale a versão solicitada e repita o build. Não é preciso instalar ferramentas C++ do Visual Studio para gerar APK Android.

## iOS

A pasta `ios/` está incluída. O build iOS exige macOS, Xcode e assinatura Apple:

```bash
flutter pub get
flutter build ios --no-codesign --dart-define=SERVER_URL=https://aurora-z5xt.onrender.com
```

Abra `ios/Runner.xcworkspace` no Xcode, configure sua equipe e assinatura e gere o Archive. **O build iOS não foi executado no Windows.**

## Testar o multiplayer de verdade

1. Abra o aplicativo em dois dispositivos com a mesma URL de servidor.
2. Crie contas diferentes, ou entre como convidados diferentes.
3. Primeiro jogador: Sala privada → 1v1 → Criar sala.
4. Segundo jogador: digite o código e a senha, se houver.
5. O anfitrião inicia. Cada um recebe somente suas três cartas. Toque na carta quando for sua vez.
6. Para 2v2, entre com quatro contas. Assentos 0/2 e 1/3 formam as duplas.
7. Na partida rápida, selecione a mesma modalidade, regra e entrada; ela inicia automaticamente quando completar jogadores.

Não há preenchimento automático com robôs. Salas vazias permanecem aguardando. Uma ação não respondida por três minutos causa derrota por inatividade. Uma sala aguardando sem atividade fecha após 15 minutos. O estado persiste e permite retomar após reinício do servidor. Não saia da conta durante uma partida: voltar exige a mesma conta; convidados dependem do token salvo no dispositivo.

## Regras implementadas

Paulista, baralho de 40 cartas, três cartas por jogador, melhor de três vazas, objetivo 12 pontos. Ordem natural: 4,5,6,7,Q,J,K,A,2,3. Vira define manilha; naipes das manilhas: ouros < espadas < copas < paus.

Desafios 1 → 3 → 6 → 9 → 12. A dupla adversária aceita, corre ou aumenta; um aumento só é aplicado pelo servidor. Mão de onze permite ver o parceiro e escolher jogar por três ou correr por um; onze a onze usa cartas ocultas. Três empates não dão pontos. Há também **manilha fixa com pontuação paulista** (7♦, A♠, 7♥, 4♣); não é apresentada como regulamento mineiro.

## Fichas, amigos, loja e torneios

- Saldo inicial: 10.250. Entradas rápidas: 100, 500, 1.000, 5.000 e 10.000. Sala privada gratuita.
- Vencedores recebem duas vezes a entrada +100 por jogador; derrotados perdem a entrada. Cada resultado é liquidado uma única vez em transação.
- Vitória: 150 XP; derrota: 50 XP; nível a cada 1.000 XP.
- Bônus diário: 300 fichas. Missão diária: três partidas/300 fichas. Missão semanal: cinco vitórias/1.500 fichas. Períodos em UTC.
- Amigos reais, pedidos/aceitação/remoção, busca por nome/ID, convites com validade de cinco minutos. Salas com senha continuam exigindo a senha.
- Ranking: 100 pontos por vitória; semanal usa vitórias da semana ISO em UTC; aba amigos mostra sua rede. Histórico e estatísticas persistidos.
- Loja com avatares geométricos, molduras, versos, mesas, emotes e efeito de brilho. Passe Aurora custa apenas fichas e concede +100 fichas e 50 XP em cada bônus diário após a compra. Não há pagamento externo.
- Torneios gratuitos 1v1 de 8/16/32 participantes, começam ao lotar e criam rodadas automaticamente. Campeão ganha tamanho ×250 fichas +1.000 XP. Chave acessível na tela Torneios.

## Organização

`lib/core/app.dart`: sessão, navegação e responsividade. `lib/screens/`: telas. `lib/widgets/truco_widgets.dart`: componentes e arte vetorial própria. `lib/services/truco_service.dart`: HTTP, armazenamento seguro e WebSocket.

`server/engine.py`: regras puras; `server/api.py`: autenticação, salas, amigos, ranking, carteira, loja, torneios e transmissão; `server/security.py`: scrypt/tokens; `server/database.py`: persistência SQLAlchemy/PostgreSQL; `server/server.py`: entrada do processo.

As contas usam senha com sal e scrypt. Tokens aleatórios são guardados como hash no banco e com armazenamento seguro no Android/iOS. Login possui limite de tentativas por IP. O cliente não controla cartas, resultado, pontuação, XP ou saldo. Ações têm versão para impedir repetição de jogadas antigas. Não há login Google nem verificação/recuperação de e-mail implementada.

## Testes e limites de validação

```powershell
.\.venv\Scripts\python -m pytest server/test_truco.py -q
flutter analyze
flutter test
```

Testes cobrem partidas completas 1v1/2v2, WebSocket com contas distintas, privacidade da mão, ações antigas, permissões, carteira, loja, amizades, senha da sala, empates, desafios e torneios. Testes de backend usam SQLite isolado; o adaptador PostgreSQL é fornecido, mas precisa ser validado contra o seu banco antes de disponibilizar publicamente. Flutter testa navegação, estados e layouts em retrato/paisagem, com imagens de comparação.

Este projeto entrega o fluxo jogável e persistente em um servidor único. Operação comercial em larga escala ainda exige teste de carga, moderação/antifraude de contas, recuperação de acesso, política de privacidade própria, backups operacionais e coordenação entre múltiplas instâncias. Nenhum deploy no seu Render ou envio ao GitHub é feito automaticamente por gerar o APK.
