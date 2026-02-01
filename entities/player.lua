local anim8 = require("support.anim8")

local Player = {}
Player.__index = Player

local function build_animation(assets)
  if not assets or not assets.sprites or not assets.sprites.player then
    return nil, nil
  end
  local sprite = assets.sprites.player.player_sheet
  if not sprite then
    return nil, nil
  end
  local columns, rows = 8, 6
  local frame_w = sprite:getWidth() / columns
  local frame_h = sprite:getHeight() / rows
  local grid = anim8.newGrid(frame_w, frame_h, sprite:getWidth(), sprite:getHeight())
  local frames = grid("1-8", 1, "1-8", 2, "1-8", 3, "1-8", 4, "1-8", 5, "1-8", 6)
  local run = anim8.newAnimation(frames, 0.06)
  local idle = anim8.newAnimation(grid(1, 1), 1)
  return sprite, run, idle, frame_w, frame_h
end

function Player.new(x, y, config, assets)
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
  self.sprite, self.anim_run, self.anim_idle, self.sprite_frame_w, self.sprite_frame_h =
    build_animation(assets)
  self.anim = self.anim_idle or self.anim_run
  self.sprite_scale = nil
  self.sprite_offset_y = config.sprite_offset_y or 0
  if self.sprite then
    self.sprite_scale = config.sprite_scale or (self.h / self.sprite_frame_h)
  end
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
  else
    love.graphics.setColor(1, 1, 1)
  end

  if self.sprite and self.anim and self.sprite_scale then
    local sx = self.sprite_scale * (self.dir < 0 and -1 or 1)
    local sy = self.sprite_scale
    local origin_x = self.sprite_frame_w / 2
    local origin_y = self.sprite_frame_h
    self.anim:draw(
      self.sprite,
      self.x + self.w / 2,
      self.y + self.h + self.sprite_offset_y,
      0,
      sx,
      sy,
      origin_x,
      origin_y
    )
  else
    if self.mode == "offensive" then
      love.graphics.setColor(0.2, 0.7, 0.9)
    else
      love.graphics.setColor(0.4, 0.9, 0.6)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
  end
end

function Player:update_animation(dt)
  if self.anim_run then
    local moving = math.abs(self.vx) > 1 or not self.on_ground
    local next_anim = moving and self.anim_run or self.anim_idle
    if next_anim and self.anim ~= next_anim then
      self.anim = next_anim
      self.anim:gotoFrame(1)
    end
    if self.anim then
      self.anim:update(dt)
    end
  end
end

return Player
