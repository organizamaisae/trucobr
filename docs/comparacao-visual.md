# Comparação visual

Referências inspecionadas individualmente antes da implementação. As sete telas Flutter foram renderizadas em 1672×941 por testes golden e inspecionadas visualmente. Também foram testadas em 844×390 e 1280×800. As imagens originais são apenas referência, nunca fundos do aplicativo.

| Referência | Captura Flutter | Comparação e ajustes |
|---|---|---|
| 1 — Início | `test/goldens/home.png` | Mantidos perfil à esquerda, controles à direita, emblema central, CTA verde e quatro atalhos. Ajustados altura do perfil, posição do logo e ícones inferiores. Emblema original Aurora Cards substitui a marca da referência. |
| 2 — Perfil | `test/goldens/profile.png` | Mantidas as três colunas e grade 2×2. Ajustados ícones e altura dos números para eliminar cortes. Medalhas vetoriais e avatar neutro substituem recursos originais. |
| 3 — Sala privada | `test/goldens/private.png` | Mantidos dois painéis e botões inferiores. Código apresentado em seis quadrados editáveis; nome, seletor e chave são widgets reais. Chave ajustada para verde/branco. |
| 4 — Amigos | `test/goldens/friends.png` | Mantidas quatro linhas à esquerda e busca/convites à direita. Status e convites funcionais; ação de convidar fica desabilitada em amigos offline. |
| 5 — Modos | `test/goldens/modes.png` | Mantidos três cartões, seletor 2/3/4 e nota recreativa. Ajustadas alturas de ilustrações para manter todos os botões dentro dos painéis. Textos identificam a demonstração local. |
| 6 — Lobby | `test/goldens/lobby.png` | Mantidas fileira de jogadores, código e dois painéis inferiores. A demonstração ocupa as vagas com bots em vez de mostrar um jogador remoto aguardando; prontidão do usuário bloqueia/libera o início. |
| 7 — Mesa | `test/goldens/match.png` | Mantidos feltro oval, bordas azul/dourado, cinco cartas centrais, mão e placar inferior. Ajustados emblema e faixa de rodada. A barra tem quatro ações, incluindo Aumentar. Quantidade de adversários acompanha 2–4 participantes; avatares de bots substituem retratos. |

## Diferenças conhecidas

A fonte livre, os ícones, os retratos substitutos e o emblema original diferem dos recursos das referências. Molduras e luzes são aproximações vetoriais, sem reproduzir a textura raster de cada filete. A mesa usa cartas de ação com pontos, não regras de apostas de poker. Em telas com proporção diferente de 16:9 são preservadas margens. A inspeção foi feita em renderização Flutter de teste; não houve inspeção em aparelho Android por ausência do SDK.
