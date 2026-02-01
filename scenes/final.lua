local UI = require("config.ui")

local Final = {}
Final.__index = Final

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

function Final.new(context, outcome)
  local self = setmetatable({}, Final)
  self.context = context
  self.outcome = outcome
  self.font_title = load_font(self.context.assets, MENU_FONTS.title)
  self.font_body = load_font(self.context.assets, MENU_FONTS.body)
  self.font_footer = load_font(self.context.assets, MENU_FONTS.footer)
  return self
end

function Final:draw()
  local width = self.context.settings.width
  local height = self.context.settings.height

  draw_background(width, height)

  local title = self.outcome == "good" and "Final Bom" or "Final Ruim"
  love.graphics.setFont(self.font_title)
  set_color(MENU_COLORS.title)
  love.graphics.printf(title, 0, height * 0.28, width, "center")

  love.graphics.setFont(self.font_body)
  set_color(MENU_COLORS.subtitle)
  if self.outcome == "good" then
    love.graphics.printf(
      "Voce libertou o povo e quebrou o ciclo do Coronel.",
      0,
      height * 0.45,
      width,
      "center"
    )
  else
    love.graphics.printf(
      "Voce absorveu a mascara do Coronel e virou o novo receptaculo.",
      0,
      height * 0.45,
      width,
      "center"
    )
  end

  love.graphics.setFont(self.font_footer)
  set_color(MENU_COLORS.footer)
  love.graphics.printf("Pressione Enter para voltar ao menu", 0, height * 0.62, width, "center")
end

function Final:update()
  if self.context.input:pressed("confirm") or self.context.input:pressed("back") then
    local Menu = require("scenes.menu")
    self.context.state.switch(Menu.new(self.context))
  end
end

return Final
