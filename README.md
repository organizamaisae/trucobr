# Aurora Cards

Aplicativo Flutter/Dart recreativo para Android horizontal, inspirado nas sete referências fornecidas. Interface de widgets reais com navegação, formulários, amigos, lobby e partida local por turnos. **Não há apostas, dinheiro, fichas compráveis, depósitos, saques ou prêmios.**

## Executar

Requisitos: Flutter 3.47.3 / Dart 3.13 ou compatível, Python 3.10+ para o servidor opcional e Android SDK para Android.

```powershell
flutter pub get
flutter run
```

Para visualizar no navegador:

```powershell
flutter run -d chrome
```

O Android utiliza `sensorLandscape`, área segura e modo imersivo. `LayoutBuilder` e `MediaQuery` dimensionam uma área 1672 × 941 proporcionalmente; telas com outra proporção recebem margens para preservar a composição. A interface foi testada em 1672×941, 844×390 e 1280×800.

## Servidor Python e onde colocar o link

### Publicar no Render

O repositório já inclui `render.yaml`. No GitHub, abra o repositório do projeto e confirme que `server/server.py`, `requirements.txt` e `render.yaml` foram enviados. No Render, escolha **New → Web Service → Build and deploy from a Git repository**, conecte o GitHub, selecione este repositório e confirme:

```text
Build Command: pip install -r requirements.txt
Start Command: python server/server.py --host 0.0.0.0 --port $PORT
Health Check Path: /health
```

O plano gratuito pode dormir após inatividade. Quando o serviço ficar com status **Live**, copie a URL HTTPS, parecida com `https://aurora-cards-server.onrender.com`, e compile o aplicativo apontando para ela:

```powershell
flutter build apk --release --dart-define=SERVER_URL=https://aurora-z5xt.onrender.com
```

Não acrescente `/rooms` ao endereço. Teste a instalação com `https://sua-url.onrender.com/health`; a resposta esperada é JSON com `status: ok`. O banco de salas atual fica em memória e reiniciar o serviço apaga as salas. Para produção, adicione persistência e autenticação.

Servidor sem dependências externas:

```powershell
python server/server.py --host 0.0.0.0 --port 8080
```

**O link é configurado na variável de compilação `SERVER_URL`.** A leitura está em `lib/services/room_service.dart`, na constante `RoomService.serverUrl`.

```powershell
# Emulador Android, servidor no computador:
flutter run --dart-define=SERVER_URL=http://10.0.2.2:8080

# Celular Android na mesma rede (substitua pelo IP do computador):
flutter run --dart-define=SERVER_URL=http://192.168.1.100:8080

# Servidor hospedado com HTTPS:
flutter run --dart-define=SERVER_URL=https://seu-servidor.exemplo.com

# Navegador local:
flutter run -d chrome --dart-define=SERVER_URL=http://localhost:8080
```

Não adicione `/rooms` ao link. Reinicie/recompile o app após alterar `SERVER_URL`. A versão debug Android permite HTTP para desenvolvimento; use HTTPS para APK release. No celular, `localhost` se refere ao celular, não ao computador. Para acessar pela rede, a porta 8080 precisa estar liberada no firewall do computador.

Sem `SERVER_URL`, as salas são guardadas na memória do aplicativo e podem ser reabertas pelo código **na mesma execução**. Com o servidor, outro dispositivo pode localizar o cadastro da sala pelo código. O servidor fornece:

- `GET /health`: diagnóstico;
- `POST /rooms`: cria sala com `name`, `capacity` (2–4) e `private`;
- `POST /rooms/{codigo}/join`: localiza sala pelo código.

Salas expiram após seis horas e são perdidas ao reiniciar o servidor. A opção “somente convidados” registra a intenção de acesso por código. Esta API demonstrativa não possui autenticação, lista de convidados verificada ou persistência.

**Escopo online:** o servidor cadastra e localiza salas. Lobby, amigos, prontidão e partidas são demonstrativos locais; não há sincronização de turnos entre dispositivos ou matchmaking real. “Partida rápida” inicia uma mesa com bots claramente identificados. Os convites da lista são simulações locais. Para implementar multiplayer real, é necessário acrescentar identidade de jogadores e protocolo de estado/turnos autoritativo ao servidor.

## Como jogar

1. Início → Jogar → selecione 2, 3 ou 4 participantes.
2. Abra Partida rápida ou Contra bots e inicie pelo lobby. Modo treino abre a mesa com instruções.
3. Toque em uma carta da mão para selecioná-la. “Ver mão” permite escolher entre as três cartas e mostra sua força.
4. **Jogar carta** soma sua força ao placar e entrega o turno aos bots.
5. **Aumentar** gasta uma energia e acrescenta 5 de força à próxima carta, até duas vezes por turno. Não representa aposta. A energia começa em 3, recupera 1 a cada rodada e não pode ser comprada.
6. **Passar** não soma pontos e recupera uma energia. O aumento preparado é descartado ao passar.
7. Após cinco rodadas, o maior placar vence. O resultado atualiza o perfil durante a sessão.

## Telas e organização

```text
lib/
  main.dart
  core/app.dart                 # navegação e estado da demonstração
  models/game.dart              # cartas, amigos e regras de turnos
  services/room_service.dart    # HTTP e salas locais; SERVER_URL
  theme/royal_theme.dart        # cores, fonte e tema
  widgets/royal_widgets.dart    # botões, painéis, títulos, cartas e painters
  screens/
    home/
    profile/
    private_room/
    friends/
    game_modes/
    room_lobby/
    match/
server/                        # servidor e testes Python
assets/fonts/                  # Cormorant Garamond, licença OFL inclusa
assets/images/aurora-logo.png   # emblema original gerado para este projeto
```

As telas usam `part` para compartilhar o estado da demonstração na biblioteca `core/app.dart`. Não há captura de referência no bundle. `Stack/Positioned` são usados para a mesa e para sobrepor o campo editável aos seis quadrados do código.

## Recursos visuais substituíveis

- **Logo:** substitua `assets/images/aurora-logo.png` por uma arte própria 1536×1024 (proporção 3:2). O arquivo atual é original, com fundo azul; o widget `Emblem` suaviza as bordas ao compor com o fundo. Não foi possível obter alpha real pela ferramenta de geração, portanto não é anunciado como PNG transparente.
- **Avatares:** placeholders vetoriais originais no componente `Avatar`, em `lib/widgets/royal_widgets.dart`. Para retratos próprios, adicione `assets/images/avatar-01.webp` até `avatar-04.webp`, registre-os no `pubspec.yaml` e substitua o ícone no componente por `ClipOval(Image.asset(...))`. Tamanho sugerido: 256×256. Não foram copiados retratos das referências.
- **Fundo, naipes, mesa, espadas e louros:** desenhados por `CustomPainter`, editáveis em `royal_widgets.dart`.
- **Fonte:** Cormorant Garamond livre, com licença em `assets/fonts/OFL.txt`. Ela aproxima a tipografia serifada das referências, mas não é a mesma fonte.

A composição, paleta e proporções seguem as referências; logo, retratos substitutos, ícones e regras são originais/adaptados. A reprodução não é pixel a pixel.

## Testes e comparação visual

```powershell
flutter analyze
flutter test
python -m unittest discover -s server -v
```

Os testes cobrem limites do aumento, pontuação e fim da partida, salas locais, navegação e ausência de overflow nas sete telas em três tamanhos. Sete testes golden com fontes carregadas comparam a renderização com `test/goldens/*.png`.

Para atualizar capturas **após revisar visualmente alterações intencionais**:

```powershell
flutter test test/visual_test.dart --update-goldens
```

A análise inicial individual está em `docs/referencias.md`. O relatório da comparação final e suas diferenças está em `docs/comparacao-visual.md`. Os goldens verificam regressões da implementação, não equivalência pixel a pixel às imagens fornecidas.

### Caminhos com acentos no Windows

Nesta instalação, `flutter analyze` apresentou um erro interno de JSON ao processar o caminho `Aplicações`. O projeto foi analisado usando um alias sem acentos para a mesma pasta:

```powershell
subst R: "C:\Users\Gustavo\Downloads\Trabalhos\Aplicações\poker"
Set-Location R:\
flutter analyze
flutter test
```

Se R: já estiver em uso, escolha outra letra. Ao terminar e após sair de R:, `subst R: /D` remove somente o alias, sem apagar os arquivos.

## Gerar APK

Neste ambiente, a tentativa de build parou com **No Android SDK found**. Não foi gerado APK.

Instale o Android SDK pelo Android Studio, incluindo Android SDK Platform, Platform Tools, Command-line Tools e Build Tools. Depois:

```powershell
flutter config --android-sdk "C:\Users\SEU_USUARIO\AppData\Local\Android\Sdk"
flutter doctor --android-licenses
flutter doctor
flutter build apk --debug

# APK otimizado com servidor HTTPS:
flutter build apk --release --dart-define=SERVER_URL=https://aurora-z5xt.onrender.com
```

Saídas: `build/app/outputs/flutter-apk/app-debug.apk` ou `app-release.apk`. O template de assinatura ainda usa a chave debug; configure seu keystore em `android/app/build.gradle.kts` antes de distribuir uma release assinada. Para instalar em aparelho autorizado via USB: `flutter install`.
