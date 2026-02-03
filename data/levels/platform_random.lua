local PlatformCatalog = require("data.levels.platform_catalog")
local Settings = require("config.settings")
local Constants = require("config.constants")

local PlatformRandom = {}

local function clamp(value, min_value, max_value)
  if value < min_value then
    return min_value
  end
  if value > max_value then
    return max_value
  end
  return value
end

local function weighted_pick(weights)
  local total = 0
  for _, item in ipairs(weights) do
    total = total + item.weight
  end
  local target = math.random() * total
  local running = 0
  for _, item in ipairs(weights) do
    running = running + item.weight
    if target <= running then
      return item.kind
    end
  end
  return weights[#weights].kind
end

local function max_jump_safe()
  local jump_speed = Constants.player and Constants.player.jump_speed or 520
  local gravity = Constants.gravity or 1400
  if gravity <= 0 then
    return 160
  end
  local max_jump = (jump_speed * jump_speed) / (2 * gravity)
  return max_jump * 1.7
end

local function floor_height()
  local background_height = (Constants.world and Constants.world.background_height)
    or Settings.height
  local ground_height = (Constants.world and Constants.world.ground_height) or 40
  local scale = Settings.height / background_height
  return ground_height * scale
end

function PlatformRandom.build_random_platforms(world_width, floor_y, level_index)
  local platforms = {}
  local floor_h = floor_height()
  table.insert(platforms, { x = 0, y = floor_y, w = world_width, h = floor_h })

  local count = clamp(6 + (level_index or 1) * 2, 6, 16)
  local weights = {
    { kind = "platform_02", weight = 4 },
    { kind = "platform_04", weight = 3 },
    { kind = "platform_01_L", weight = 2 },
    { kind = "platform_03", weight = 1 },
  }

  local cursor_x = 200
  local end_x = world_width - 220
  local gap = 140 + (level_index or 1) * 10
  local safe_jump = max_jump_safe()
  local offsets = { 120, 160, 200, 220 }
  local allowed_offsets = {}
  for _, offset in ipairs(offsets) do
    if offset <= safe_jump then
      table.insert(allowed_offsets, offset)
    end
  end
  if #allowed_offsets == 0 then
    table.insert(allowed_offsets, math.floor(safe_jump))
  end

  for _ = 1, count do
    local kind = weighted_pick(weights)
    local width = PlatformCatalog.get_platform_width(kind)
    if cursor_x + width > end_x then
      break
    end

    local x = cursor_x + math.random(-40, 40)
    if x < 80 then
      x = 80
    end
    if x + width > end_x then
      x = end_x - width
    end

    local offset = allowed_offsets[math.random(1, #allowed_offsets)]
    local y = floor_y - offset

    if kind == "platform_01_L" then
      PlatformCatalog.add_platform_L(platforms, x, y)
    else
      PlatformCatalog.add_platform(platforms, kind, x, y)
    end

    cursor_x = cursor_x + width + gap
  end

  return platforms
end

return PlatformRandom
