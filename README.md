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

## Estrutura

```
assets/        Audio, sprites e tiles
config/        Constantes e settings
core/          Loop, input, camera, fisica, cenas
entities/      Player e inimigos
systems/       Movimento e combate
scenes/        Menu e fase
ui/            HUD
support/       Funcoes simples de math
main.lua       Entrada do jogo
```

## Controles

- Mover: A/D ou setas
- Pulo: Space
- Ataque: J, K ou X
- Voltar ao menu: Esc

## Proximo passo rapido

- Trocar sprites do player/inimigo
- Ajustar constantes em config/constants.lua
- Adicionar novas fases em scenes/
