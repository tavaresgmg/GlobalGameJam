local Boss = {}
Boss.__index = Boss

local function draw_bar(x, y, width, height, value, max, color)
  if max <= 0 then
    return
  end
  local ratio = math.max(0, math.min(1, value / max))
  love.graphics.setColor(0.12, 0.12, 0.12)
  love.graphics.rectangle("fill", x, y, width, height)
  love.graphics.setColor(color[1], color[2], color[3])
  love.graphics.rectangle("fill", x, y, width * ratio, height)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("line", x, y, width, height)
end

function Boss.new(definition, x, y, width, height)
  local self = setmetatable({}, Boss)
  self.id = definition.id
  self.name = definition.name
  self.x = x
  self.y = y
  self.w = width
  self.h = height
  self.tag = "boss"
  self.is_boss = true
  self.is_target = true
  self.is_trigger = false
  self.in_world = false
  self.vx = definition.speed or 90
  self.vy = 0
  self.dir = -1
  self.health = definition.max_health
  self.max_health = definition.max_health
  self.damage = definition.damage
  self.reward_offensive = definition.reward_offensive
  self.reward_defensive = definition.reward_defensive
  self.is_final = definition.is_final or false
  self.alive = true
  self.active = true
  self.always_active = true
  self.state = "masked"
  self.reward_granted = false
  self.speed = definition.speed or 90
  self.charge_speed = definition.charge_speed or 260
  self.charge_range = definition.charge_range or 160
  self.charge_cooldown = definition.charge_cooldown or 2.0
  self.charge_timer = 0
  self.charge_cooldown_timer = 0
  self.is_charging = false
  self.home_x = x
  self.home_y = y
  self.leash_range = definition.leash_range
  self.agro_range = definition.agro_range
  self.flash_timer = 0
  return self
end

function Boss:update_behavior(player, dt, agro_range)
  if not self.alive then
    return
  end

  if self.dir == 0 then
    self.dir = -1
  end
  self.vx = self.speed

  if self.charge_cooldown_timer > 0 then
    self.charge_cooldown_timer = math.max(0, self.charge_cooldown_timer - dt)
  end

  if self.is_charging then
    self.charge_timer = self.charge_timer - dt
    if self.charge_timer <= 0 then
      self.is_charging = false
      self.charge_cooldown_timer = self.charge_cooldown
    end
    return
  end

  local dx = (player.x + player.w / 2) - (self.x + self.w / 2)
  local distance = math.abs(dx)
  local chase_range = self.agro_range or agro_range or (self.charge_range * 1.6)
  local leash_range = self.leash_range or (chase_range * 1.8)
  local home_dx = self.home_x - self.x
  local home_distance = math.abs(home_dx)

  if
    distance <= chase_range
    and distance <= self.charge_range
    and self.charge_cooldown_timer <= 0
  then
    self.is_charging = true
    self.charge_timer = 0.5
    self.dir = dx >= 0 and 1 or -1
    return
  end

  if distance <= chase_range then
    local preferred = self.charge_range * 0.75
    local player_attacking = (player.attack_timer and player.attack_timer > 0)
      or (player.attack_cooldown and player.attack_cooldown > 0)
    if distance < preferred and not player_attacking then
      self.dir = dx >= 0 and -1 or 1
    else
      self.dir = dx >= 0 and 1 or -1
    end
  else
    if home_distance > 6 then
      self.dir = home_dx >= 0 and 1 or -1
    else
      self.dir = 0
    end
  end

  if home_distance > leash_range then
    self.dir = home_dx >= 0 and 1 or -1
  end
end

function Boss:take_hit(damage, mode)
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

function Boss:draw()
  if not self.alive then
    return
  end

  if self.is_charging then
    love.graphics.setColor(1, 0.3, 0.6)
  elseif self.flash_timer and self.flash_timer > 0 then
    love.graphics.setColor(1, 1, 1)
  else
    love.graphics.setColor(0.7, 0.2, 0.6)
  end
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

  local bar_y = self.y - 10
  draw_bar(self.x, bar_y, self.w, 4, self.health, self.max_health, { 0.9, 0.2, 0.6 })

  love.graphics.setColor(1, 1, 1)
  love.graphics.print(self.name, self.x, self.y - 24)
end

return Boss
