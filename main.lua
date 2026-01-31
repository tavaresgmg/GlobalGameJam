local App = require("core.app")

local app = App.new()

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  app:load()
end

function love.update(dt)
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
