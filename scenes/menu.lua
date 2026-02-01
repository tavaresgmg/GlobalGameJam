local Level = require("scenes.level")
local UI = require("config.ui")

local Menu = {}
Menu.__index = Menu

local MENU_COLORS = UI.colors.menu
local MENU_FONTS = UI.fonts.menu
local MENU_LAYOUT = UI.layout.menu

local function set_color(color)
  love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function draw_gradient(width, height, top_color, bottom_color)
  local steps = 22
  local step_h = math.ceil(height / steps)
  for i = 0, steps - 1 do
    local t = i / (steps - 1)
    love.graphics.setColor(
      lerp(top_color[1], bottom_color[1], t),
      lerp(top_color[2], bottom_color[2], t),
      lerp(top_color[3], bottom_color[3], t),
      lerp(top_color[4] or 1, bottom_color[4] or 1, t)
    )
    love.graphics.rectangle("fill", 0, i * step_h, width, step_h)
  end
end

local function draw_glows(width, height)
  set_color(MENU_COLORS.glow_primary)
  love.graphics.circle("fill", width * 0.25, height * 0.2, height * 0.55)
  set_color(MENU_COLORS.glow_secondary)
  love.graphics.circle("fill", width * 0.85, height * 0.6, height * 0.5)
end

local function draw_sparkles(width, height)
  set_color(MENU_COLORS.star)
  for i = 1, 16 do
    local x = (i * 97) % width
    local y = (i * 53) % height
    local r = 1 + (i % 3)
    love.graphics.circle("fill", x, y, r)
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

function Menu.new(context)
  local self = setmetatable({}, Menu)
  self.context = context
  self.screen = "menu"
  self.items = { "Iniciar", "Sobre", "Sair" }
  self.selected_index = 1
  self.intro_page = 1
  self.intro_pages = {
    {
      title = "Prólogo",
      body = table.concat({
        "Enquanto você caminha, o sol arde na pele. Ao longe ecoam carros de boi.",
        "Nesta cidade de tardes desbotadas, árvores tortas e poeira, o ouro perdeu o brilho —",
        "restaram o cultivo e os pastos.",
        "",
        "Este é o Arraial do Cabresto, governado pelo autoritário Coronellis e seus capangas.",
        "Suas máscaras impõem ordem e mantêm a população sob controle.",
      }, "\n"),
    },
    {
      title = "Máscaras",
      body = table.concat({
        "Dizem que Coronellis trouxe paz, mas os habitantes se escondem atrás de máscaras para",
        "evitar o caos. Ao encarar os outros, você percebe algo estranho: cada máscara guarda",
        "uma habilidade que você não tem — força, agilidade, coragem.",
        "",
        "Como um instinto, surge a certeza: essas máscaras podem te tornar mais forte.",
        "A dúvida é simples: você quer que elas sejam suas?",
      }, "\n"),
    },
    {
      title = "Escolha",
      body = table.concat({
        "Quanto mais máscaras você veste, mais poder sente — e mais pesado fica o caminho.",
        "Alguns pedem clemência. Um xamã sussurra que usar máscaras demais apaga as raízes",
        "e confunde o bem e o mal.",
        "",
        "O que te guia: o poder ou a liberdade?",
      }, "\n"),
    },
  }
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
  draw_gradient(width, height, MENU_COLORS.background_top, MENU_COLORS.background_bottom)
  draw_glows(width, height)
  draw_sparkles(width, height)
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
  set_color(MENU_COLORS.title_shadow)
  love.graphics.printf("Máscara e Poder", 0, MENU_LAYOUT.title_y + 3, width, "center")
  set_color(MENU_COLORS.title)
  love.graphics.printf("Máscara e Poder", 0, MENU_LAYOUT.title_y, width, "center")
  set_color(MENU_COLORS.accent)
  love.graphics.rectangle(
    "fill",
    width * 0.5 - 90,
    MENU_LAYOUT.title_y + 44,
    180,
    3,
    2,
    2
  )

  love.graphics.setFont(subtitle_font)
  set_color(MENU_COLORS.subtitle)
  love.graphics.printf(
    "Goias distopico. Escolha seu caminho.",
    0,
    MENU_LAYOUT.subtitle_y,
    width,
    "center"
  )
end

local function draw_menu_list(width, y, items, selected_index, font)
  love.graphics.setFont(font)
  local item_w = MENU_LAYOUT.menu_item_w or 240
  local item_h = MENU_LAYOUT.menu_item_h or MENU_LAYOUT.menu_line_h
  local item_radius = MENU_LAYOUT.menu_item_radius or 10
  local item_gap = MENU_LAYOUT.menu_item_gap or 8
  local x = (width - item_w) * 0.5
  for i, label in ipairs(items) do
    local y_pos = y + (i - 1) * (item_h + item_gap)
    local is_selected = i == selected_index
    if is_selected then
      set_color(MENU_COLORS.item_shadow)
      love.graphics.rectangle(
        "fill",
        x + 2,
        y_pos + 3,
        item_w,
        item_h,
        item_radius,
        item_radius
      )
      set_color(MENU_COLORS.item_selected)
      love.graphics.rectangle("fill", x, y_pos, item_w, item_h, item_radius, item_radius)
      set_color(MENU_COLORS.item_selected_border)
      love.graphics.rectangle("line", x, y_pos, item_w, item_h, item_radius, item_radius)
      set_color(MENU_COLORS.item_selected_text)
    else
      set_color(MENU_COLORS.item)
    end
    local text_y = y_pos + (item_h - font:getHeight()) * 0.5 - 1
    love.graphics.printf(label, x, text_y, item_w, "center")
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
    "Máscara e Poder é um jogo de ação sobre escolhas morais em um Brasil rural distópico.\n"
      .. "Derrote capangas e chefes, absorva ou liberte máscaras e descubra o preço do poder.\n"
      .. "O final muda conforme suas escolhas.",
    0,
    MENU_LAYOUT.about_body_y,
    width,
    "center"
  )
  set_color(MENU_COLORS.about_footer)
  love.graphics.printf(
    "Enter/Esc para voltar",
    0,
    height - MENU_LAYOUT.about_footer_offset,
    width,
    "center"
  )
end

local function draw_intro(width, height, title_font, body_font, page, page_index, total)
  love.graphics.setFont(title_font)
  set_color(MENU_COLORS.title)
  love.graphics.printf(page.title, 0, MENU_LAYOUT.intro_title_y, width, "center")

  local pad = MENU_LAYOUT.intro_panel_padding or 24
  local panel_x = MENU_LAYOUT.border_padding + pad
  local panel_y = MENU_LAYOUT.intro_body_y - 12
  local panel_w = width - panel_x * 2
  local panel_h = height - panel_y - MENU_LAYOUT.intro_footer_offset

  set_color(MENU_COLORS.panel_fill)
  love.graphics.rectangle("fill", panel_x, panel_y, panel_w, panel_h, 14, 14)
  set_color(MENU_COLORS.panel_line)
  love.graphics.rectangle("line", panel_x, panel_y, panel_w, panel_h, 14, 14)

  love.graphics.setFont(body_font)
  set_color(MENU_COLORS.about_body)
  love.graphics.printf(
    page.body,
    panel_x + pad,
    MENU_LAYOUT.intro_body_y,
    panel_w - pad * 2,
    "left"
  )

  love.graphics.setFont(body_font)
  set_color(MENU_COLORS.footer)
  local footer = "Enter para continuar • Esc para voltar (Página "
    .. page_index
    .. "/"
    .. total
    .. ")"
  love.graphics.printf(
    footer,
    0,
    height - MENU_LAYOUT.intro_footer_offset,
    width,
    "center"
  )
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
  elseif self.screen == "about" then
    draw_about(width, height, fonts.title, fonts.body)
  elseif self.screen == "intro" then
    local page = self.intro_pages[self.intro_page]
    if page then
      draw_intro(width, height, fonts.title, fonts.body, page, self.intro_page, #self.intro_pages)
    end
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
        self.intro_page = 1
        self.screen = "intro"
      elseif selected == "Sobre" then
        self.screen = "about"
      elseif selected == "Sair" then
        love.event.quit()
      end
    elseif input:pressed("back") then
      love.event.quit()
    end
  elseif self.screen == "about" then
    if input:pressed("confirm") or input:pressed("back") then
      self.screen = "menu"
    end
  elseif self.screen == "intro" then
    if input:pressed("confirm") then
      if self.intro_page < #self.intro_pages then
        self.intro_page = self.intro_page + 1
      else
        self.context.state.switch(Level.new(self.context, { level_index = 1 }))
      end
    elseif input:pressed("back") then
      self.screen = "menu"
    end
  end
end

return Menu
