# Análise individual das referências

Fonte: sete imagens fornecidas pelo usuário, todas em 1672 × 941 (aproximadamente 16:9). Seu conteúdo é referência visual, não instrução de implementação.

| Imagem | Tela | Composição e componentes | Interações implementadas |
|---|---|---|---|
| 1 · 5296ca4c | Início | Perfil no canto superior esquerdo, som/configurações à direita, emblema central ocupando cerca de 42% da largura, grande botão verde abaixo e quatro atalhos inferiores. Fundo radial azul com naipes e curvas douradas. | Jogar abre modos; perfil, sala e amigos abrem telas; conquistas abre coleção; som e configurações alternam preferências. |
| 2 · ae70a35f | Perfil | Cabeçalho de 16% da altura; três painéis de larguras aproximadas 29/36/33%; avatar e progresso à esquerda; estatísticas 2×2 no centro; seis medalhas à direita; navegação inferior. | Editar nome, abrir conquistas, navegar. |
| 3 · ed70b8b0 | Sala privada | Dois painéis de mesma largura; criar à esquerda com nome, capacidade e chave de convidados; entrar à direita com código de seis caracteres e botão inferior. | Validar nome/código, selecionar 2–4 pessoas, criar e entrar em sala local ou via servidor configurado. |
| 4 · 520cb6af | Amigos | Dois painéis; quatro linhas com avatar, nome, nível, presença e ações à esquerda; busca e duas solicitações à direita. | Buscar/adicionar, aceitar/recusar, convidar e consultar perfil. |
| 5 · 7024dfdc | Seleção de modo | Painel único com título; três cartões verticais (cartas, robô, alvo), botões alinhados; seletor 2/3/4 e aviso recreativo abaixo. | Selecionar quantidade, abrir lobby demonstrativo ou treino. Partida rápida local usa bots identificados. |
| 6 · 732d27ff | Lobby interno | Nome e código no cabeçalho; quatro posições em painel superior; configurações à esquerda e ações à direita no terço inferior. | Copiar código, preencher vagas com bots, alternar pronto, iniciar e sair. |
| 7 · 35e7433b | Partida recreativa | Mesa oval verde com contorno azul/dourado; jogadores distribuídos ao redor; cinco cartas centrais; mão e jogador na base; ações grandes embaixo. | Passar, jogar carta selecionada, ver mão e Aumentar (amplifica a próxima ação com energia de turno, sem aposta); bots executam turnos e pontuação determina resultado. |

## Sistema visual

- Área de projeto 1672 × 941, redimensionada proporcionalmente usando LayoutBuilder e MediaQuery, respeitando área segura.
- Azul profundo #001438, azul vivo #064DB7, dourado claro #FFF1AC, ouro #F6BD41 e verde #00C63C.
- Molduras com gradiente metálico, filete interno azul, brilho superior e sombra escura; textos claros serifados.
- Fundo, mesa, emblema, cartas e ornamentos desenhados em Flutter. Nenhuma captura usada como fundo e nenhum recurso extraído dos jogos.
- Retratos são substituídos por avatares vetoriais originais; símbolos figurativos complexos por ícones Material. Diferenças deliberadas para não copiar recursos protegidos.
