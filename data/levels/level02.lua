local Base = require("data.levels.base")

local Level02 = {}

function Level02.build(settings, constants)
  return Base.build(settings, constants, 2)
end

return Level02
