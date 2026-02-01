local Base = require("data.levels.base")

local Level01 = {}

function Level01.build(settings, constants)
  local base = Base.build(settings, constants, 1)
  base.platforms = {
    base.platforms[1],
  }
  for _, spawn in ipairs(base.enemy_spawns or {}) do
    spawn.platform = nil
  end

  base.background = {
    bucket = "level01",
    layers = {
      { key = "level01_layer01", speed = 0.2 },
      { key = "level01_layer02", speed = 0.4 },
    },
    ground = { key = "level01_ground" },
  }
  return base
end

return Level01
