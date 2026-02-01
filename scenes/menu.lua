local Level01 = require("scenes.level01")
local UI = require("config.ui")

local Menu = {}
Menu.__index = Menu

local MENU_COLORS = UI.colors.menu
local MENU_FONTS = UI.fonts.menu
local MENU_LAYOUT = UI.layout.menu

local function set_color(color)
  love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
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

function Menu.new(context)
  local self = setmetatable({}, Menu)
  self.context = context
  self.screen = "menu"
  self.items = { "Iniciar", "Sobre", "Sair" }
  self.selected_index = 1
  self.fonts = {
    title = load_font(self.context.assets, MENU_FONTS.title),
    subtitle = load_font(self.context.assets, MENU_FONTS.subtitle),
    menu = load_font(self.context.assets, MENU_FONTS.menu),
    footer = load_font(self.context.assets, MENU_FONTS.footer),
    body = load_font(self.context.assets, MENU_FONTS.body),
  }
  return self
end

local function draw_background(width, height)
  set_color(MENU_COLORS.background)
  love.graphics.rectangle("fill", 0, 0, width, height)
  set_color(MENU_COLORS.border)
  love.graphics.rectangle(
    "line",
    MENU_LAYOUT.border_padding,
    MENU_LAYOUT.border_padding,
    width - MENU_LAYOUT.border_padding * 2,
    height - MENU_LAYOUT.border_padding * 2,
    MENU_LAYOUT.border_radius,
    MENU_LAYOUT.border_radius
  )
end

local function draw_title(width, title_font, subtitle_font)
  love.graphics.setFont(title_font)
  set_color(MENU_COLORS.title)
  love.graphics.printf("Jogo das Mascaras", 0, MENU_LAYOUT.title_y, width, "center")

  love.graphics.setFont(subtitle_font)
  set_color(MENU_COLORS.subtitle)
  love.graphics.printf("Goias distopico. Escolha seu caminho.", 0, MENU_LAYOUT.subtitle_y, width, "center")
end

local function draw_menu_list(width, y, items, selected_index, font)
  love.graphics.setFont(font)
  for i, label in ipairs(items) do
    local is_selected = i == selected_index
    set_color(is_selected and MENU_COLORS.item_selected or MENU_COLORS.item)
    local prefix = is_selected and "> " or "  "
    love.graphics.printf(prefix .. label, 0, y, width, "center")
    y = y + MENU_LAYOUT.menu_line_h
  end
end

local function draw_footer(width, font)
  love.graphics.setFont(font)
  set_color(MENU_COLORS.footer)
  love.graphics.printf(
    "Setas/WASD para mover | Enter/Espaco para selecionar | Esc para sair",
    0,
    MENU_LAYOUT.footer_y,
    width,
    "center"
  )
end

local function draw_about(width, height, title_font, body_font)
  love.graphics.setFont(title_font)
  set_color(MENU_COLORS.title)
  love.graphics.printf("Sobre", 0, MENU_LAYOUT.about_title_y, width, "center")

  love.graphics.setFont(body_font)
  set_color(MENU_COLORS.about_body)
  love.graphics.printf(
    "O Coronel Supremo domina por mascaras.\nVoce comeca mascarado e decide: absorver ou libertar.",
    0,
    MENU_LAYOUT.about_body_y,
    width,
    "center"
  )
  set_color(MENU_COLORS.about_footer)
  love.graphics.printf("Enter/Esc para voltar", 0, height - MENU_LAYOUT.about_footer_offset, width, "center")
end

function Menu:draw()
  local width = self.context.settings.width
  local height = self.context.settings.height
  local fonts = self.fonts

  draw_background(width, height)

  if self.screen == "menu" then
    draw_title(width, fonts.title, fonts.subtitle)
    draw_menu_list(width, MENU_LAYOUT.menu_start_y, self.items, self.selected_index, fonts.menu)
    draw_footer(width, fonts.footer)
  else
    draw_about(width, height, fonts.title, fonts.body)
  end
end

function Menu:update()
  local input = self.context.input
  if self.screen == "menu" then
    if input:pressed("down") then
      self.selected_index = self.selected_index % #self.items + 1
    elseif input:pressed("up") then
      self.selected_index = (self.selected_index - 2) % #self.items + 1
    elseif input:pressed("confirm") then
      local selected = self.items[self.selected_index]
      if selected == "Iniciar" then
        self.context.state.switch(Level01.new(self.context))
      elseif selected == "Sobre" then
        self.screen = "about"
      elseif selected == "Sair" then
        love.event.quit()
      end
    elseif input:pressed("back") then
      love.event.quit()
    end
  else
    if input:pressed("confirm") or input:pressed("back") then
      self.screen = "menu"
    end
  end
end

return Menu
