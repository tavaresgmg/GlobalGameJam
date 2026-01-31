local Math = require("support.math")

local Camera = {}
Camera.__index = Camera

function Camera.new(width, height)
  local self = setmetatable({}, Camera)
  self.x = 0
  self.y = 0
  self.w = width
  self.h = height
  return self
end

function Camera:set_position(x, y)
  self.x = x or self.x
  self.y = y or self.y
end

function Camera:follow(target, world_width, world_height)
  local target_x = target.x + target.w / 2 - self.w / 2
  local target_y = target.y + target.h / 2 - self.h / 2

  local max_x = math.max(0, world_width - self.w)
  local max_y = math.max(0, world_height - self.h)

  self.x = Math.clamp(target_x, 0, max_x)
  self.y = Math.clamp(target_y, 0, max_y)
end

function Camera:attach()
  love.graphics.push()
  love.graphics.translate(-math.floor(self.x), -math.floor(self.y))
end

function Camera:detach()
  love.graphics.pop()
end

return Camera
