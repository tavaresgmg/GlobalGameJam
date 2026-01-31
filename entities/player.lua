local Player = {}
Player.__index = Player

function Player.new(x, y, config)
  local self = setmetatable({}, Player)
  self.x = x
  self.y = y
  self.w = config.width
  self.h = config.height
  self.vx = 0
  self.vy = 0
  self.speed = config.speed
  self.jump_speed = config.jump_speed
  self.on_ground = false
  self.dir = 1
  self.health = config.max_health
  self.attack_timer = 0
  self.attack_cooldown = 0
  return self
end

function Player:reset(x, y)
  self.x = x
  self.y = y
  self.vx = 0
  self.vy = 0
  self.on_ground = false
  self.attack_timer = 0
  self.attack_cooldown = 0
end

function Player:attack_box(config)
  local range = config.attack_range
  local height = config.attack_height
  local width = range

  local box_x = self.x + (self.dir > 0 and self.w or -width)
  local box_y = self.y + (self.h - height) / 2

  return {
    x = box_x,
    y = box_y,
    w = width,
    h = height,
  }
end

function Player:draw()
  love.graphics.setColor(0.2, 0.7, 0.9)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Player
