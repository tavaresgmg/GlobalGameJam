local Base = require("data.levels.base")
local Backgrounds = require("data.levels.backgrounds")
local PlatformRandom = require("data.levels.platform_random")

local Level01 = {}

function Level01.build(settings, constants)
  local base = Base.build(settings, constants, 1)
  base.platforms = PlatformRandom.build_random_platforms(
    base.world.width,
    base.floor_y,
    base.level_index
  )
  for _, spawn in ipairs(base.enemy_spawns or {}) do
    spawn.platform = nil
  end

  base.background = Backgrounds.phase1_background

  return base
end

return Level01
