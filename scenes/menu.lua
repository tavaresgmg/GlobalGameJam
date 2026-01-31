local Scene = require("core.scene")
local Level01 = require("scenes.level01")

local Menu = setmetatable({}, { __index = Scene })
Menu.__index = Menu

function Menu.new(context)
  local self = setmetatable(Scene.new(), Menu)
  self.context = context
  return self
end

function Menu:draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf("Jogo Jam", 0, 160, self.context.settings.width, "center")
  love.graphics.printf("Press Enter to Start", 0, 220, self.context.settings.width, "center")
  love.graphics.printf("Esc to Quit", 0, 250, self.context.settings.width, "center")
end

function Menu:keypressed(key)
  if key == "return" or key == "kpenter" then
    self.context.state:switch(Level01.new(self.context))
  elseif key == "escape" then
    love.event.quit()
  end
end

return Menu
