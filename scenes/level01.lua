local Camera = require("support.hump.camera")
local Player = require("entities.player")
local Enemy = require("entities.enemy")
local Boss = require("entities.boss")
local Pickup = require("entities.pickup")
local MaskDrop = require("entities.mask_drop")
local Movement = require("systems.movement")
local Combat = require("systems.combat")
local Hud = require("ui.hud")
local AI = require("systems.ai")
local Abilities = require("systems.abilities")
local Progression = require("systems.progression")
local Health = require("systems.health")
local Collision = require("systems.collision")
local BossDefs = require("data.bosses")
local AbilityDefs = require("data.abilities")
local EnemyDefs = require("data.enemies")

local Level01 = {}
Level01.__index = Level01

function Level01.new(context)
  local self = setmetatable({}, Level01)
  self.context = context
  self.hud = Hud.new(self.context.assets)
  self.messages = {}
  self.final_triggered = false
  self.segments = {}
  self.current_segment = 1
  return self
end

function Level01:enter()
  local settings = self.context.settings
  local constants = self.context.constants

  self.world = {
    width = settings.width * 3,
    height = settings.height,
    gravity = constants.gravity,
    platforms = {},
  }
  self.collision_world = Collision.new_world(32)

  local floor_y = settings.height - 40
  table.insert(self.world.platforms, { x = 0, y = floor_y, w = self.world.width, h = 40 })
  table.insert(self.world.platforms, { x = 280, y = floor_y - 120, w = 140, h = 20 })
  table.insert(self.world.platforms, { x = 620, y = floor_y - 200, w = 160, h = 20 })
  table.insert(self.world.platforms, { x = 980, y = floor_y - 140, w = 160, h = 20 })
  for _, platform in ipairs(self.world.platforms) do
    platform.tag = "platform"
    platform.is_trigger = false
    platform.alive = true
    Collision.add(self.collision_world, platform)
  end

  self.spawn = { x = 80, y = floor_y - constants.player.height }
  self.player = Player.new(self.spawn.x, self.spawn.y, constants.player)
  self.player.on_ground = true
  Collision.add(self.collision_world, self.player)

  Abilities.init_player(self.player)
  Progression.init_player(self.player)

  self.enemies = {
    Enemy.new(320, floor_y - EnemyDefs.grunt.height, EnemyDefs.grunt, 240, 460),
    Enemy.new(520, floor_y - EnemyDefs.rusher.height, EnemyDefs.rusher, 480, 640),
    Enemy.new(760, floor_y - EnemyDefs.grunt.height, EnemyDefs.grunt, 700, 900),
    Enemy.new(1120, floor_y - EnemyDefs.mini_boss.height, EnemyDefs.mini_boss, 1080, 1260),
  }
  for _, enemy in ipairs(self.enemies) do
    Collision.add(self.collision_world, enemy)
  end

  local boss_width = constants.boss.width
  local boss_height = constants.boss.height

  self.bosses = {
    Boss.new(BossDefs[1], 1500, floor_y - boss_height, boss_width, boss_height),
    Boss.new(BossDefs[2], 1850, floor_y - boss_height, boss_width, boss_height),
    Boss.new(BossDefs[3], 2300, floor_y - boss_height, boss_width, boss_height),
  }
  for _, boss in ipairs(self.bosses) do
    boss.damage = constants.boss.damage
    Collision.add(self.collision_world, boss)
  end
  self.bosses[1]:set_patrol_bounds(1420, 1640)
  self.bosses[2]:set_patrol_bounds(1760, 1980)
  self.bosses[3]:set_patrol_bounds(2180, 2450)

  self.final_boss = self.bosses[#self.bosses]

  self.pickups = {
    Pickup.new(420, floor_y - 80, constants.pickup.heal_amount),
    Pickup.new(1100, floor_y - 80, constants.pickup.heal_amount),
    Pickup.new(1780, floor_y - 80, constants.pickup.heal_amount),
  }
  for _, pickup in ipairs(self.pickups) do
    Collision.add(self.collision_world, pickup)
  end

  self.mask_drops = {}

  self.unmask_trigger = {
    x = 1240,
    y = floor_y - 80,
    w = 60,
    h = 60,
    used = false,
    tag = "unmask",
    is_trigger = true,
    in_world = false,
  }
  Collision.add(self.collision_world, self.unmask_trigger)

  self.segments = {
    {
      start_x = 0,
      gate_x = 980,
      locked = true,
      enemies = { self.enemies[1], self.enemies[2], self.enemies[3] },
      bosses = {},
    },
    {
      start_x = 980,
      gate_x = 1500,
      locked = true,
      enemies = { self.enemies[4] },
      bosses = {},
    },
    {
      start_x = 1500,
      gate_x = 2100,
      locked = true,
      enemies = {},
      bosses = { self.bosses[1], self.bosses[2] },
    },
    {
      start_x = 2100,
      gate_x = 2600,
      locked = true,
      enemies = {},
      bosses = { self.bosses[3] },
    },
  }

  self.camera = Camera(settings.width / 2, settings.height / 2)
end

local function update_timers(level, dt)
  local player = level.player
  if player.hurt_timer > 0 then
    player.hurt_timer = math.max(0, player.hurt_timer - dt)
  end
  if player.invulnerable_timer > 0 then
    player.invulnerable_timer = math.max(0, player.invulnerable_timer - dt)
  end
  if player.flash_timer and player.flash_timer > 0 then
    player.flash_timer = math.max(0, player.flash_timer - dt)
  end
  for _, enemy in ipairs(level.enemies or {}) do
    if enemy.flash_timer and enemy.flash_timer > 0 then
      enemy.flash_timer = math.max(0, enemy.flash_timer - dt)
    end
  end
  for _, boss in ipairs(level.bosses or {}) do
    if boss.flash_timer and boss.flash_timer > 0 then
      boss.flash_timer = math.max(0, boss.flash_timer - dt)
    end
  end
end

local function player_hit(player, damage, hurt_cooldown)
  if player.hurt_timer > 0 then
    return false
  end

  local died = Health.damage(player, damage)
  player.hurt_timer = hurt_cooldown
  player.invulnerable_timer = math.max(player.invulnerable_timer, hurt_cooldown)
  player.flash_timer = hurt_cooldown

  if died then
    player.health = player.max_health
    return true
  end

  return false
end

local function collect_pickups(player, pickups, collision_world)
  local overlaps = Collision.query_rect(
    collision_world,
    player.x,
    player.y,
    player.w,
    player.h,
    function(item)
      return item.tag == "pickup" and not item.collected
    end
  )

  for _, pickup in ipairs(overlaps) do
    pickup.collected = true
    Collision.remove(collision_world, pickup)
    Health.heal(player, pickup.amount)
  end
end

local function collect_mask_drops(player, drops, ability_defs, collision_world)
  local overlaps = Collision.query_rect(
    collision_world,
    player.x,
    player.y,
    player.w,
    player.h,
    function(item)
      return item.tag == "mask_drop" and not item.collected
    end
  )

  for _, drop in ipairs(overlaps) do
    drop.collected = true
    Collision.remove(collision_world, drop)
    Abilities.grant(player, drop.ability_id, ability_defs)
  end
end

local function spawn_mask_drop(level, boss, ability_id)
  if not ability_id then
    return
  end
  local drop = MaskDrop.new(boss.x + boss.w / 2 - 9, boss.y - 20, ability_id)
  table.insert(level.mask_drops, drop)
  Collision.add(level.collision_world, drop)
end

local function player_overlaps_trigger(level, trigger)
  local overlaps = Collision.query_rect(
    level.collision_world,
    level.player.x,
    level.player.y,
    level.player.w,
    level.player.h,
    function(item)
      return item == trigger
    end
  )
  return #overlaps > 0
end

local function build_messages(level)
  local player = level.player
  local unmask_trigger = level.unmask_trigger
  local messages = {}
  if player.mode == "offensive" then
    table.insert(messages, "Modo ofensivo: absorve mascaras ao derrotar inimigos.")
  else
    table.insert(messages, "Modo defensivo: liberta mascaras ao derrotar inimigos.")
  end
  table.insert(messages, "Dash: Shift | Especial: Q | Interagir: E")

  if
    unmask_trigger
    and not unmask_trigger.used
    and player_overlaps_trigger(level, unmask_trigger)
  then
    table.insert(messages, "Pressione E para libertar sua mascara.")
  end

  return messages
end

local function segment_cleared(segment)
  for _, enemy in ipairs(segment.enemies) do
    if enemy.alive then
      return false
    end
  end
  for _, boss in ipairs(segment.bosses) do
    if boss.alive then
      return false
    end
  end
  return true
end

local function collect_contacts(level, predicate)
  local hits = {}
  local function scan(cols)
    for _, col in ipairs(cols or {}) do
      local other = col.other
      if other and predicate(other) then
        hits[other] = true
      end
    end
  end

  scan(level.player.collisions)
  for _, enemy in ipairs(level.enemies) do
    scan(enemy.collisions)
  end
  for _, boss in ipairs(level.bosses) do
    scan(boss.collisions)
  end

  return hits
end

function Level01:update(dt)
  update_timers(self, dt)

  AI.update(self.enemies, self.player, self.context.constants.enemy.agro_range, dt)

  for _, boss in ipairs(self.bosses) do
    boss:update_behavior(self.player, dt, self.context.constants.boss.agro_range)
  end

  Movement.update_player(self.player, self.context.input, self.world, self.collision_world, dt)
  Movement.update_enemies(self.enemies, self.world, self.collision_world, dt)
  Movement.update_enemies(self.bosses, self.world, self.collision_world, dt)

  Combat.update(
    self.player,
    self.context.input,
    self.enemies,
    self.context.constants,
    AbilityDefs,
    dt,
    self.collision_world,
    "enemy"
  )
  Combat.update(
    self.player,
    self.context.input,
    self.bosses,
    self.context.constants,
    AbilityDefs,
    dt,
    self.collision_world,
    "boss"
  )

  collect_pickups(self.player, self.pickups, self.collision_world)
  collect_mask_drops(self.player, self.mask_drops, AbilityDefs, self.collision_world)

  if
    not self.unmask_trigger.used
    and self.player.mode == "offensive"
    and player_overlaps_trigger(self, self.unmask_trigger)
    and self.context.input:pressed("interact")
  then
    self.player:unmask()
    self.unmask_trigger.used = true
    Collision.remove(self.collision_world, self.unmask_trigger)
  end

  local enemy_hits = collect_contacts(self, function(item)
    return item.is_enemy and item.alive
  end)
  for enemy in pairs(enemy_hits) do
    if enemy.active and enemy.attack_active then
      player_hit(self.player, enemy.damage, self.context.constants.player.hurt_cooldown)
    end
  end

  local boss_hits = collect_contacts(self, function(item)
    return item.is_boss and item.alive
  end)
  for boss in pairs(boss_hits) do
    player_hit(self.player, boss.damage, self.context.constants.player.hurt_cooldown)
  end

  for _, enemy in ipairs(self.enemies) do
    if not enemy.alive and enemy.in_world then
      Collision.remove(self.collision_world, enemy)
    end
  end

  for _, boss in ipairs(self.bosses) do
    if not boss.alive and not boss.drop_spawned then
      local reward = self.player.mode == "offensive" and boss.reward_offensive
        or boss.reward_defensive
      spawn_mask_drop(self, boss, reward)
      boss.drop_spawned = true
    end
    if not boss.alive and boss.in_world then
      Collision.remove(self.collision_world, boss)
    end
  end

  if self.final_boss and not self.final_boss.alive and not self.final_triggered then
    local Final = require("scenes.final")
    local outcome = Progression.final_outcome(self.player)
    self.final_triggered = true
    self.context.state.switch(Final.new(self.context, outcome))
    return
  end

  for _, segment in ipairs(self.segments) do
    if segment.locked and segment_cleared(segment) then
      segment.locked = false
    end
  end

  local current_segment = self.segments[self.current_segment]
  if current_segment and not current_segment.locked and self.player.x > current_segment.gate_x then
    self.current_segment = math.min(self.current_segment + 1, #self.segments)
  end

  local active_segment = self.segments[self.current_segment]
  if active_segment and active_segment.locked and self.player.x > active_segment.gate_x then
    self.player.x = active_segment.gate_x - self.player.w
    Collision.sync(self.collision_world, self.player)
  end

  if self.player.y > self.world.height + 200 then
    self.player:reset(self.spawn.x, self.spawn.y)
    Collision.sync(self.collision_world, self.player)
  end

  self.messages = build_messages(self)

  if self.context.input:pressed("pause") then
    local Menu = require("scenes.menu")
    self.context.state.switch(Menu.new(self.context))
  end
end

function Level01:draw()
  local half_w = self.context.settings.width / 2
  local half_h = self.context.settings.height / 2
  local target_x = self.player.x + self.player.w / 2
  local target_y = self.player.y + self.player.h / 2
  local max_x = math.max(half_w, self.world.width - half_w)
  local max_y = math.max(half_h, self.world.height - half_h)
  local cam_x = math.max(half_w, math.min(max_x, target_x))
  local cam_y = math.max(half_h, math.min(max_y, target_y))
  self.camera:lookAt(cam_x, cam_y)
  self.camera:attach()

  love.graphics.clear(0.08, 0.1, 0.12)
  love.graphics.setColor(0.2, 0.2, 0.2)
  for _, platform in ipairs(self.world.platforms) do
    love.graphics.rectangle("fill", platform.x, platform.y, platform.w, platform.h)
  end

  for _, segment in ipairs(self.segments) do
    if segment.locked then
      love.graphics.setColor(0.6, 0.2, 0.2, 0.6)
      love.graphics.rectangle("fill", segment.gate_x - 4, self.world.height - 140, 8, 120)
    end
  end

  if not self.unmask_trigger.used then
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle(
      "line",
      self.unmask_trigger.x,
      self.unmask_trigger.y,
      self.unmask_trigger.w,
      self.unmask_trigger.h
    )
  end

  for _, pickup in ipairs(self.pickups) do
    pickup:draw()
  end

  for _, drop in ipairs(self.mask_drops) do
    drop:draw()
  end

  for _, enemy in ipairs(self.enemies) do
    enemy:draw()
  end

  for _, boss in ipairs(self.bosses) do
    boss:draw()
  end

  self.player:draw()

  if self.player.attack_timer > 0 then
    local hitbox = self.player:attack_box(self.context.constants.player)
    love.graphics.setColor(1, 0.8, 0.2, 0.5)
    love.graphics.rectangle("fill", hitbox.x, hitbox.y, hitbox.w, hitbox.h)
  end

  self.camera:detach()

  self.hud:draw(self.player, AbilityDefs, self.messages, self.bosses, self.context.settings)
end

return Level01
