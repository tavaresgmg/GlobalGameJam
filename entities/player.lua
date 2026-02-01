local anim8 = require("support.anim8")

local function sorted_jump_files(path)
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

local function alpha_bbox(image_data, x0, y0, w, h)
  local min_x, min_y = w, h
  local max_x, max_y = -1, -1
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local _, _, _, a = image_data:getPixel(x0 + x, y0 + y)
      if a > 0 then
        if x < min_x then
          min_x = x
        end
        if y < min_y then
          min_y = y
        end
        if x > max_x then
          max_x = x
        end
        if y > max_y then
          max_y = y
        end
      end
    end
  end
  if max_x < 0 then
    return nil
  end
  return { min_x, min_y, max_x, max_y }
end

local function bbox_height(bbox)
  if not bbox then
    return nil
  end
  return bbox[4] - bbox[2] + 1
end

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

local function build_jump_frames(assets, path, sprite_sheet, frame_w, frame_h)
  if not assets or not assets.sprites or not assets.sprites.player_jump then
    return nil, nil, nil, nil, nil
  end
  local files = sorted_jump_files(path)
  if #files == 0 then
    return nil, nil, nil, nil, nil
  end

  local frames = {}
  local frame_w, frame_h = nil, nil
  for _, filename in ipairs(files) do
    local key = filename:gsub("%.png$", "")
    local image = assets.sprites.player_jump[key]
    if image then
      if not frame_w then
        frame_w, frame_h = image:getWidth(), image:getHeight()
      end
      table.insert(frames, image)
    end
  end

  if #frames == 0 then
    return nil, nil, nil, nil, nil
  end

  local scale_adjust = 1
  local jump_origin_y = nil
  if love and love.image and sprite_sheet and frame_w and frame_h then
    local ok_jump, jump_data = pcall(love.image.newImageData, path .. "/" .. files[1])
    local ok_sheet, sheet_data = pcall(function()
      return sprite_sheet:newImageData()
    end)
    if ok_jump and ok_sheet and jump_data and sheet_data then
      local jump_bbox =
        alpha_bbox(jump_data, 0, 0, jump_data:getWidth(), jump_data:getHeight())
      local sheet_bbox = alpha_bbox(sheet_data, 0, 0, frame_w, frame_h)
      local jump_h = bbox_height(jump_bbox)
      local sheet_h = bbox_height(sheet_bbox)
      if jump_h and sheet_h and jump_h > 0 then
        scale_adjust = sheet_h / jump_h
      end
      if jump_bbox and sheet_bbox then
        local sheet_pad = frame_h - (sheet_bbox[4] + 1)
        local jump_pad = jump_data:getHeight() - (jump_bbox[4] + 1)
        jump_origin_y = jump_data:getHeight() - (jump_pad - sheet_pad)
      end
    end
  end

  return frames, frame_w, frame_h, scale_adjust, jump_origin_y
end

function Player.new(x, y, config, assets, weapons)
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
  self.weapons = weapons or {}
  self.weapon_index = (#self.weapons > 0 and 1) or nil
  self.mode = "offensive"
  self.unmasked = false
  self.max_abilities = config.max_abilities
  self.hurt_timer = 0
  self.invulnerable_timer = 0
  self.flash_timer = 0
  self.sprite, self.anim_run, self.anim_idle, self.sprite_frame_w, self.sprite_frame_h =
    build_animation(assets)
  self.jump_frames, self.jump_frame_w, self.jump_frame_h, self.jump_scale_adjust, self.jump_origin_y =
    build_jump_frames(
      assets,
      "assets/sprites/player_jump",
      self.sprite,
      self.sprite_frame_w,
      self.sprite_frame_h
    )
  self.anim = self.anim_idle or self.anim_run
  self.sprite_scale = nil
  self.jump_scale = nil
  self.sprite_offset_y = config.sprite_offset_y or 0
  if self.sprite then
    self.sprite_scale = config.sprite_scale or (self.h / self.sprite_frame_h)
  end
  if self.sprite_scale and self.jump_frame_h and self.sprite_frame_h then
    local scale_bbox = self.sprite_scale * (self.jump_scale_adjust or 1)
    local scale_size = self.sprite_scale * (self.sprite_frame_h / self.jump_frame_h)
    self.jump_scale = (scale_bbox + scale_size) * 0.5
  end
  self.jump_frame_index = 1
  self.jump_timer = 0
  self.jump_frame_time = 0.06
  self.was_on_ground = true
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
  self.jump_frame_index = 1
  self.jump_timer = 0
  self.was_on_ground = true
end

function Player:set_mode(mode)
  self.mode = mode
end

function Player:unmask()
  self.unmasked = true
  self.mode = "defensive"
end

function Player:attack_box(config, weapon)
  local range = (weapon and weapon.attack_range) or config.attack_range
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

function Player:current_weapon()
  if not self.weapon_index or not self.weapons then
    return nil
  end
  return self.weapons[self.weapon_index]
end

function Player:swap_weapon()
  if not self.weapons or #self.weapons < 2 then
    return false
  end
  if not self.weapon_index then
    self.weapon_index = 1
    return true
  end
  self.weapon_index = (self.weapon_index % #self.weapons) + 1
  return true
end

function Player:draw()
  if self.flash_timer and self.flash_timer > 0 then
    love.graphics.setColor(1, 1, 1)
  else
    love.graphics.setColor(1, 1, 1)
  end

  if self.jump_frames and not self.on_ground then
    local frame = self.jump_frames[self.jump_frame_index]
    local scale = self.jump_scale or self.sprite_scale
    if frame and scale then
      local sx = scale * (self.dir < 0 and -1 or 1)
      local sy = scale
      local origin_x = (self.jump_frame_w or frame:getWidth()) / 2
      local origin_y = self.jump_origin_y or self.jump_frame_h or frame:getHeight()
      love.graphics.draw(
        frame,
        self.x + self.w / 2,
        self.y + self.h + self.sprite_offset_y,
        0,
        sx,
        sy,
        origin_x,
        origin_y
      )
      return
    end
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
  if self.jump_frames and not self.on_ground then
    if self.was_on_ground then
      self.jump_frame_index = 1
      self.jump_timer = 0
    end
    self.jump_timer = self.jump_timer + dt
    if self.jump_timer >= self.jump_frame_time then
      self.jump_timer = self.jump_timer - self.jump_frame_time
      self.jump_frame_index = math.min(self.jump_frame_index + 1, #self.jump_frames)
    end
  else
    self.jump_frame_index = 1
    self.jump_timer = 0
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
  self.was_on_ground = self.on_ground
end

return Player
