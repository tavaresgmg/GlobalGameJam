local Scene = {}
Scene.__index = Scene

function Scene.new()
  return setmetatable({}, Scene)
end

function Scene:load() end
function Scene:update() end
function Scene:draw() end
function Scene:keypressed() end
function Scene:keyreleased() end
function Scene:exit() end

return Scene
