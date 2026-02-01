local Base = require("data.levels.base")

local Level05 = {}

function Level05.build(settings, constants)
  local base = Base.build(settings, constants, 5)
  local floor_y = settings.height - 64
  
  -- Apenas o chão, sem plataformas extras
  base.platforms = {
    base.platforms[1],
  }
  
  -- Sem inimigos normais
  base.enemy_spawns = {}
  
  -- Boss final: João Facão (posição mais no centro)
  base.boss_spawns = {
    { boss_index = 3, x = 600 },  -- João Facão
  }
  
  -- Apenas um segment com o boss
  base.segments = {
    {
      start_x = 0,
      gate_x = 2000,
      locked = true,
      enemy_ids = {},
      boss_ids = { 1 },
    },
  }
  
  return base
end

return Level05
