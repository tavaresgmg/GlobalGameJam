local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y, config, left_bound, right_bound)
  local self = setmetatable({}, Enemy)
  self.x = x
  self.y = y
  self.w = config.width
  self.h = config.height
  self.vx = config.speed
  self.vy = 0
  self.dir = 1
  self.left_bound = left_bound or x - 60
  self.right_bound = right_bound or x + 60
  self.alive = true
  return self
end

function Enemy:take_hit()
  self.alive = false
end

function Enemy:draw()
  if not self.alive then
    return
  end
  love.graphics.setColor(0.9, 0.3, 0.3)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Enemy
