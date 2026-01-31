local Input = {}
Input.__index = Input

function Input.new()
  local self = setmetatable({}, Input)
  self.bindings = {}
  self.just_pressed = {}
  return self
end

function Input:bind(action, keys)
  self.bindings[action] = keys
end

function Input:keypressed(key)
  for action, keys in pairs(self.bindings) do
    for _, bound in ipairs(keys) do
      if key == bound then
        self.just_pressed[action] = true
      end
    end
  end
end

function Input:is_down(action)
  local keys = self.bindings[action]
  if not keys then
    return false
  end

  for _, key in ipairs(keys) do
    if love.keyboard.isDown(key) then
      return true
    end
  end

  return false
end

function Input:consume(action)
  if self.just_pressed[action] then
    self.just_pressed[action] = false
    return true
  end
  return false
end

function Input:clear()
  self.just_pressed = {}
end

return Input
