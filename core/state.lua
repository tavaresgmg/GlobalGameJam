local State = {}
State.__index = State

function State.new()
  local self = setmetatable({}, State)
  self.stack = {}
  return self
end

function State:current()
  return self.stack[#self.stack]
end

function State:push(scene)
  table.insert(self.stack, scene)
  if scene.load then
    scene:load()
  end
end

function State:pop()
  local scene = table.remove(self.stack)
  if scene and scene.exit then
    scene:exit()
  end
end

function State:switch(scene)
  self:pop()
  self:push(scene)
end

function State:update(dt)
  local scene = self:current()
  if scene and scene.update then
    scene:update(dt)
  end
end

function State:draw()
  local scene = self:current()
  if scene and scene.draw then
    scene:draw()
  end
end

function State:keypressed(key)
  local scene = self:current()
  if scene and scene.keypressed then
    scene:keypressed(key)
  end
end

function State:keyreleased(key)
  local scene = self:current()
  if scene and scene.keyreleased then
    scene:keyreleased(key)
  end
end

return State
