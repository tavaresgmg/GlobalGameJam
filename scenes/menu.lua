local Level01 = require("scenes.level01")

local Menu = {}
Menu.__index = Menu

local function load_font(assets, name, size)
  if assets and assets.fonts and assets.fonts[name] then
    local font_factory = assets.fonts[name]
    if type(font_factory) == "function" then
      return font_factory(size)
    end
  end
  return love.graphics.newFont(size)
end

function Menu.new(context)
  local self = setmetatable({}, Menu)
  self.context = context
  self.screen = "menu"
  self.items = { "Iniciar", "Sobre", "Sair" }
  self.selected_index = 1
  self.fonts = {
    title = load_font(self.context.assets, "SpaceMono-Bold", 36),
    subtitle = load_font(self.context.assets, "SpaceMono-Regular", 16),
    menu = load_font(self.context.assets, "SpaceMono-Regular", 22),
    footer = load_font(self.context.assets, "SpaceMono-Regular", 12),
    body = load_font(self.context.assets, "SpaceMono-Regular", 16),
  }
  return self
end

local function draw_background(width, height)
  love.graphics.setColor(0.05, 0.06, 0.08)
  love.graphics.rectangle("fill", 0, 0, width, height)
  love.graphics.setColor(0.2, 0.2, 0.3, 0.5)
  love.graphics.rectangle("line", 24, 24, width - 48, height - 48, 12, 12)
end

local function draw_title(width, title_font, subtitle_font)
  love.graphics.setFont(title_font)
  love.graphics.setColor(0.95, 0.95, 0.95)
  love.graphics.printf("Jogo das Mascaras", 0, 90, width, "center")

  love.graphics.setFont(subtitle_font)
  love.graphics.setColor(0.7, 0.7, 0.75)
  love.graphics.printf("Goias distopico. Escolha seu caminho.", 0, 140, width, "center")
end

local function draw_menu_list(width, y, items, selected_index, font)
  love.graphics.setFont(font)
  for i, label in ipairs(items) do
    local is_selected = i == selected_index
    love.graphics.setColor(
      is_selected and 1 or 0.7,
      is_selected and 1 or 0.7,
      is_selected and 1 or 0.7
    )
    local prefix = is_selected and "> " or "  "
    love.graphics.printf(prefix .. label, 0, y, width, "center")
    y = y + 36
  end
end

local function draw_footer(width, font)
  love.graphics.setFont(font)
  love.graphics.setColor(0.6, 0.6, 0.65)
  love.graphics.printf(
    "Setas/WASD para mover | Enter/Espaco para selecionar | Esc para sair",
    0,
    420,
    width,
    "center"
  )
end

local function draw_about(width, height, title_font, body_font)
  love.graphics.setFont(title_font)
  love.graphics.setColor(0.95, 0.95, 0.95)
  love.graphics.printf("Sobre", 0, 100, width, "center")

  love.graphics.setFont(body_font)
  love.graphics.setColor(0.7, 0.7, 0.75)
  love.graphics.printf(
    "O Coronel Supremo domina por mascaras.\nVoce comeca mascarado e decide: absorver ou libertar.",
    0,
    170,
    width,
    "center"
  )
  love.graphics.setColor(0.6, 0.6, 0.65)
  love.graphics.printf("Enter/Esc para voltar", 0, height - 90, width, "center")
end

function Menu:draw()
  local width = self.context.settings.width
  local height = self.context.settings.height
  local fonts = self.fonts

  draw_background(width, height)

  if self.screen == "menu" then
    draw_title(width, fonts.title, fonts.subtitle)
    draw_menu_list(width, 220, self.items, self.selected_index, fonts.menu)
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
