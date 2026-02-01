# Bibliotecas (LÖVE)

## Em uso agora
- **bump.lua** (colisao AABB): controla colisao entre player, inimigos e plataformas.
- **baton** (input): padroniza controles (WASD/setas, ataque, dash, etc).
- **HUMP Camera**: camera suave/centralizada com `lookAt`.
- **HUMP Gamestate**: troca de cenas (menu, fase, final) sem estado custom.
- **lurker + lume** (dev): hot reload de codigo em desenvolvimento.
- **cargo**: asset manager (fonts via assets).
- **SUIT**: UI imediata para HUD/slots com pouco codigo.

## Preparadas (para integrar)
- **anim8**: animacoes por spritesheet (quando assets chegarem).
- **sfxr.lua**: SFX procedural temporario (substituir por assets reais).

## Candidatas (avaliar)
- **STI**: integra mapas do Tiled para reduzir codigo de fase.
- **bitser**: serializacao para save/progressao (requer LuaJIT).
- **Jumper**: pathfinding grid para AI em mapas.

## Diretriz
Sempre preferir bibliotecas quando houver equivalente estavel, evitando implementacoes autorais de sistemas comuns.
