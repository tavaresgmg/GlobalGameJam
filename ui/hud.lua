local UI = require("config.ui")
local Suit = require("support.suit")

local Hud = {}
Hud.__index = Hud

local HUD_COLORS = UI.colors.hud
local HUD_FONTS = UI.fonts.hud
local HUD_LAYOUT = UI.layout.hud

local function set_color(color, alpha_override)
  if alpha_override then
    love.graphics.setColor(color[1], color[2], color[3], alpha_override)
  else
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
  end
end

local function load_font(assets, font_def)
  if assets and assets.fonts and font_def and font_def.name then
    local font_factory = assets.fonts[font_def.name]
    if type(font_factory) == "function" then
      return font_factory(font_def.size)
    end
  end
  return love.graphics.newFont((font_def and font_def.size) or 12)
end

local function draw_box(x, y, width, height)
  set_color(HUD_COLORS.panel_fill)
  love.graphics.rectangle(
    "fill",
    x,
    y,
    width,
    height,
    HUD_LAYOUT.panel_radius,
    HUD_LAYOUT.panel_radius
  )
  set_color(HUD_COLORS.panel_line)
  love.graphics.rectangle(
    "line",
    x,
    y,
    width,
    height,
    HUD_LAYOUT.panel_radius,
    HUD_LAYOUT.panel_radius
  )
end

local function draw_bar(x, y, width, height, value, max, color)
  if max <= 0 then
    return
  end
  local ratio = math.max(0, math.min(1, value / max))
  set_color(HUD_COLORS.bar_bg)
  love.graphics.rectangle("fill", x, y, width, height)
  set_color(color, 0.95)
  love.graphics.rectangle("fill", x, y, width * ratio, height)
  set_color(HUD_COLORS.bar_line)
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
  self.font_title = load_font(assets, HUD_FONTS.title)
  self.font_body = load_font(assets, HUD_FONTS.body)
  self.font_small = load_font(assets, HUD_FONTS.small)
  self.suit = Suit.new()
  return self
end

local function draw_status_panel(self, player, x, y, width, height)
  local suit = self.suit
  draw_box(x, y, width, height)
  suit:Label(
    "HP",
    {
      id = "hud_hp_label",
      font = self.font_small,
      align = "left",
      color = { normal = { fg = HUD_COLORS.text_primary } },
    },
    x + HUD_LAYOUT.panel_inner,
    y + HUD_LAYOUT.status_text_y,
    width - HUD_LAYOUT.panel_inner * 2,
    16
  )
  suit:Label(
    tostring(player.health) .. "/" .. tostring(player.max_health),
    {
      id = "hud_hp_value",
      font = self.font_small,
      align = "right",
      color = { normal = { fg = HUD_COLORS.text_primary } },
    },
    x + HUD_LAYOUT.panel_inner,
    y + HUD_LAYOUT.status_text_y,
    width - HUD_LAYOUT.panel_inner * 2,
    16
  )

  draw_bar(
    x + HUD_LAYOUT.panel_inner,
    y + HUD_LAYOUT.bar_y,
    width - HUD_LAYOUT.panel_inner * 2,
    HUD_LAYOUT.bar_h,
    player.health,
    player.max_health,
    { 0.25, 0.9, 0.4 }
  )

  suit:Label(
    "Modo: " .. player.mode,
    {
      id = "hud_mode",
      font = self.font_small,
      align = "left",
      color = { normal = { fg = HUD_COLORS.text_secondary } },
    },
    x + HUD_LAYOUT.panel_inner,
    y + HUD_LAYOUT.mode_text_y,
    width - HUD_LAYOUT.panel_inner * 2,
    16
  )
end

local function draw_combat_panel(self, player, x, y, width, height, level_index, total_levels)
  local suit = self.suit
  draw_box(x, y, width, height)

  local special_ready = player.mode == "offensive" and player.special_ready_offensive
    or player.special_ready_defensive
  local special_color = special_ready and HUD_COLORS.special_ready or HUD_COLORS.special_wait
  local special_label = special_ready and "Especial: PRONTO" or "Especial: carregando"
  suit:Label(
    special_label,
    {
      id = "hud_special",
      font = self.font_small,
      align = "left",
      color = { normal = { fg = special_color } },
    },
    x + HUD_LAYOUT.panel_inner,
    y + HUD_LAYOUT.status_text_y,
    width - HUD_LAYOUT.panel_inner * 2,
    16
  )

  local phase_label = ""
  if level_index and total_levels then
    phase_label = "  |  Fase " .. tostring(level_index) .. "/" .. tostring(total_levels)
  end
  suit:Label(
    "A: " .. player.masks_absorbed .. "  R: " .. player.masks_removed .. phase_label,
    {
      id = "hud_masks",
      font = self.font_small,
      align = "left",
      color = { normal = { fg = HUD_COLORS.text_secondary } },
    },
    x + HUD_LAYOUT.panel_inner,
    y + HUD_LAYOUT.mode_text_y,
    width - HUD_LAYOUT.panel_inner * 2,
    16
  )
end

local function draw_abilities_panel(self, player, ability_defs, x, y, width)
  local abilities = ability_names(player, ability_defs)
  if abilities == "" then
    return
  end

  local suit = self.suit
  local lines = wrap_lines(self.font_small, abilities, width - HUD_LAYOUT.panel_inner * 2)
  local height = HUD_LAYOUT.abilities_header_y
    + HUD_LAYOUT.abilities_text_y
    + #lines * HUD_LAYOUT.abilities_line_h

  draw_box(x, y - height, width, height)
  suit:Label(
    "Habilidades",
    {
      id = "hud_abilities_title",
      font = self.font_small,
      align = "left",
      color = { normal = { fg = HUD_COLORS.abilities_title } },
    },
    x + HUD_LAYOUT.panel_inner,
    y - height + HUD_LAYOUT.abilities_header_y,
    width - HUD_LAYOUT.panel_inner * 2,
    16
  )

  local line_y = y - height + HUD_LAYOUT.abilities_text_y
  for i, line in ipairs(lines) do
    suit:Label(
      line,
      {
        id = "hud_abilities_" .. tostring(i),
        font = self.font_small,
        align = "left",
        color = { normal = { fg = HUD_COLORS.abilities_text } },
      },
      x + HUD_LAYOUT.panel_inner,
      line_y,
      width - HUD_LAYOUT.panel_inner * 2,
      16
    )
    line_y = line_y + HUD_LAYOUT.abilities_line_h
  end
end

local function draw_weapon_panel(self, player, x, y, width, height)
  local suit = self.suit
  draw_box(x, y, width, height)

  suit:Label(
    "Armas",
    {
      id = "hud_weapons_title",
      font = self.font_small,
      align = "left",
      color = { normal = { fg = HUD_COLORS.text_secondary } },
    },
    x + HUD_LAYOUT.panel_inner,
    y + HUD_LAYOUT.weapon_text_y,
    width - HUD_LAYOUT.panel_inner * 2,
    16
  )

  local slot_size = HUD_LAYOUT.weapon_slot_size
  local slot_gap = HUD_LAYOUT.weapon_slot_gap
  local total_width = slot_size * 2 + slot_gap
  local slot_x = x + width - HUD_LAYOUT.panel_inner - total_width
  local slot_y = y + (height - slot_size) / 2

  for i = 1, 2 do
    local weapon = player.weapons and player.weapons[i]
    local color = (weapon and weapon.color) or { 0.35, 0.35, 0.35 }
    set_color(color, 0.95)
    love.graphics.rectangle("fill", slot_x, slot_y, slot_size, slot_size, 3, 3)

    local is_active = player.weapon_index == i
    set_color(is_active and { 1, 1, 1, 1 } or { 0.4, 0.4, 0.4, 0.9 })
    love.graphics.rectangle("line", slot_x, slot_y, slot_size, slot_size, 3, 3)

    slot_x = slot_x + slot_size + slot_gap
  end
end

function Hud:draw(player, ability_defs, _, _, settings, level_index, total_levels)
  local screen_w = settings and settings.width or 960
  local screen_h = settings and settings.height or 540

  local padding = HUD_LAYOUT.padding
  local panel_w = HUD_LAYOUT.panel_w
  local panel_h = HUD_LAYOUT.panel_h

  draw_status_panel(self, player, padding, padding, panel_w, panel_h)
  draw_combat_panel(
    self,
    player,
    screen_w - padding - panel_w,
    padding,
    panel_w,
    panel_h,
    level_index,
    total_levels
  )

  local abilities_w = HUD_LAYOUT.abilities_w
  draw_abilities_panel(
    self,
    player,
    ability_defs,
    screen_w - padding - abilities_w,
    screen_h - padding,
    abilities_w
  )

  local weapon_panel_h = HUD_LAYOUT.weapon_panel_h
  draw_weapon_panel(
    self,
    player,
    screen_w - padding - panel_w,
    padding + panel_h + HUD_LAYOUT.weapon_panel_gap,
    panel_w,
    weapon_panel_h
  )

  self.suit:draw()
end

return Hud
