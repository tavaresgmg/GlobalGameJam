local App = require("core.app")

local app = App.new()
local hot_reload = nil

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  app:load()

  if love.filesystem and love.filesystem.isFused and not love.filesystem.isFused() then
    local lurker = require("support.lurker")
    hot_reload = lurker.init()
  end
end

function love.update(dt)
  if hot_reload then
    hot_reload.update()
  end
  app:update(dt)
end

function love.draw()
  app:draw()
end

function love.keypressed(key)
  app:keypressed(key)
end

function love.keyreleased(key)
  app:keyreleased(key)
end
