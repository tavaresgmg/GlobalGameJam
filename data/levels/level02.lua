local Base = require("data.levels.base")
local Backgrounds = require("data.levels.backgrounds")
local PlatformRandom = require("data.levels.platform_random")

local Level02 = {}

function Level02.build(settings, constants)
  local base = Base.build(settings, constants, 2)

  -- Inimigos no chão (posições antes da escala 2x)
  base.enemy_spawns = {
    { kind = "grunt", x = 200, left = 150, right = 300, speed_mult = 0.9 },
    { kind = "rusher", x = 400, left = 350, right = 500, speed_mult = 1.1 },
    { kind = "grunt", x = 700, left = 600, right = 800, speed_mult = 1.0 },
    { kind = "rusher", x = 1000, left = 900, right = 1100, speed_mult = 1.2 },
    { kind = "grunt", x = 1300, left = 1200, right = 1400, speed_mult = 0.9 },
    { kind = "rusher", x = 1600, left = 1500, right = 1700, speed_mult = 1.15 },
    { kind = "grunt", x = 1900, left = 1800, right = 2000, speed_mult = 1.0 },
    { kind = "rusher", x = 2100, left = 2000, right = 2200, speed_mult = 1.1 },
  }

  base.unmask_trigger = nil

  -- Mini boss no final da fase
  base.boss_spawns = {
    { boss_index = 1, x = 3500 },  -- Capanga do Ferro
  }
  
  -- Segments: matar todos inimigos, depois o boss
  base.segments = {
    {
      start_x = 0,
      gate_x = 3200,
      locked = true,
      enemy_ids = { 1, 2, 3, 4, 5, 6, 7, 8 },
      boss_ids = {},
    },
    {
      start_x = 3200,
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

return Level02
