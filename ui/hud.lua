local Hud = {}
Hud.__index = Hud

function Hud.new()
  local self = setmetatable({}, Hud)
  return self
end

function Hud:draw(player)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("HP: " .. tostring(player.health), 16, 16)
  love.graphics.print("Move: A/D or Arrows  Jump: Space  Attack: J/K/X", 16, 36)
end

return Hud
