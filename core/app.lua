local Settings = require("config.settings")
local Constants = require("config.constants")
local Baton = require("support.baton")
local Cargo = require("support.cargo")
local Gamestate = require("support.hump.gamestate")
local Time = require("core.time")
local Menu = require("scenes.menu")

local App = {}
App.__index = App

function App.new()
  local self = setmetatable({}, App)
  self.input = Baton.new({
    controls = {
      left = { "key:a", "key:left" },
      right = { "key:d", "key:right" },
      up = { "key:w", "key:up" },
      down = { "key:s", "key:down" },
      jump = { "key:space", "key:w", "key:up" },
      dash = { "key:lshift", "key:rshift" },
      attack = { "key:j", "key:k", "key:x" },
      special = { "key:r" },
      swap_weapon = { "key:q" },
      interact = { "key:e" },
      confirm = { "key:return", "key:kpenter", "key:space" },
      back = { "key:escape" },
      pause = { "key:escape" },
    },
  })
  self.state = Gamestate
  self.context = {
    input = self.input,
    state = self.state,
    settings = Settings,
    constants = Constants,
    assets = nil,
  }
  return self
end

function App:load()
  love.window.setTitle(Settings.title)
  love.window.setMode(Settings.width, Settings.height, {
    fullscreen = Settings.fullscreen,
    vsync = Settings.vsync,
  })

  local seed = Settings.random_seed or os.time()
  math.randomseed(seed)
  Settings.random_seed = seed

  self.canvas = love.graphics.newCanvas(Settings.width, Settings.height)

  self.assets = Cargo.init("assets")
  self.context.assets = self.assets

  self.state.switch(Menu.new(self.context))
end

function App:update(dt)
  dt = Time.clamp_dt(dt)
  self.input:update()
  self.state.update(dt)
end

function App:draw()
  local window_w, window_h = love.graphics.getDimensions()
  local scale = math.min(window_w / Settings.width, window_h / Settings.height)
  local offset_x = math.floor((window_w - Settings.width * scale) * 0.5)
  local offset_y = math.floor((window_h - Settings.height * scale) * 0.5)

  if self.canvas then
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 1)
    self.state.draw()
    love.graphics.setCanvas()

    love.graphics.clear(0, 0, 0, 1)
    love.graphics.origin()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvas, offset_x, offset_y, 0, scale, scale)
  else
    self.state.draw()
  end
end

function App:toggle_fullscreen()
  local fullscreen = love.window.getFullscreen()
  local target = not fullscreen
  local success = love.window.setFullscreen(target, "desktop")

  if success then
    Settings.fullscreen = target
  else
    print("[window] Falha ao alternar tela cheia.")
  end

  return success
end

function App:keypressed(key)
  if key == "f11" then
    self:toggle_fullscreen()
    return
  end

  if key == "return" or key == "kpenter" then
    if love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt") then
      self:toggle_fullscreen()
      return
    end
  end

  if self.state.keypressed then
    self.state.keypressed(key)
  end
end

function App:keyreleased(key)
  if self.state.keyreleased then
    self.state.keyreleased(key)
  end
end

return App
