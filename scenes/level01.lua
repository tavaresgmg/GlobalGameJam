local Camera = require("support.hump.camera")
local Player = require("entities.player")
local Enemy = require("entities.enemy")
local Boss = require("entities.boss")
local Pickup = require("entities.pickup")
local Movement = require("systems.movement")
local Combat = require("systems.combat")
local Collectables = require("systems.collectables")
local Hud = require("ui.hud")
local AI = require("systems.ai")
local Abilities = require("systems.abilities")
local Progression = require("systems.progression")
local Health = require("systems.health")
local Collision = require("systems.collision")
local Triggers = require("systems.triggers")
local LevelData = require("data.level01")
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
  local level_data = LevelData.build(settings, constants)

  self.world = {
    width = level_data.world.width,
    height = level_data.world.height,
    gravity = level_data.world.gravity,
    platforms = level_data.platforms,
  }
  self.collision_world = Collision.new_world(32)

  local floor_y = level_data.floor_y
  for _, platform in ipairs(self.world.platforms) do
    platform.tag = "platform"
    platform.is_trigger = false
    platform.alive = true
    Collision.add(self.collision_world, platform)
  end

  self.spawn = level_data.spawn
  self.player = Player.new(self.spawn.x, self.spawn.y, constants.player)
  self.player.on_ground = true
  Collision.add(self.collision_world, self.player)

  Abilities.init_player(self.player)
  Progression.init_player(self.player)

  local function build_enemy_spawns(spawn_defs)
    local enemies = {}
    for _, spawn in ipairs(spawn_defs or {}) do
      local def = EnemyDefs[spawn.kind]
      if def then
        local platform = spawn.platform and self.world.platforms[spawn.platform] or nil
        local y = spawn.y
          or (platform and (platform.y - def.height))
          or (floor_y - def.height)
        local left_bound = spawn.left
          or (platform and platform.x)
          or (spawn.x - 80)
        local right_bound = spawn.right
          or (platform and (platform.x + platform.w))
          or (spawn.x + 80)
        table.insert(enemies, Enemy.new(spawn.x, y, def, left_bound, right_bound))
      end
    end
    return enemies
  end

  self.enemies = build_enemy_spawns(level_data.enemy_spawns)
  for _, enemy in ipairs(self.enemies) do
    Collision.add(self.collision_world, enemy)
  end

  local boss_width = constants.boss.width
  local boss_height = constants.boss.height

  self.bosses = {
    Boss.new(BossDefs[1], 1700, floor_y - boss_height, boss_width, boss_height),
    Boss.new(BossDefs[2], 2900, floor_y - boss_height, boss_width, boss_height),
    Boss.new(BossDefs[3], 4100, floor_y - boss_height, boss_width, boss_height),
  }
  for _, boss in ipairs(self.bosses) do
    boss.damage = constants.boss.damage
    Collision.add(self.collision_world, boss)
  end

  self.final_boss = self.bosses[#self.bosses]

  self.pickups = {
    Pickup.new(520, floor_y - 80, constants.pickup.heal_amount),
    Pickup.new(1320, floor_y - 80, constants.pickup.heal_amount),
    Pickup.new(2080, floor_y - 80, constants.pickup.heal_amount),
    Pickup.new(2760, floor_y - 80, constants.pickup.heal_amount),
    Pickup.new(3440, floor_y - 80, constants.pickup.heal_amount),
    Pickup.new(4080, floor_y - 80, constants.pickup.heal_amount),
    Pickup.new(4680, floor_y - 80, constants.pickup.heal_amount),
  }
  for _, pickup in ipairs(self.pickups) do
    Collision.add(self.collision_world, pickup)
  end

  self.mask_drops = {}

  self.unmask_trigger = level_data.unmask_trigger
  Collision.add(self.collision_world, self.unmask_trigger)

  local function resolve_entities(list, ids)
    local items = {}
    for _, id in ipairs(ids or {}) do
      local entity = list[id]
      if entity then
        table.insert(items, entity)
      end
    end
    return items
  end

  self.segments = {}
  for _, segment_def in ipairs(level_data.segments) do
    table.insert(self.segments, {
      start_x = segment_def.start_x,
      gate_x = segment_def.gate_x,
      locked = segment_def.locked,
      enemies = resolve_entities(self.enemies, segment_def.enemy_ids),
      bosses = resolve_entities(self.bosses, segment_def.boss_ids),
    })
  end

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

local function restart_level(level)
  level.context.state.switch(Level01.new(level.context))
end

local function clamp_player_to_world(level)
  if level.player.x < 0 then
    level.player.x = 0
    level.player.vx = 0
    Collision.sync(level.collision_world, level.player)
  end
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
    and Triggers.overlaps(level.collision_world, player, unmask_trigger)
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

local function entity_hits_player(entity, player)
  for _, col in ipairs(entity.collisions or {}) do
    if col.other == player then
      return true
    end
  end
  return false
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
  clamp_player_to_world(self)

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

  Collectables.collect_pickups(self.player, self.pickups, self.collision_world)
  Collectables.collect_mask_drops(self.player, self.mask_drops, AbilityDefs, self.collision_world)

  Triggers.try_unmask(self.player, self.unmask_trigger, self.collision_world, self.context.input)

  local player_died = false
  for _, enemy in ipairs(self.enemies) do
    if enemy.alive and enemy.active and entity_hits_player(enemy, self.player) then
      if player_hit(self.player, enemy.damage, self.context.constants.player.hurt_cooldown) then
        player_died = true
        break
      end
    end
  end

  if not player_died then
    for _, boss in ipairs(self.bosses) do
      if boss.alive and entity_hits_player(boss, self.player) then
        if player_hit(self.player, boss.damage, self.context.constants.player.hurt_cooldown) then
          player_died = true
          break
        end
      end
    end
  end

  if player_died then
    restart_level(self)
    return
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
      Collectables.spawn_mask_drop(self.mask_drops, self.collision_world, boss, reward)
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
    restart_level(self)
    return
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
