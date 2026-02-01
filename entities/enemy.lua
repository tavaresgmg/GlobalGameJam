local Enemy = {}
Enemy.__index = Enemy

local function sorted_enemy_files(path)
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

local function build_enemy_frames(assets, folder_key, path)
  if not assets or not assets.sprites or not assets.sprites[folder_key] then
    return nil, nil, nil
  end
  local files = sorted_enemy_files(path)
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

function Enemy.new(x, y, config, left_bound, right_bound, assets)
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
  self.face_dir = 1
  self.face_lock_distance = config.face_lock_distance or 6
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
  self.anim_frame_time = config.anim_frame_time or 0.08
  self.sprite_scale_mult = config.sprite_scale_mult or 1
  self.sprite_flip = config.sprite_flip or false
  self.anim_timer = 0
  self.anim_frame_index = 1
  self.anim_state = "idle"
  self.anim_walk_frames, self.anim_walk_w, self.anim_walk_h =
    build_enemy_frames(assets, "minion_walk", "assets/sprites/minion_walk")
  self.anim_attack_frames, self.anim_attack_w, self.anim_attack_h =
    build_enemy_frames(assets, "minion_attack", "assets/sprites/minion_attack")
  local ref_h = self.anim_walk_h or self.anim_attack_h
  if ref_h then
    self.sprite_scale = (self.h / ref_h) * self.sprite_scale_mult
  end
  if config.sprite_offset_y then
    self.sprite_offset_y = config.sprite_offset_y
  elseif config.sprite_margin_bottom and self.sprite_scale then
    self.sprite_offset_y = config.sprite_margin_bottom * self.sprite_scale
  else
    self.sprite_offset_y = 0
  end
  return self
end

function Enemy:update_animation(dt)
  if not self.alive then
    return
  end
  local state = "idle"
  local moving = math.abs(self.vx or 0) > 1 and self.dir ~= 0
  if self.state == "attack" or self.attack_active then
    state = "attack"
  elseif moving and self.active then
    state = "walk"
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

  local frame
  if self.anim_state == "attack" then
    frame = self.anim_attack_frames and self.anim_attack_frames[self.anim_frame_index]
  elseif self.anim_state == "walk" then
    frame = self.anim_walk_frames and self.anim_walk_frames[self.anim_frame_index]
  else
    frame = self.anim_walk_frames and self.anim_walk_frames[1]
  end

  if frame and self.sprite_scale then
    love.graphics.setColor(1, 1, 1)
    local flip = self.sprite_flip and -1 or 1
    local face = self.face_dir or self.dir
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
    if self.flash_timer and self.flash_timer > 0 then
      love.graphics.setColor(1, 1, 1)
    elseif self.active then
      love.graphics.setColor(0.9, 0.3, 0.3)
    else
      love.graphics.setColor(0.6, 0.4, 0.3)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
  end
end

return Enemy
