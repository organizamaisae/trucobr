# Análise da referência de Truco

A imagem enviada contém quinze telas e um painel promocional. Foi tratada como referência visual, não como instruções executáveis. O visual do poker anterior foi substituído. A paleta usada é preto azulado #050F14, painéis #0B222B, verde #00BD70, azul de ação #0064CB e dourado #E9BA63; bordas finas e cantos arredondados.

1. Splash: marca central, cartas em leque, espaço escuro. Implementada durante restauração da sessão, com arte desenhada no Flutter.
2. Login: marca, campos e ações empilhados. E-mail/senha e convidado; botões Google/Apple da imagem omitidos por solicitação do usuário.
3. Início: avatar/XP/saldo, faixa de temporada, ações verdes/azuis, atalhos e menu inferior. Mesa central adicionada conforme pedido textual.
4. Seleção de mesas: cinco níveis e entradas, medalhas e ação de entrar. Nenhum número fictício de jogadores online.
5. Partida: feltro verde, quatro assentos, cartas claras, placar e desafios coloridos. Adaptada para paisagem, com mão privada e indicador de vez.
6. Sala privada: 1v1/2v2, regra, senha opcional, código e criação. Não há espectadores; as conexões só recebem a própria mesa como participante.
7. Amigos: busca, presença, pedidos e convite; perfis e remoção em menu contextual.
8. Ranking: abas global/semanal/amigos, posição, nome, nível, vitórias e pontos. Dados reais.
9. Perfil: avatar, ID, XP, estatísticas, personalização e conquistas.
10. Carteira: saldo destacado, ganhos/gastos, bônus e extrato. Botão comprar fichas da imagem não implementado, pois não há compra por dinheiro.
11. Loja: categorias e cartões de itens. Avatares são monogramas e símbolos originais, não retratos copiados da imagem.
12. Torneios: inscrições, progresso e chave expansível, gerados com participantes reais.
13. Histórico: resultados, data, placar e XP; estado vazio informativo antes da primeira partida.
14. Configurações: conexão, regras, informações de conta e saída. Não há configurações de notificações sem serviço correspondente.
15. Mais: conteúdo consolidado em Configurações.

As fontes Inter e Cormorant Garamond têm licenças OFL incluídas. Logo, naipes, feltro e versos são widgets/CustomPainter sem fundo de imagem; não há quadriculado falso. Não é necessário substituir arquivo de logo. Se futuramente desejar retratos ilustrados, substitua a implementação `PlayerAvatar` por arquivos próprios/licenciados. Os PNGs antigos do poker permanecem como arquivos históricos, mas não são empacotados no aplicativo.
