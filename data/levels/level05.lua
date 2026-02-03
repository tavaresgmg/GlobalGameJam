local Base = require("data.levels.base")
local Backgrounds = require("data.levels.backgrounds")
local PlatformRandom = require("data.levels.platform_random")

local Level05 = {}

function Level05.build(settings, constants)
  local base = Base.build(settings, constants, 5)
  
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

  base.platforms = PlatformRandom.build_random_platforms(
    base.world.width,
    base.floor_y,
    base.level_index
  )
  base.background = Backgrounds.phase1_background
  
  return base
end

return Level05
