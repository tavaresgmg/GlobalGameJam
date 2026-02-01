local Final = {}
Final.__index = Final

function Final.new(context, outcome)
  local self = setmetatable({}, Final)
  self.context = context
  self.outcome = outcome
  return self
end

function Final:draw()
  love.graphics.setColor(1, 1, 1)

  local title = self.outcome == "good" and "Final Bom" or "Final Ruim"
  love.graphics.printf(title, 0, 140, self.context.settings.width, "center")

  if self.outcome == "good" then
    love.graphics.printf(
      "Voce libertou o povo e quebrou o ciclo do Coronel.",
      0,
      200,
      self.context.settings.width,
      "center"
    )
  else
    love.graphics.printf(
      "Voce absorveu a mascara do Coronel e virou o novo receptaculo.",
      0,
      200,
      self.context.settings.width,
      "center"
    )
  end

  love.graphics.printf(
    "Pressione Enter para voltar ao menu",
    0,
    260,
    self.context.settings.width,
    "center"
  )
end

function Final:update()
  if self.context.input:pressed("confirm") then
    local Menu = require("scenes.menu")
    self.context.state.switch(Menu.new(self.context))
  end
end

return Final
