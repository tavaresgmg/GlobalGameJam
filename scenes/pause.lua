local UI = require("config.ui")

local Pause = {}
Pause.__index = Pause

local MENU_COLORS = UI.colors.menu
local MENU_FONTS = UI.fonts.menu

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

function Pause.new(context, gameplay_state)
  local self = setmetatable({}, Pause)
  self.context = context
  self.gameplay_state = gameplay_state
  self.items = { "Continuar", "Menu", "Sair" }
  self.selected_index = 1
  self.font_title = load_font(self.context.assets, MENU_FONTS.title)
  self.font_body = load_font(self.context.assets, MENU_FONTS.body)
  return self
end

local function draw_menu(width, height, font, items, selected_index)
  love.graphics.setFont(font)
  local item_h = 36
  local item_gap = 10
  local total_h = (#items * item_h) + ((#items - 1) * item_gap)
  local start_y = height * 0.5 - total_h * 0.5

  for i, label in ipairs(items) do
    local y = start_y + (i - 1) * (item_h + item_gap)
    local is_selected = i == selected_index
    if is_selected then
      set_color(MENU_COLORS.item_selected)
      love.graphics.rectangle("fill", width * 0.35, y, width * 0.3, item_h, 10, 10)
      set_color(MENU_COLORS.item_selected_text)
    else
      set_color(MENU_COLORS.item)
    end
    love.graphics.printf(label, 0, y + 6, width, "center")
  end
end

function Pause:draw()
  if self.gameplay_state and self.gameplay_state.draw then
    self.gameplay_state:draw()
  end

  local width = self.context.settings.width
  local height = self.context.settings.height

  set_color({ 0, 0, 0, 0.55 })
  love.graphics.rectangle("fill", 0, 0, width, height)

  love.graphics.setFont(self.font_title)
  set_color(MENU_COLORS.title)
  love.graphics.printf("Pausado", 0, height * 0.25, width, "center")

  love.graphics.setFont(self.font_body)
  draw_menu(width, height, self.font_body, self.items, self.selected_index)

  set_color(MENU_COLORS.footer)
  love.graphics.printf("Enter para selecionar • Esc para voltar", 0, height * 0.78, width, "center")
end

function Pause:update()
  local input = self.context.input
  if input:pressed("down") then
    self.selected_index = self.selected_index % #self.items + 1
  elseif input:pressed("up") then
    self.selected_index = (self.selected_index - 2) % #self.items + 1
  elseif input:pressed("confirm") then
    local selected = self.items[self.selected_index]
    if selected == "Continuar" then
      self.context.state.switch(self.gameplay_state)
    elseif selected == "Menu" then
      local Menu = require("scenes.menu")
      self.context.state.switch(Menu.new(self.context))
    elseif selected == "Sair" then
      love.event.quit()
    end
  elseif input:pressed("pause") or input:pressed("back") then
    self.context.state.switch(self.gameplay_state)
  end
end

return Pause
