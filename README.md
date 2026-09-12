# Truco BR — versão 3

Mesmo aplicativo Flutter e mesmo backend Python/multiplayer, agora com o visual brasileiro da referência e MongoDB. O endereço do servidor continua `https://aurora-z5xt.onrender.com`. Login por e-mail/senha ou convidado, sem Google. Não há bots nem operações com dinheiro real.

## O que mudou

- Nome exibido **Truco BR**, versão `3.0.0+3`; identificador Android preservado para atualizar o aplicativo existente.
- Interface verde escura, madeira, dourado, banner e avatar originais, JOGAR amarelo, salas privadas com abas, fichas desenhadas em código.
- **Nenhum torneio é criado automaticamente.** A lista começa vazia. Eventos são publicados pelo administrador no aplicativo; continuam começando quando completam 8, 16 ou 32 jogadores reais.
- Somente a conta `gustavoluzmachado@gmail.com`, ativada com código privado, pode criar torneios. A API valida essa permissão em cada criação, independentemente da interface.
- Persistência MongoDB com transações para salas, usuários, fichas, sessões, loja, amigos e torneios.

## Banco informado

A credencial fornecida foi configurada apenas no arquivo local **`.env`**, ignorado pelo Git e excluído dos pacotes ZIP. Não há senha do banco no código Flutter/Python. O banco selecionado é **`quizeid`**, mesmo que a URI tenha `/QuizID`: `MONGODB_DB` determina o banco efetivamente usado pelo driver. A coleção do aplicativo é **`truco_br_records`**; outras coleções não são apagadas nem reutilizadas.

Configuração esperada:

```dotenv
MONGODB_URI=COLE_AQUI_SUA_URI_COMPLETA
MONGODB_DB=quizeid
ADMIN_SETUP_CODE=SEU_CODIGO_PRIVADO_DE_ATIVACAO
TRUCO_STORAGE=mongo
PORT=5000
```

O `.env` é carregado automaticamente; variáveis do ambiente têm prioridade. O ZIP traz apenas `.env.example`, sem credenciais. Dados do antigo PostgreSQL/SQLite **não são migrados automaticamente** para o MongoDB.

### Situação da conexão

O teste contra o cluster informado falhou durante o handshake TLS (`ServerSelectionTimeoutError`). Isso aconteceu antes de confirmar autenticação ou gravar dados. Não foi desativada a verificação de certificados. Portanto, a configuração está pronta, mas **o acesso ao Atlas ainda precisa ser liberado/verificado**.

No Atlas:

1. Confira se o cluster está ativo.
2. Em **Security → Network Access**, adicione o IP público atual do computador para testes locais.
3. Para o Render, adicione os IPs de saída do serviço, exibidos no painel do Render.
4. Em **Database Access**, confira se o usuário da URI tem acesso de leitura/escrita ao banco `quizeid`.
5. Teste novamente sem alterar ou remover TLS:

```powershell
.\.venv\Scripts\python server/check_mongo.py
```

O teste faz ping e verifica gravação/leitura/rollback de uma transação com identificador aleatório. Não apaga dados existentes e não imprime a senha. Referência: https://www.mongodb.com/docs/atlas/troubleshoot-connection/

## Executar localmente

Na pasta do projeto:

```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install -r requirements.txt
.\.venv\Scripts\python server/check_mongo.py
.\.venv\Scripts\python server/server.py
```

Porta padrão **5000**. Saúde: `http://127.0.0.1:5000/health`; documentação: `/docs`; WebSocket: `/ws`.

Com Docker, configure `.env` e execute `docker compose up --build`. O container conecta ao Atlas informado, não cria outro banco.

## Atualizar o mesmo Render

1. Envie esta versão ao mesmo GitHub `fxzazx/aurora`.
2. No serviço web existente, mantenha **Root Directory** vazio e branch `main`.
3. **Build Command:** `pip install -r requirements.txt`
4. **Start Command:** `python server/server.py --host 0.0.0.0 --port $PORT`
5. **Health Check Path:** `/health`
6. Em **Environment**, configure `MONGODB_URI`, `MONGODB_DB=quizeid` e `ADMIN_SETUP_CODE` com os valores do seu `.env` local. Use `PYTHON_VERSION=3.13.7`. Remova `TRUCO_STORAGE=sqlite`, se existir. O antigo `DATABASE_URL` não é usado no modo MongoDB.
7. Libere no Atlas os IPs de saída do Render.
8. Faça **Manual Deploy → Deploy latest commit**.

O Render define sua própria variável `PORT`; mantenha `$PORT` no comando. Não altere a URL do aplicativo, não crie outro serviço e não coloque a URI do banco no APK.

Resposta esperada em `https://aurora-z5xt.onrender.com/health`:

```json
{"status":"ok","app":"Truco BR","version":3}
```

## Ativar seu administrador e criar torneios

O código de ativação impede que alguém ganhe acesso administrativo simplesmente cadastrando seu e-mail. O valor foi gerado em **`ADMIN_SETUP_CODE` no `.env` local**. Use o mesmo valor no ambiente do Render. Não compartilhe esse código com jogadores.

1. Instale a nova versão do APK.
2. Cadastre `gustavoluzmachado@gmail.com`. Ao digitar esse e-mail, o formulário mostra **Código de ativação do administrador**.
3. Preencha com o valor de `ADMIN_SETUP_CODE` e escolha sua senha de login.
4. Se essa conta já existir no banco, faça login e abra **Configurações → Ativar administrador**, usando o mesmo código.
5. Vá a **Torneios → CRIAR TORNEIO**.
6. Informe o nome e escolha 8, 16 ou 32 jogadores; toque em **Publicar**.

As outras contas veem a lista e podem se inscrever, mas não veem o botão de criação. Requisições diretas de contas comuns recebem HTTP 403. Não há torneios de exemplo adicionados pelo servidor. Torneios antigos vazios e sem criador não são exibidos; torneios com participantes não são apagados.

## Gerar APK

O projeto atual tem acentos no caminho. Se o analisador apresentar `FormatException`, confira `subst` e use `R:` associado a esta pasta:

```powershell
subst R: "C:\Users\Gustavo\Downloads\Trabalhos\Aplicações\poker"
Set-Location R:\
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define=SERVER_URL=https://aurora-z5xt.onrender.com
```

Saída: `build/app/outputs/flutter-apk/app-debug.apk`. O APK distribuído é para testes, assinado com chave de desenvolvimento. Para publicação nas lojas, configure suas chaves de assinatura. iOS está incluído, mas exige macOS/Xcode e assinatura Apple; não foi compilado no Windows.

## Arquitetura preservada

- `lib/core/app.dart`: sessão e navegação; `lib/screens/`: telas reais.
- `lib/services/truco_service.dart`: HTTP autenticado, armazenamento seguro e WebSocket.
- `lib/widgets/truco_widgets.dart` e `br_art.dart`: componentes, logo vetorial, cartas, fichas, feltro e artes.
- `server/api.py`: mesmas rotas e autoridade sobre usuários, salas, saldos e resultados; nova rota `POST /api/tournaments/create`.
- `server/database.py`: adaptador MongoDB transacional; SQLite somente para testes isolados quando `TRUCO_STORAGE=sqlite`.
- `server/engine.py`: Truco 1v1/2v2, cartas privadas, vira, desafios, mão de onze e placar até 12.
- `server/security.py`: scrypt e tokens aleatórios com hash no banco.

Mantenha **uma instância/um worker**. O estado persiste no MongoDB, mas a coordenação em tempo real ainda é de um processo. O cluster Atlas precisa suportar transações. Não há fallback silencioso para SQLite se o MongoDB falhar.

## Testes

```powershell
.\.venv\Scripts\python -m pytest server/test_truco.py server/test_admin.py server/test_mongo_adapter.py -q
flutter analyze
flutter test
```

Os testes de lógica usam SQLite isolado e não modificam seu Atlas. Cobrem partidas completas, torneio até a final, ficha/loja, WebSockets, privacidade e autorização exclusiva de criação. As capturas Flutter usam fixtures; não são jogadores inseridos no banco real.

O teste real do Atlas continua bloqueado pela falha de conexão descrita acima. Não houve deploy no Render nem push ao GitHub nesta entrega. Testes de carga, recuperação por e-mail e build iOS continuam fora da validação realizada.
