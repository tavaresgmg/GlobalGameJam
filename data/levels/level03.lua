local Base = require("data.levels.base")

local Level03 = {}

function Level03.build(settings, constants)
  return Base.build(settings, constants, 3)
end

return Level03
