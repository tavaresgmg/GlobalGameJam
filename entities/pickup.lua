local Pickup = {}
Pickup.__index = Pickup

function Pickup.new(x, y, amount)
  local self = setmetatable({}, Pickup)
  self.x = x
  self.y = y
  self.w = 16
  self.h = 16
  self.tag = "pickup"
  self.is_trigger = true
  self.in_world = false
  self.amount = amount
  self.collected = false
  return self
end

function Pickup:draw()
  if self.collected then
    return
  end
  love.graphics.setColor(0.2, 1, 0.2)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Pickup
