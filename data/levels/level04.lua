local Base = require("data.levels.base")
local Backgrounds = require("data.levels.backgrounds")
local PlatformRandom = require("data.levels.platform_random")

local Level04 = {}

function Level04.build(settings, constants)
  local base = Base.build(settings, constants, 4)

  base.enemy_spawns = {
    { kind = "grunt", x = 250, left = 150, right = 350, speed_mult = 1.0 },
    { kind = "rusher", x = 500, left = 400, right = 600, speed_mult = 1.25 },
    { kind = "grunt", x = 800, left = 700, right = 900, speed_mult = 0.95 },
    { kind = "rusher", x = 1100, left = 1000, right = 1200, speed_mult = 1.2 },
    { kind = "grunt", x = 1400, left = 1300, right = 1500, speed_mult = 1.0 },
    { kind = "rusher", x = 1700, left = 1600, right = 1800, speed_mult = 1.15 },
    { kind = "grunt", x = 2000, left = 1900, right = 2100, speed_mult = 1.0 },
    { kind = "rusher", x = 2250, left = 2150, right = 2350, speed_mult = 1.2 },
  }
  
  -- Mini boss no final da fase
  base.boss_spawns = {
    { boss_index = 1, x = 3700 },  -- Capanga do Ferro
  }
  
  -- Segments: matar todos inimigos, depois o boss
  base.segments = {
    {
      start_x = 0,
      gate_x = 3400,
      locked = true,
      enemy_ids = { 1, 2, 3, 4, 5, 6, 7, 8 },
      boss_ids = {},
    },
    {
      start_x = 3400,
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

return Level04
