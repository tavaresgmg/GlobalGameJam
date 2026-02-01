local Particles = {}
Particles.__index = Particles

local function make_pixel()
  local image_data = love.image.newImageData(2, 2)
  image_data:mapPixel(function()
    return 1, 1, 1, 1
  end)
  return love.graphics.newImage(image_data)
end

local function build_damage_ps(pixel)
  local ps = love.graphics.newParticleSystem(pixel, 160)
  ps:setParticleLifetime(0.2, 0.5)
  ps:setSizes(3.4, 0.8)
  ps:setSpeed(90, 260)
  ps:setSpread(math.pi * 2)
  ps:setLinearDamping(1.2, 4)
  ps:setColors(1, 0.1, 0.1, 1, 1, 0.1, 0.1, 0)
  return ps
end

local function build_attack_ps(pixel)
  local ps = love.graphics.newParticleSystem(pixel, 160)
  ps:setParticleLifetime(0.12, 0.3)
  ps:setSizes(3.0, 0.6)
  ps:setSpeed(110, 300)
  ps:setSpread(math.pi / 5)
  ps:setLinearDamping(1.6, 6)
  ps:setColors(1, 0.85, 0.2, 1, 1, 0.5, 0.1, 0)
  return ps
end

function Particles.new()
  local self = setmetatable({}, Particles)
  local pixel = make_pixel()
  self.damage = build_damage_ps(pixel)
  self.attack = build_attack_ps(pixel)
  return self
end

function Particles:emit_damage(x, y)
  self.damage:setPosition(x, y)
  self.damage:emit(64)
end

function Particles:emit_attack(x, y, dir)
  self.attack:setPosition(x, y)
  self.attack:setDirection(dir >= 0 and 0 or math.pi)
  self.attack:emit(48)
end

function Particles:update(dt)
  self.damage:update(dt)
  self.attack:update(dt)
end

function Particles:draw()
  love.graphics.draw(self.damage)
  love.graphics.draw(self.attack)
end

return Particles
