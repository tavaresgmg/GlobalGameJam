local Base = require("data.levels.base")
local Backgrounds = require("data.levels.backgrounds")
local PlatformRandom = require("data.levels.platform_random")

local Level03 = {}

function Level03.build(settings, constants)
  local base = Base.build(settings, constants, 3)

  base.enemy_spawns = {
    { kind = "grunt", x = 200, left = 150, right = 350, speed_mult = 1.0 },
    { kind = "rusher", x = 450, left = 350, right = 550, speed_mult = 1.2 },
    { kind = "grunt", x = 750, left = 650, right = 850, speed_mult = 0.9 },
    { kind = "rusher", x = 1050, left = 950, right = 1150, speed_mult = 1.15 },
    { kind = "grunt", x = 1350, left = 1250, right = 1450, speed_mult = 1.0 },
    { kind = "rusher", x = 1650, left = 1550, right = 1750, speed_mult = 1.2 },
    { kind = "grunt", x = 1950, left = 1850, right = 2050, speed_mult = 0.95 },
    { kind = "rusher", x = 2200, left = 2100, right = 2300, speed_mult = 1.1 },
  }
  
  -- Mini boss no final da fase
  base.boss_spawns = {
    { boss_index = 2, x = 3600 },  -- Capanga da Noite
  }
  
  -- Segments: matar todos inimigos, depois o boss
  base.segments = {
    {
      start_x = 0,
      gate_x = 3300,
      locked = true,
      enemy_ids = { 1, 2, 3, 4, 5, 6, 7, 8 },
      boss_ids = {},
    },
    {
      start_x = 3300,
      gate_x = 4000,
      locked = true,
      enemy_ids = {},
      boss_ids = { 1 },
    },
  }

  local last_gate_x = base.segments[#base.segments] and base.segments[#base.segments].gate_x
  if last_gate_x then
    base.world.width = last_gate_x
    if base.platforms[1] then
      base.platforms[1].w = last_gate_x
    end
  end

  base.boss_limit_x = nil
  if base.boss_spawns and #base.boss_spawns > 0 then
    local limit = base.boss_spawns[1].x - 120
    if limit < 80 then
      limit = 80
    end
    if base.world and base.world.width and limit > base.world.width - 80 then
      limit = base.world.width - 80
    end
    base.boss_limit_x = limit
  end

  base.platforms = PlatformRandom.build_random_platforms(
    base.world.width,
    base.floor_y,
    base.level_index
  )
  base.background = Backgrounds.phase1_background
  
  return base
end

return Level03
