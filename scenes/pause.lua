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
  self.font_title = load_font(self.context.assets, MENU_FONTS.title)
  self.font_body = load_font(self.context.assets, MENU_FONTS.body)
  return self
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
  love.graphics.printf("Pausado", 0, height * 0.35, width, "center")

  love.graphics.setFont(self.font_body)
  set_color(MENU_COLORS.footer)
  love.graphics.printf("Esc para voltar", 0, height * 0.5, width, "center")
end

function Pause:update()
  if self.context.input:pressed("pause") or self.context.input:pressed("back") then
    self.context.state.switch(self.gameplay_state)
  end
end

return Pause
