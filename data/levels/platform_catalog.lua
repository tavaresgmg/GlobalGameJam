local PlatformCatalog = {}

local DEFAULT_SCALE = 0.4

local function scale_value(value, scale)
  return value * (scale or DEFAULT_SCALE)
end

function PlatformCatalog.add_platform_L(platforms, x, y, scale)
  local s = scale or DEFAULT_SCALE
  table.insert(platforms, {
    x = x + 87 * s,
    y = y,
    w = 261 * s,
    h = 190 * s,
    sprite = "platform_01",
    sprite_scale = s,
    sprite_offset_x = -87 * s,
    sprite_offset_y = 0,
  })
  table.insert(platforms, {
    x = x,
    y = y + 190 * s,
    w = 174 * s,
    h = 189 * s,
  })
end

function PlatformCatalog.add_platform(platforms, kind, x, y, scale)
  local s = scale or DEFAULT_SCALE
  if kind == "platform_02" then
    table.insert(platforms, {
      x = x,
      y = y + 50 * s,
      w = 237 * s,
      h = 80 * s,
      sprite = kind,
      sprite_scale = s,
      sprite_offset_x = 0,
      sprite_offset_y = -50 * s,
    })
  elseif kind == "platform_03" then
    table.insert(platforms, {
      x = x,
      y = y,
      w = 326 * s,
      h = 463 * s,
      sprite = kind,
      sprite_scale = s,
    })
  elseif kind == "platform_04" then
    table.insert(platforms, {
      x = x,
      y = y + 30 * s,
      w = 524 * s,
      h = 70 * s,
      sprite = kind,
      sprite_scale = s,
      sprite_offset_x = 0,
      sprite_offset_y = -30 * s,
    })
  else
    error("Plataforma invalida: " .. tostring(kind))
  end
end

function PlatformCatalog.get_platform_width(kind, scale)
  local s = scale or DEFAULT_SCALE
  if kind == "platform_02" then
    return scale_value(237, s)
  end
  if kind == "platform_03" then
    return scale_value(326, s)
  end
  if kind == "platform_04" then
    return scale_value(524, s)
  end
  if kind == "platform_01_L" or kind == "platform_01" then
    return scale_value(348, s)
  end

  error("Plataforma invalida: " .. tostring(kind))
end

return PlatformCatalog
