# Verificação visual

As capturas de teste ficam em `test/goldens/truco_*.png`. Retrato de referência: 390×844; mesa horizontal: 844×390. A navegação também é testada em paisagem. As capturas antigas sem prefixo `truco_` pertencem ao projeto de poker e não são baselines da nova versão.

Na revisão inicial foram identificados overflow da marca, campo de regras largo e glifos ausentes nos naipes. A marca recebeu ajuste de escala, o seletor passou a expandir dentro do painel e os naipes foram redesenhados com CustomPainter. A mesa recebeu quatro posições, espaço para as cartas e botões de desafio habilitados conforme o estado recebido do servidor.

A referência usa retratos ilustrados, textura fotográfica e efeitos 3D. Esta versão usa arte vetorial original, avatares geométricos e feltro procedural; preserva a hierarquia, paleta e organização, sem prometer reprodução pixel a pixel. A presença e os dados exibidos dependem de contas reais, e listas sem dados mostram estados vazios úteis.

Para atualizar baselines intencionalmente: `flutter test --update-goldens`. Para verificar sem alterá-las: `flutter test`.
