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
      special = { "key:q" },
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
  self.state.draw()
end

function App:keypressed(key)
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
