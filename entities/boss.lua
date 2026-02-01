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

local function phase_from_health(boss)
  if boss.max_health <= 0 then
    return 1
  end
  local ratio = boss.health / boss.max_health
  if ratio <= boss.phase_3_ratio then
    return 3
  end
  if ratio <= boss.phase_2_ratio then
    return 2
  end
  return 1
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
  self.base_speed = definition.speed or 90
  self.speed = self.base_speed
  self.base_charge_speed = definition.charge_speed or 260
  self.charge_speed = self.base_charge_speed
  self.charge_range = definition.charge_range or 160
  self.base_charge_cooldown = definition.charge_cooldown or 2.0
  self.charge_cooldown = self.base_charge_cooldown
  self.telegraph_time = definition.telegraph_time or 0.35
  self.charge_duration = definition.charge_duration or 0.5
  self.phase_2_ratio = definition.phase_2_ratio or 0.6
  self.phase_3_ratio = definition.phase_3_ratio or 0.3
  self.phase_2_speed_mult = definition.phase_2_speed_mult or 1.1
  self.phase_3_speed_mult = definition.phase_3_speed_mult or 1.2
  self.phase_2_charge_speed_mult = definition.phase_2_charge_speed_mult or 1.1
  self.phase_3_charge_speed_mult = definition.phase_3_charge_speed_mult or 1.2
  self.phase_2_charge_cooldown_mult = definition.phase_2_charge_cooldown_mult or 0.9
  self.phase_3_charge_cooldown_mult = definition.phase_3_charge_cooldown_mult or 0.75
  self.phase_2_agro_mult = definition.phase_2_agro_mult or 1.1
  self.phase_3_agro_mult = definition.phase_3_agro_mult or 1.2
  self.evade_range = definition.evade_range or 80
  self.evade_speed = definition.evade_speed or 180
  self.evade_duration = definition.evade_duration or 0.22
  self.evade_cooldown = definition.evade_cooldown or 1.2
  self.phase_2_evade_cooldown_mult = definition.phase_2_evade_cooldown_mult or 0.9
  self.phase_3_evade_cooldown_mult = definition.phase_3_evade_cooldown_mult or 0.75
  self.charge_timer = 0
  self.charge_cooldown_timer = 0
  self.is_charging = false
  self.is_telegraphing = false
  self.telegraph_timer = 0
  self.evade_timer = 0
  self.evade_cooldown_timer = 0
  self.evade_dir = 0
  self.phase = 1
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

  local phase = phase_from_health(self)
  self.phase = phase

  if self.dir == 0 then
    self.dir = -1
  end

  local speed_mult = 1
  local charge_speed_mult = 1
  local cooldown_mult = 1
  local agro_mult = 1
  local evade_cooldown_mult = 1
  if phase == 2 then
    speed_mult = self.phase_2_speed_mult
    charge_speed_mult = self.phase_2_charge_speed_mult
    cooldown_mult = self.phase_2_charge_cooldown_mult
    agro_mult = self.phase_2_agro_mult
    evade_cooldown_mult = self.phase_2_evade_cooldown_mult
  elseif phase == 3 then
    speed_mult = self.phase_3_speed_mult
    charge_speed_mult = self.phase_3_charge_speed_mult
    cooldown_mult = self.phase_3_charge_cooldown_mult
    agro_mult = self.phase_3_agro_mult
    evade_cooldown_mult = self.phase_3_evade_cooldown_mult
  end

  self.speed = self.base_speed * speed_mult
  self.charge_speed = self.base_charge_speed * charge_speed_mult
  local charge_cooldown = self.base_charge_cooldown * cooldown_mult
  local evade_cooldown = self.evade_cooldown * evade_cooldown_mult
  self.vx = self.speed

  if self.charge_cooldown_timer > 0 then
    self.charge_cooldown_timer = math.max(0, self.charge_cooldown_timer - dt)
  end
  if self.evade_cooldown_timer > 0 then
    self.evade_cooldown_timer = math.max(0, self.evade_cooldown_timer - dt)
  end

  if self.is_telegraphing then
    self.vx = 0
    self.telegraph_timer = self.telegraph_timer - dt
    if self.telegraph_timer <= 0 then
      self.is_telegraphing = false
      self.is_charging = true
      self.charge_timer = self.charge_duration
    end
    return
  end

  if self.evade_timer > 0 then
    self.evade_timer = self.evade_timer - dt
    self.vx = self.evade_speed
    self.dir = self.evade_dir
    return
  end

  if self.is_charging then
    self.charge_timer = self.charge_timer - dt
    if self.charge_timer <= 0 then
      self.is_charging = false
      self.charge_cooldown_timer = charge_cooldown
    end
    return
  end

  local dx = (player.x + player.w / 2) - (self.x + self.w / 2)
  local distance = math.abs(dx)
  local chase_range = (self.agro_range or agro_range or (self.charge_range * 1.6)) * agro_mult
  local leash_range = self.leash_range or (chase_range * 1.8)
  local home_dx = self.home_x - self.x
  local home_distance = math.abs(home_dx)
  local player_attacking = (player.attack_timer and player.attack_timer > 0)
    or (player.attack_cooldown and player.attack_cooldown > 0)

  if
    distance <= chase_range
    and distance <= self.charge_range
    and self.charge_cooldown_timer <= 0
  then
    self.is_telegraphing = true
    self.telegraph_timer = self.telegraph_time
    self.dir = dx >= 0 and 1 or -1
    return
  end

  if
    player_attacking
    and distance <= self.evade_range
    and self.evade_cooldown_timer <= 0
    and home_distance <= leash_range
  then
    self.evade_cooldown_timer = evade_cooldown
    self.evade_timer = self.evade_duration
    self.evade_dir = dx >= 0 and -1 or 1
    return
  end

  if distance <= chase_range then
    local preferred = self.charge_range * 0.75
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

  if self.is_telegraphing then
    love.graphics.setColor(1, 0.55, 0.2)
  elseif self.is_charging then
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
