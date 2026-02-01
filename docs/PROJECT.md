# Projeto: Jogo das Mascaras

## Visao
Jogo 2D side-scroller em um Brasil distopico entre os seculos XIX e XX (Goias), em clima de coronelismo.
O jogador comeca mascarado e pode seguir dois caminhos: absorver mascaras (ofensivo) ou libertar mascaras (defensivo).
O final e determinado pela proporcao entre mascaras absorvidas e removidas.

## Premissa narrativa
- O Coronel Supremo domina todos atraves de mascaras.
- As mascaras possuem entidades que precisam ser mortas para libertar as pessoas.
- O jogador pode se tornar o novo receptaculo (final ruim) ou libertar o povo (final bom).

## Loop principal
- Combate (bater, pulo, dash)
- Absorver ou libertar mascaras
- Progredir por bosses e ganhar habilidades

## Sistemas-chave
- Player com modo ofensivo/defensivo
- Contadores de mascaras e especiais
- Habilidades de boss (max 3 ativas)
- Boss final com bifurcacao de final

## Controles
- Mover: A/D ou setas
- Pulo: Space
- Dash: Shift
- Ataque: J, K ou X
- Especial: Q
- Interagir: E

## Status
MVP jogavel com placeholders e fluxo completo de combate, progressao e finais.

## Temporarios (TODO)
- Fonte fallback default em ui/hud.lua (substituir por fonte real em assets/fonts).
- Fase hardcoded em scenes/level01.lua (avaliar Tiled + STI).
- Sem sistema de save/progressao externo (avaliar bitser).
- Expandir cargo para imagens/sons (fonts ja via cargo).
- Hot reload em dev via lurker integrado (validar no fluxo de trabalho).

## UI/UX
- Menu minimalista com selecao por setas/WASD
- Tela Sobre separada com premissa curta
- HUD sem painel de dicas durante gameplay
- HUD compacta com foco em HP, especial e habilidades

## Mecânicas (atual)
- Pulo duplo + coyote time + jump buffer
- IA de inimigos com estados e ataque por janela
- Fase segmentada por arenas com gates

## Bibliotecas
- bump.lua (colisao)
- baton (input)
- HUMP (camera + gamestate)
- lurker + lume (hot reload dev)
- cargo (assets manager)
- anim8 (animacoes; aguardando sprites)
- sfxr.lua (SFX temporario; substituir por assets)
