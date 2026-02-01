local Boss = {}
Boss.__index = Boss

local function sorted_boss_files(path)
  if not love or not love.filesystem then
    return {}
  end
  local files = {}
  for _, name in ipairs(love.filesystem.getDirectoryItems(path)) do
    if name:match("%.png$") then
      table.insert(files, name)
    end
  end
  table.sort(files)
  return files
end

local function build_boss_frames(assets, folder_key, path)
  if not folder_key or not assets or not assets.sprites or not assets.sprites[folder_key] then
    return nil, nil, nil
  end
  local files = sorted_boss_files(path)
  if #files == 0 then
    return nil, nil, nil
  end
  local frames = {}
  local frame_w, frame_h = nil, nil
  local bucket = assets.sprites[folder_key]
  for _, filename in ipairs(files) do
    local key = filename:gsub("%.png$", "")
    local image = bucket[key]
    if image then
      if not frame_w then
        frame_w, frame_h = image:getWidth(), image:getHeight()
      end
      table.insert(frames, image)
    end
  end
  if #frames == 0 then
    return nil, nil, nil
  end
  return frames, frame_w, frame_h
end

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

function Boss.new(definition, x, y, width, height, assets)
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
  self.attack_anim_timer = 0
  self.evade_timer = 0
  self.evade_cooldown_timer = 0
  self.evade_dir = 0
  self.phase = 1
  self.home_x = x
  self.home_y = y
  self.leash_range = definition.leash_range
  self.agro_range = definition.agro_range
  self.is_chasing = false
  self.chase_enter_margin = 0.9
  self.chase_exit_margin = 1.1
  self.flash_timer = 0
  self.anim_frame_time = definition.anim_frame_time or 0.08
  self.sprite_scale_mult = definition.sprite_scale_mult or 1
  self.sprite_flip = definition.sprite_flip or false
  self.anim_timer = 0
  self.anim_frame_index = 1
  self.anim_state = "idle"
  local walk_folder = definition.sprite_walk_folder
  local attack_folder = definition.sprite_attack_folder
  self.anim_walk_frames, self.anim_walk_w, self.anim_walk_h =
    build_boss_frames(assets, walk_folder, "assets/sprites/" .. (walk_folder or ""))
  self.anim_attack_frames, self.anim_attack_w, self.anim_attack_h =
    build_boss_frames(assets, attack_folder, "assets/sprites/" .. (attack_folder or ""))
  local ref_h = self.anim_walk_h or self.anim_attack_h
  if ref_h then
    self.sprite_scale = (self.h / ref_h) * self.sprite_scale_mult
  end
  if definition.sprite_offset_y then
    self.sprite_offset_y = definition.sprite_offset_y
  elseif definition.sprite_margin_bottom and self.sprite_scale then
    self.sprite_offset_y = definition.sprite_margin_bottom * self.sprite_scale
  else
    self.sprite_offset_y = 0
  end
  return self
end

function Boss:update_behavior(player, dt, agro_range)
  if not self.alive then
    return
  end

  local phase = phase_from_health(self)
  self.phase = phase

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
    self.attack_anim_timer = self.telegraph_time + self.charge_duration
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

  local chase_enter = chase_range * self.chase_enter_margin
  local chase_exit = chase_range * self.chase_exit_margin

  -- Prioridade 1: Se muito longe de home, força retorno e cancela chase
  if home_distance > leash_range then
    self.is_chasing = false
    self.dir = home_dx >= 0 and 1 or -1
    return
  end

  -- Atualiza estado de chase com histerese
  if self.is_chasing then
    if distance > chase_exit then
      self.is_chasing = false
    end
  else
    if distance <= chase_enter then
      self.is_chasing = true
    end
  end

  if self.is_chasing then
    self.dir = dx >= 0 and 1 or -1
  else
    -- Não está perseguindo: fica parado
    self.vx = 0
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

function Boss:update_animation(dt)
  if not self.alive then
    return
  end
  if self.attack_anim_timer and self.attack_anim_timer > 0 then
    self.attack_anim_timer = math.max(0, self.attack_anim_timer - dt)
  end
  local state = "idle"
  local moving = math.abs(self.vx or 0) > 1 and self.dir ~= 0
  local attacking = (self.attack_anim_timer and self.attack_anim_timer > 0)
    or self.is_telegraphing
    or self.is_charging
  if attacking then
    state = "attack"
  elseif moving and self.active then
    state = "walk"
  end

  if state == "attack" and (not self.anim_attack_frames or #self.anim_attack_frames == 0) then
    state = moving and "walk" or "idle"
  end

  if state ~= self.anim_state then
    self.anim_state = state
    self.anim_frame_index = 1
    self.anim_timer = 0
  end

  if state == "idle" then
    self.anim_frame_index = 1
    self.anim_timer = 0
  end

  local frames = nil
  if state == "attack" then
    frames = self.anim_attack_frames
  elseif state == "walk" or state == "idle" then
    frames = self.anim_walk_frames
  end
  if not frames or #frames == 0 then
    return
  end

  self.anim_timer = self.anim_timer + dt
  if self.anim_timer >= self.anim_frame_time then
    self.anim_timer = self.anim_timer - self.anim_frame_time
    self.anim_frame_index = self.anim_frame_index + 1
    if self.anim_frame_index > #frames then
      self.anim_frame_index = 1
    end
  end
end

function Boss:draw()
  if not self.alive then
    return
  end

  local frame
  if self.anim_state == "attack" then
    frame = self.anim_attack_frames and self.anim_attack_frames[self.anim_frame_index]
  elseif self.anim_state == "walk" then
    frame = self.anim_walk_frames and self.anim_walk_frames[self.anim_frame_index]
  else
    frame = self.anim_walk_frames and self.anim_walk_frames[1]
  end

  love.graphics.setColor(1, 1, 1)
  if frame and self.sprite_scale then
    local flip = self.sprite_flip and -1 or 1
    local face = self.dir
    local sx = self.sprite_scale * (face < 0 and -1 or 1) * flip
    local sy = self.sprite_scale
    local origin_x = (self.anim_walk_w or self.anim_attack_w or frame:getWidth()) / 2
    local origin_y = (self.anim_walk_h or self.anim_attack_h or frame:getHeight())
    love.graphics.draw(
      frame,
      self.x + self.w / 2,
      self.y + self.h + (self.sprite_offset_y or 0),
      0,
      sx,
      sy,
      origin_x,
      origin_y
    )
  else
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
  end

  local frame_h = self.anim_walk_h or self.anim_attack_h or self.h
  local scale = self.sprite_scale or 1
  local offset_y = self.sprite_offset_y or 0
  local sprite_top = self.y + self.h + offset_y - (frame_h * scale)
  
  local bar_y = sprite_top + 90
  local bar_w = self.w
  local bar_x = self.x + self.w / 2 - bar_w / 2
  draw_bar(bar_x, bar_y, bar_w, 4, self.health, self.max_health, { 0.9, 0.2, 0.6 })

  love.graphics.setColor(1, 1, 1)
  local font = love.graphics.getFont()
  local text_w = font:getWidth(self.name)
  local text_x = self.x + self.w / 2 - text_w / 2
  love.graphics.print(self.name, text_x, bar_y - 16)
end

return Boss
