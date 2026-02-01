local Hud = {}
Hud.__index = Hud

local function load_font(assets, name, size)
  if assets and assets.fonts and assets.fonts[name] then
    local font_factory = assets.fonts[name]
    if type(font_factory) == "function" then
      return font_factory(size)
    end
  end
  return love.graphics.newFont(size)
end

local function draw_box(x, y, width, height)
  love.graphics.setColor(0.06, 0.07, 0.09, 0.78)
  love.graphics.rectangle("fill", x, y, width, height, 8, 8)
  love.graphics.setColor(0.22, 0.26, 0.3, 0.85)
  love.graphics.rectangle("line", x, y, width, height, 8, 8)
end

local function draw_bar(x, y, width, height, value, max, color)
  if max <= 0 then
    return
  end
  local ratio = math.max(0, math.min(1, value / max))
  love.graphics.setColor(0.12, 0.12, 0.12, 0.9)
  love.graphics.rectangle("fill", x, y, width, height)
  love.graphics.setColor(color[1], color[2], color[3], 0.95)
  love.graphics.rectangle("fill", x, y, width * ratio, height)
  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.rectangle("line", x, y, width, height)
end

local function ability_names(player, ability_defs)
  local names = {}
  for _, ability_id in ipairs(player.active_abilities or {}) do
    local ability = ability_defs[ability_id]
    if ability then
      table.insert(names, ability.name)
    end
  end
  return table.concat(names, "  •  ")
end

local function wrap_lines(font, text, width)
  if text == "" then
    return {}
  end
  local _, lines = font:getWrap(text, width)
  return lines
end

function Hud.new(assets)
  local self = setmetatable({}, Hud)
  self.font_title = load_font(assets, "SpaceMono-Bold", 14)
  self.font_body = load_font(assets, "SpaceMono-Regular", 12)
  self.font_small = load_font(assets, "SpaceMono-Regular", 10)
  return self
end

local function draw_status_panel(self, player, x, y, width, height)
  draw_box(x, y, width, height)
  love.graphics.setFont(self.font_small)
  love.graphics.setColor(0.9, 0.9, 0.9)
  love.graphics.print("HP", x + 10, y + 8)
  love.graphics.print(
    tostring(player.health) .. "/" .. tostring(player.max_health),
    x + width - 60,
    y + 8
  )

  draw_bar(x + 10, y + 22, width - 20, 6, player.health, player.max_health, { 0.25, 0.9, 0.4 })

  love.graphics.setFont(self.font_small)
  love.graphics.setColor(0.7, 0.7, 0.75)
  love.graphics.print("Modo: " .. player.mode, x + 10, y + 34)
end

local function draw_combat_panel(self, player, x, y, width, height)
  draw_box(x, y, width, height)
  love.graphics.setFont(self.font_small)

  local special_ready = player.mode == "offensive" and player.special_ready_offensive
    or player.special_ready_defensive
  love.graphics.setColor(
    special_ready and 0.4 or 0.7,
    special_ready and 0.95 or 0.7,
    special_ready and 0.6 or 0.7
  )
  local special_label = special_ready and "Especial: PRONTO" or "Especial: carregando"
  love.graphics.print(special_label, x + 10, y + 8)

  love.graphics.setColor(0.7, 0.7, 0.75)
  love.graphics.print(
    "A: " .. player.masks_absorbed .. "  R: " .. player.masks_removed,
    x + 10,
    y + 34
  )
end

local function draw_abilities_panel(self, player, ability_defs, x, y, width)
  local abilities = ability_names(player, ability_defs)
  if abilities == "" then
    return
  end

  love.graphics.setFont(self.font_small)
  local lines = wrap_lines(self.font_small, abilities, width - 20)
  local height = 24 + #lines * 12

  draw_box(x, y - height, width, height)
  love.graphics.setColor(0.85, 0.85, 0.9)
  love.graphics.print("Habilidades", x + 10, y - height + 6)

  local line_y = y - height + 18
  love.graphics.setColor(0.7, 0.7, 0.75)
  for _, line in ipairs(lines) do
    love.graphics.print(line, x + 10, line_y)
    line_y = line_y + 12
  end
end

function Hud:draw(player, ability_defs, _, _, settings)
  local screen_w = settings and settings.width or 960
  local screen_h = settings and settings.height or 540

  local padding = 12
  local panel_w = 220
  local panel_h = 50

  draw_status_panel(self, player, padding, padding, panel_w, panel_h)
  draw_combat_panel(self, player, screen_w - padding - panel_w, padding, panel_w, panel_h)

  local abilities_w = 260
  draw_abilities_panel(
    self,
    player,
    ability_defs,
    screen_w - padding - abilities_w,
    screen_h - padding,
    abilities_w
  )
end

return Hud
