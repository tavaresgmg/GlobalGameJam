local Base = require("data.levels.base")

local Level02 = {}

local scale = 0.4

-- platform_01 em L precisa de 2 hitboxes
-- Parte superior: x=87 a 348, y=0 a 190
-- Parte inferior esquerda: x=0 a 174, y=190 a 379
local function add_platform_L(platforms, x, y)
  -- Parte superior (horizontal)
  table.insert(platforms, {
    x = x + 87 * scale,
    y = y,
    w = 261 * scale,
    h = 190 * scale,
    sprite = "platform_01",
    sprite_scale = scale,
    sprite_offset_x = -87 * scale,
    sprite_offset_y = 0,
  })
  -- Parte inferior (vertical) - sem sprite, só hitbox
  table.insert(platforms, {
    x = x,
    y = y + 190 * scale,
    w = 174 * scale,
    h = 189 * scale,
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

function Level02.build(settings, constants)
  local base = Base.build(settings, constants, 2)
  
  local new_platforms = {
    base.platforms[1],
  }
  
  -- Plataformas mais baixas
  add_platform(new_platforms, 200, 180, "platform_02")
  add_platform(new_platforms, 500, 220, "platform_04")
  add_platform_L(new_platforms, 900, 150)
  add_platform(new_platforms, 1300, 200, "platform_03")
  add_platform(new_platforms, 1700, 170, "platform_02")
  add_platform(new_platforms, 2100, 220, "platform_04")
  add_platform_L(new_platforms, 2500, 180)
  add_platform(new_platforms, 2900, 200, "platform_02")
  
  base.platforms = new_platforms
  
  -- Inimigos no chão (posições antes da escala 2x)
  base.enemy_spawns = {
    { kind = "grunt", x = 200, left = 150, right = 300, speed_mult = 0.9 },
    { kind = "rusher", x = 400, left = 350, right = 500, speed_mult = 1.1 },
    { kind = "grunt", x = 700, left = 600, right = 800, speed_mult = 1.0 },
    { kind = "rusher", x = 1000, left = 900, right = 1100, speed_mult = 1.2 },
    { kind = "grunt", x = 1300, left = 1200, right = 1400, speed_mult = 0.9 },
    { kind = "rusher", x = 1600, left = 1500, right = 1700, speed_mult = 1.15 },
    { kind = "grunt", x = 1900, left = 1800, right = 2000, speed_mult = 1.0 },
    { kind = "rusher", x = 2100, left = 2000, right = 2200, speed_mult = 1.1 },
  }
  
  -- Mini boss no final da fase
  base.boss_spawns = {
    { boss_index = 1, x = 3500 },  -- Capanga do Ferro
  }
  
  -- Segments: matar todos inimigos, depois o boss
  base.segments = {
    {
      start_x = 0,
      gate_x = 3200,
      locked = true,
      enemy_ids = { 1, 2, 3, 4, 5, 6, 7, 8 },
      boss_ids = {},
    },
    {
      start_x = 3200,
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

return Level02
