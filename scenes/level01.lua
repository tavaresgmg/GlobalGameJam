local Scene = require("core.scene")
local Camera = require("core.camera")
local Physics = require("core.physics")
local Player = require("entities.player")
local Enemy = require("entities.enemy")
local Movement = require("systems.movement")
local Combat = require("systems.combat")
local Hud = require("ui.hud")

local Level01 = setmetatable({}, { __index = Scene })
Level01.__index = Level01

function Level01.new(context)
  local self = setmetatable(Scene.new(), Level01)
  self.context = context
  self.hud = Hud.new()
  return self
end

function Level01:load()
  local settings = self.context.settings
  local constants = self.context.constants

  self.world = {
    width = settings.width * 2,
    height = settings.height,
    gravity = constants.gravity,
    platforms = {},
  }

  local floor_y = settings.height - 40
  table.insert(self.world.platforms, { x = 0, y = floor_y, w = self.world.width, h = 40 })
  table.insert(self.world.platforms, { x = 220, y = floor_y - 120, w = 140, h = 20 })
  table.insert(self.world.platforms, { x = 520, y = floor_y - 200, w = 160, h = 20 })

  self.spawn = { x = 80, y = floor_y - constants.player.height }
  self.player = Player.new(self.spawn.x, self.spawn.y, constants.player)
  self.player.on_ground = true

  self.enemies = {
    Enemy.new(420, floor_y - constants.enemy.height, constants.enemy, 360, 520),
    Enemy.new(720, floor_y - constants.enemy.height, constants.enemy, 680, 860),
  }

  self.camera = Camera.new(settings.width, settings.height)
end

function Level01:update(dt)
  Movement.update_player(self.player, self.context.input, self.world, dt)
  Movement.update_enemies(self.enemies, self.world, dt)
  Combat.update(self.player, self.context.input, self.enemies, self.context.constants.player, dt)

  if self.player.y > self.world.height + 200 then
    self.player:reset(self.spawn.x, self.spawn.y)
  end

  for _, enemy in ipairs(self.enemies) do
    if enemy.alive then
      local hit = Physics.aabb(
        self.player.x,
        self.player.y,
        self.player.w,
        self.player.h,
        enemy.x,
        enemy.y,
        enemy.w,
        enemy.h
      )

      if hit then
        self.player.health = math.max(0, self.player.health - 1)
        self.player:reset(self.spawn.x, self.spawn.y)
      end
    end
  end

  if self.player.health == 0 then
    self.player.health = self.context.constants.player.max_health
  end
end

function Level01:draw()
  self.camera:follow(self.player, self.world.width, self.world.height)
  self.camera:attach()

  love.graphics.clear(0.08, 0.1, 0.12)
  love.graphics.setColor(0.2, 0.2, 0.2)
  for _, platform in ipairs(self.world.platforms) do
    love.graphics.rectangle("fill", platform.x, platform.y, platform.w, platform.h)
  end

  for _, enemy in ipairs(self.enemies) do
    enemy:draw()
  end

  self.player:draw()

  if self.player.attack_timer > 0 then
    local hitbox = self.player:attack_box(self.context.constants.player)
    love.graphics.setColor(1, 0.8, 0.2, 0.5)
    love.graphics.rectangle("fill", hitbox.x, hitbox.y, hitbox.w, hitbox.h)
  end

  self.camera:detach()

  self.hud:draw(self.player)
end

function Level01:keypressed(key)
  if key == "escape" then
    local Menu = require("scenes.menu")
    self.context.state:switch(Menu.new(self.context))
  end
end

return Level01
