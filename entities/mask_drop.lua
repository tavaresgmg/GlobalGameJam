local MaskDrop = {}
MaskDrop.__index = MaskDrop

function MaskDrop.new(x, y, ability_id)
  local self = setmetatable({}, MaskDrop)
  self.x = x
  self.y = y
  self.w = 18
  self.h = 18
  self.tag = "mask_drop"
  self.is_trigger = true
  self.in_world = false
  self.ability_id = ability_id
  self.collected = false
  return self
end

function MaskDrop:draw()
  if self.collected then
    return
  end
  love.graphics.setColor(0.9, 0.9, 0.2)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return MaskDrop
