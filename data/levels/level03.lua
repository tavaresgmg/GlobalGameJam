local Base = require("data.levels.base")

local Level03 = {}

local scale = 0.4

local function add_platform_L(platforms, x, y)
  table.insert(platforms, {
    x = x + 87 * scale, y = y,
    w = 261 * scale, h = 190 * scale,
    sprite = "platform_01", sprite_scale = scale,
    sprite_offset_x = -87 * scale, sprite_offset_y = 0,
  })
  table.insert(platforms, {
    x = x, y = y + 190 * scale,
    w = 174 * scale, h = 189 * scale,
  })
end

local function add_platform(platforms, x, y, sprite)
  if sprite == "platform_02" then
    table.insert(platforms, {
      x = x, y = y + 50 * scale,
      w = 237 * scale, h = 80 * scale,
      sprite = sprite, sprite_scale = scale,
      sprite_offset_x = 0, sprite_offset_y = -50 * scale,
    })
  elseif sprite == "platform_03" then
    table.insert(platforms, {
      x = x, y = y,
      w = 326 * scale, h = 463 * scale,
      sprite = sprite, sprite_scale = scale,
    })
  elseif sprite == "platform_04" then
    table.insert(platforms, {
      x = x, y = y + 30 * scale,
      w = 524 * scale, h = 70 * scale,
      sprite = sprite, sprite_scale = scale,
      sprite_offset_x = 0, sprite_offset_y = -30 * scale,
    })
  end
end

function Level03.build(settings, constants)
  local base = Base.build(settings, constants, 3)
  
  local new_platforms = {
    base.platforms[1],
  }
  
  add_platform(new_platforms, 250, 200, "platform_04")
  add_platform(new_platforms, 650, 160, "platform_02")
  add_platform_L(new_platforms, 1000, 180)
  add_platform(new_platforms, 1400, 190, "platform_04")
  add_platform(new_platforms, 1800, 150, "platform_02")
  add_platform_L(new_platforms, 2200, 200)
  add_platform(new_platforms, 2600, 170, "platform_04")
  add_platform(new_platforms, 3000, 210, "platform_02")
  
  base.platforms = new_platforms
  
  base.enemy_spawns = {
    { kind = "grunt", x = 200, left = 150, right = 350, speed_mult = 1.0 },
    { kind = "rusher", x = 450, left = 350, right = 550, speed_mult = 1.2 },
    { kind = "grunt", x = 750, left = 650, right = 850, speed_mult = 0.9 },
    { kind = "rusher", x = 1050, left = 950, right = 1150, speed_mult = 1.15 },
    { kind = "grunt", x = 1350, left = 1250, right = 1450, speed_mult = 1.0 },
    { kind = "rusher", x = 1650, left = 1550, right = 1750, speed_mult = 1.2 },
    { kind = "grunt", x = 1950, left = 1850, right = 2050, speed_mult = 0.95 },
    { kind = "rusher", x = 2200, left = 2100, right = 2300, speed_mult = 1.1 },
  }
  
  -- Mini boss no final da fase
  base.boss_spawns = {
    { boss_index = 2, x = 3600 },  -- Capanga da Noite
  }
  
  -- Segments: matar todos inimigos, depois o boss
  base.segments = {
    {
      start_x = 0,
      gate_x = 3300,
      locked = true,
      enemy_ids = { 1, 2, 3, 4, 5, 6, 7, 8 },
      boss_ids = {},
    },
    {
      start_x = 3300,
      gate_x = 4000,
      locked = true,
      enemy_ids = {},
      boss_ids = { 1 },
    },
  }

  local last_gate_x = base.segments[#base.segments] and base.segments[#base.segments].gate_x
  if last_gate_x then
    base.world.width = last_gate_x
    if base.platforms[1] then
      base.platforms[1].w = last_gate_x
    end
  end

  base.boss_limit_x = nil
  if base.boss_spawns and #base.boss_spawns > 0 then
    local limit = base.boss_spawns[1].x - 120
    if limit < 80 then
      limit = 80
    end
    if base.world and base.world.width and limit > base.world.width - 80 then
      limit = base.world.width - 80
    end
    base.boss_limit_x = limit
  end
  
  return base
end

return Level03
