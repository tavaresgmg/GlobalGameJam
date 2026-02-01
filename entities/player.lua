local Player = {}
Player.__index = Player

function Player.new(x, y, config)
  local self = setmetatable({}, Player)
  self.x = x
  self.y = y
  self.w = config.width
  self.h = config.height
  self.tag = "player"
  self.is_player = true
  self.is_trigger = false
  self.in_world = false
  self.vx = 0
  self.vy = 0
  self.speed = config.speed
  self.jump_speed = config.jump_speed
  self.max_jumps = config.max_jumps or 1
  self.jump_count = 0
  self.coyote_time = config.coyote_time or 0
  self.jump_buffer_time = config.jump_buffer_time or 0
  self.coyote_timer = 0
  self.jump_buffer_timer = 0
  self.dash_speed = config.dash_speed
  self.dash_duration = config.dash_duration
  self.dash_cooldown = config.dash_cooldown
  self.dash_timer = 0
  self.dash_cooldown_timer = 0
  self.is_dashing = false
  self.on_ground = false
  self.dir = 1
  self.base_max_health = config.max_health
  self.max_health = config.max_health
  self.health = config.max_health
  self.base_attack = config.attack_damage
  self.attack_timer = 0
  self.attack_cooldown = 0
  self.attack_hits = {}
  self.mode = "offensive"
  self.unmasked = false
  self.max_abilities = config.max_abilities
  self.hurt_timer = 0
  self.invulnerable_timer = 0
  self.flash_timer = 0
  return self
end

function Player:reset(x, y)
  self.x = x
  self.y = y
  self.vx = 0
  self.vy = 0
  self.on_ground = false
  self.jump_count = 0
  self.coyote_timer = 0
  self.jump_buffer_timer = 0
  self.attack_timer = 0
  self.attack_cooldown = 0
  self.attack_hits = {}
  self.dash_timer = 0
  self.dash_cooldown_timer = 0
  self.is_dashing = false
  self.hurt_timer = 0
  self.invulnerable_timer = 0
  self.flash_timer = 0
end

function Player:set_mode(mode)
  self.mode = mode
end

function Player:unmask()
  self.unmasked = true
  self.mode = "defensive"
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
  if self.flash_timer and self.flash_timer > 0 then
    love.graphics.setColor(1, 1, 1)
  elseif self.mode == "offensive" then
    love.graphics.setColor(0.2, 0.7, 0.9)
  else
    love.graphics.setColor(0.4, 0.9, 0.6)
  end
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Player
