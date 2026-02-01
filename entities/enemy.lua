local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y, config, left_bound, right_bound)
  local self = setmetatable({}, Enemy)
  self.x = x
  self.y = y
  self.w = config.width
  self.h = config.height
  self.tag = "enemy"
  self.is_enemy = true
  self.is_target = true
  self.is_trigger = false
  self.base_speed = config.speed
  self.vx = config.speed
  self.vy = 0
  self.dir = 0
  self.left_bound = left_bound
  self.right_bound = right_bound
  self.health = config.health
  self.max_health = config.health
  self.damage = config.damage
  self.agro_range = config.agro_range
  self.attack_range = config.attack_range
  self.attack_windup = config.attack_windup
  self.attack_duration = config.attack_duration
  self.attack_cooldown = config.attack_cooldown
  self.call_range = config.call_range
  self.standoff_range = config.standoff_range
  self.standoff_buffer = config.standoff_buffer
  self.attack_priority = config.attack_priority or 0
  self.force_attacker = config.force_attacker or false
  self.sprint_range = config.sprint_range
  self.sprint_mult = config.sprint_mult or 1
  self.evade_range = config.evade_range
  self.evade_duration = config.evade_duration
  self.evade_cooldown = config.evade_cooldown
  self.evade_timer = 0
  self.evade_cooldown_timer = 0
  self.attack_lock_time = config.attack_lock_time or 0.8
  self.attack_lock_timer = 0
  self.flank_offset = config.flank_offset
  self.flank_tolerance = config.flank_tolerance
  self.flank_switch_time = config.flank_switch_time
  self.flank_switch_chance = config.flank_switch_chance
  self.flank_timer = 0
  self.flank_side = nil
  self.alive = true
  self.active = false
  self.state = "idle"
  self.state_timer = 0
  self.attack_timer = 0
  self.cooldown_timer = 0
  self.attack_active = false
  self.standoff_timer = 0
  self.standoff_dir = 1
  self.is_attacker = false
  self.origin_x = x
  self.chase_only = true
  self.flash_timer = 0
  self.in_world = false
  return self
end

function Enemy:take_hit(damage, mode)
  if not self.alive then
    return false
  end

  self.health = self.health - damage
  if self.health <= 0 then
    self.alive = false
    if mode == "offensive" then
      self.state = "absorbed"
    else
      self.state = "freed"
    end
    return true
  end

  return false
end

function Enemy:draw()
  if not self.alive then
    return
  end

  if self.flash_timer and self.flash_timer > 0 then
    love.graphics.setColor(1, 1, 1)
  elseif self.active then
    love.graphics.setColor(0.9, 0.3, 0.3)
  else
    love.graphics.setColor(0.6, 0.4, 0.3)
  end
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Enemy
