local Base = require("data.levels.base")

local Level01 = {}

function Level01.build(settings, constants)
  return Base.build(settings, constants, 1)
end

return Level01
