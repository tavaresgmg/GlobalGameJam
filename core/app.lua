local Settings = require("config.settings")
local Constants = require("config.constants")
local Input = require("core.input")
local State = require("core.state")
local Time = require("core.time")
local Menu = require("scenes.menu")

local App = {}
App.__index = App

function App.new()
  local self = setmetatable({}, App)
  self.input = Input.new()
  self.state = State.new()
  self.context = {
    input = self.input,
    state = self.state,
    settings = Settings,
    constants = Constants,
  }
  return self
end

function App:load()
  love.window.setTitle(Settings.title)
  love.window.setMode(Settings.width, Settings.height, {
    fullscreen = Settings.fullscreen,
    vsync = Settings.vsync,
  })

  self:bind_defaults()
  self.state:push(Menu.new(self.context))
end

function App:bind_defaults()
  self.input:bind("left", { "a", "left" })
  self.input:bind("right", { "d", "right" })
  self.input:bind("jump", { "space", "w", "up" })
  self.input:bind("attack", { "j", "k", "x" })
  self.input:bind("pause", { "escape" })
end

function App:update(dt)
  dt = Time.clamp_dt(dt)
  self.state:update(dt)
  self.input:clear()
end

function App:draw()
  self.state:draw()
end

function App:keypressed(key)
  self.input:keypressed(key)
  self.state:keypressed(key)
end

function App:keyreleased(key)
  self.state:keyreleased(key)
end

return App
