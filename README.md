# Jogo Jam (LOVE)

Template 2D side-scroller feito 100% via codigo (Lua + LOVE), pronto para JAM.

## Como rodar

```
love .
```

## Qualidade

```
make fmt
make lint
make check
```

## Controles

- Mover: A/D ou setas
- Pulo: Space
- Dash: Shift
- Ataque: J, K ou X
- Especial: Q
- Interagir: E
- Voltar ao menu: Esc

## Estrutura

```
assets/        Audio, sprites e tiles
config/        Constantes e settings
core/          Loop, input, camera, fisica, cenas
data/          Definicao de bosses e habilidades
entities/      Player, inimigos, bosses
systems/       Movimento, combate, AI, progressao
scenes/        Menu, fase e final
ui/            HUD
support/       Funcoes simples de math
main.lua       Entrada do jogo
```

## Proximo passo rapido

- Trocar sprites do player/inimigo
- Ajustar constantes em config/constants.lua
- Adicionar novas fases em scenes/

## Docs

- docs/PROJECT.md (visao geral)
- docs/ROADMAP.md (80/20)
- docs/CHANGELOG.md
