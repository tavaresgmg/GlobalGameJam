local Camera = require("support.hump.camera")
local Player = require("entities.player")
local Enemy = require("entities.enemy")
local Boss = require("entities.boss")
local Pickup = require("entities.pickup")
local Movement = require("systems.movement")
local Combat = require("systems.combat")
local Particles = require("systems.particles")
local Collectables = require("systems.collectables")
local Hud = require("ui.hud")
local AI = require("systems.ai")
local Abilities = require("systems.abilities")
local Progression = require("systems.progression")
local Health = require("systems.health")
local Collision = require("systems.collision")
local Triggers = require("systems.triggers")
local LevelIndex = require("data.levels.index")
local WeaponDefs = require("data.weapons")
local BossDefs = require("data.bosses")
local AbilityDefs = require("data.abilities")
local EnemyDefs = require("data.enemies")

local Level = {}
Level.__index = Level

local function copy_list(values)
  local out = {}
  for i, value in ipairs(values or {}) do
    out[i] = value
  end
  return out
end

local function copy_map(values)
  local out = {}
  for key, value in pairs(values or {}) do
    out[key] = value
  end
  return out
end

local function build_player_state(player)
  return {
    mode = player.mode,
    unmasked = player.unmasked,
    health = player.health,
    masks_absorbed = player.masks_absorbed,
    masks_removed = player.masks_removed,
    special_charge_absorb = player.special_charge_absorb,
    special_charge_remove = player.special_charge_remove,
    special_ready_offensive = player.special_ready_offensive,
    special_ready_defensive = player.special_ready_defensive,
    special_offensive_unlocked = player.special_offensive_unlocked,
    special_defensive_unlocked = player.special_defensive_unlocked,
    active_abilities = copy_list(player.active_abilities),
    ability_set = copy_map(player.ability_set),
    weapon_index = player.weapon_index,
  }
end

local function apply_player_state(player, state, ability_defs)
  if not state then
    return
  end

  player.mode = state.mode or player.mode
  player.unmasked = state.unmasked or false
  player.masks_absorbed = state.masks_absorbed or 0
  player.masks_removed = state.masks_removed or 0
  player.special_charge_absorb = state.special_charge_absorb or 0
  player.special_charge_remove = state.special_charge_remove or 0
  player.special_ready_offensive = state.special_ready_offensive or false
  player.special_ready_defensive = state.special_ready_defensive or false
  player.special_offensive_unlocked = state.special_offensive_unlocked or false
  player.special_defensive_unlocked = state.special_defensive_unlocked or false
  player.active_abilities = copy_list(state.active_abilities)
  player.ability_set = copy_map(state.ability_set)
  if state.weapon_index and player.weapons and player.weapons[state.weapon_index] then
    player.weapon_index = state.weapon_index
  elseif player.weapons and #player.weapons > 0 then
    player.weapon_index = 1
  else
    player.weapon_index = nil
  end
  Abilities.recalculate(player, ability_defs)

  if state.health then
    player.health = math.min(state.health, player.max_health)
  end
end

local function advance_level(level)
  if level.level_index >= #LevelIndex then
    return false
  end

  local next_state = build_player_state(level.player)
  level.context.state.switch(Level.new(level.context, {
    level_index = level.level_index + 1,
    player_state = next_state,
  }))
  return true
end

function Level.new(context, opts)
  local self = setmetatable({}, Level)
  opts = opts or {}
  self.context = context
  self.assets = self.context.assets
  self.hud = Hud.new(self.context.assets)
  self.particles = Particles.new()
  self.messages = {}
  self.final_triggered = false
  self.segments = {}
  self.current_segment = 1
  self.level_index = opts.level_index or 1
  self.player_state = opts.player_state
  return self
end

function Level:enter()
  local settings = self.context.settings
  local constants = self.context.constants
  local level_module = LevelIndex[self.level_index]
  if not level_module then
    error("Nivel invalido: " .. tostring(self.level_index))
  end
  local level_data = require(level_module).build(settings, constants)

  self.world = {
    width = level_data.world.width,
    height = level_data.world.height,
    gravity = level_data.world.gravity,
    platforms = level_data.platforms,
  }
  self.background = level_data.background
  self.collision_world = Collision.new_world(32)

  local floor_y = level_data.floor_y
  for _, platform in ipairs(self.world.platforms) do
    platform.tag = "platform"
    platform.is_trigger = false
    platform.alive = true
    Collision.add(self.collision_world, platform)
  end

  self.spawn = level_data.spawn
  self.player = Player.new(self.spawn.x, self.spawn.y, constants.player, self.assets, WeaponDefs)
  self.player.on_ground = true
  Collision.add(self.collision_world, self.player)

  Abilities.init_player(self.player)
  Progression.init_player(self.player)
  apply_player_state(self.player, self.player_state, AbilityDefs)

  local function build_enemy_spawns(spawn_defs)
    local enemies = {}
    for _, spawn in ipairs(spawn_defs or {}) do
      local def = EnemyDefs[spawn.kind]
      if def then
        local platform = spawn.platform and self.world.platforms[spawn.platform] or nil
        local y = spawn.y or (platform and (platform.y - def.height)) or (floor_y - def.height)
        local left_bound = spawn.left or (platform and platform.x) or (spawn.x - 80)
        local right_bound = spawn.right
          or (platform and (platform.x + platform.w))
          or (spawn.x + 80)
        local enemy = Enemy.new(spawn.x, y, def, left_bound, right_bound, self.assets)
        if spawn.speed then
          enemy.vx = spawn.speed
        elseif spawn.speed_mult then
          enemy.vx = def.speed * spawn.speed_mult
        end
        table.insert(enemies, enemy)
      end
    end
    return enemies
  end

  self.enemies = build_enemy_spawns(level_data.enemy_spawns)
  for _, enemy in ipairs(self.enemies) do
    enemy.bound_left = 0
    enemy.bound_right = level_data.boss_limit_x or self.world.width
    Collision.add(self.collision_world, enemy)
  end

  local boss_width = constants.boss.width
  local boss_height = constants.boss.height

  self.bosses = {}
  for _, spawn in ipairs(level_data.boss_spawns or {}) do
    local def = BossDefs[spawn.boss_index]
    if def then
      local boss = Boss.new(def, spawn.x, floor_y - boss_height, boss_width, boss_height)
      table.insert(self.bosses, boss)
    end
  end
  for _, boss in ipairs(self.bosses) do
    boss.damage = constants.boss.damage
    boss.bound_left = 0
    boss.bound_right = self.world.width
    Collision.add(self.collision_world, boss)
  end

  self.final_boss = nil
  for _, boss in ipairs(self.bosses) do
    if boss.is_final then
      self.final_boss = boss
      break
    end
  end

  self.pickups = {}
  for _, spawn in ipairs(level_data.pickup_spawns or {}) do
    table.insert(self.pickups, Pickup.new(spawn.x, spawn.y, constants.pickup.heal_amount))
  end
  for _, pickup in ipairs(self.pickups) do
    Collision.add(self.collision_world, pickup)
  end

  self.mask_drops = {}

  self.unmask_trigger = level_data.unmask_trigger
  if self.unmask_trigger then
    if self.player.mode ~= "offensive" then
      self.unmask_trigger.used = true
    end
    if not self.unmask_trigger.used then
      Collision.add(self.collision_world, self.unmask_trigger)
    end
  end

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

local function player_hit(level, player, damage, hurt_cooldown)
  if player.hurt_timer > 0 then
    return false, false
  end

  local died = Health.damage(player, damage)
  player.hurt_timer = hurt_cooldown
  player.invulnerable_timer = math.max(player.invulnerable_timer, hurt_cooldown)
  player.flash_timer = hurt_cooldown
  if level and level.particles then
    level.particles:emit_damage(player.x + player.w / 2, player.y + player.h / 2)
  end

  if died then
    return true, true
  end

  return false, true
end

local function enter_game_over(level)
  local GameOver = require("scenes.gameover")
  level.context.state.switch(GameOver.new(level.context, level.level_index))
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
  table.insert(messages, "Dash: Shift | Trocar arma: Q | Especial: R | Interagir: E")

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
  for _, col in ipairs(player.collisions or {}) do
    if col.other == entity then
      return true
    end
  end
  return false
end

local function draw_layer(image, world_width, world_height, camera, speed)
  if not image then
    return
  end
  local iw, ih = image:getWidth(), image:getHeight()
  if iw <= 0 or ih <= 0 then
    return
  end
  local scale = world_height / ih
  local scaled_w = iw * scale
  local x = camera.x * (speed or 1)
  local start_x = -x % scaled_w - scaled_w
  for draw_x = start_x, world_width + scaled_w, scaled_w do
    love.graphics.draw(image, draw_x, 0, 0, scale, scale)
  end
end

local function draw_ground_layer(image, world_width, floor_y, camera, scale)
  if not image then
    return
  end
  local iw, ih = image:getWidth(), image:getHeight()
  if iw <= 0 or ih <= 0 then
    return
  end
  local used_scale = scale or 1
  local scaled_w = iw * used_scale
  local y = floor_y
  local x = -camera.x
  local start_x = -x % scaled_w - scaled_w
  for draw_x = start_x, world_width + scaled_w, scaled_w do
    love.graphics.draw(image, draw_x, y, 0, used_scale, used_scale)
  end
end

function Level:update(dt)
  update_timers(self, dt)

  if self.context.input:pressed("swap_weapon") then
    self.player:swap_weapon()
  end

  local special_targets = {}
  for _, enemy in ipairs(self.enemies) do
    table.insert(special_targets, enemy)
  end
  for _, boss in ipairs(self.bosses) do
    table.insert(special_targets, boss)
  end
  Combat.use_special(
    self.player,
    self.context.input,
    special_targets,
    self.context.constants,
    AbilityDefs
  )

  AI.update(self.enemies, self.player, self.context.constants.enemy.agro_range, dt)

  for _, boss in ipairs(self.bosses) do
    boss:update_behavior(self.player, dt, self.context.constants.boss.agro_range)
  end

  Movement.update_player(self.player, self.context.input, self.world, self.collision_world, dt)
  self.player:update_animation(dt)
  Movement.update_enemies(self.enemies, self.world, self.collision_world, dt)
  Movement.update_enemies(self.bosses, self.world, self.collision_world, dt)
  for _, enemy in ipairs(self.enemies) do
    enemy:update_animation(dt)
  end
  clamp_player_to_world(self)

  local attack_started = Combat.update(
    self.player,
    self.context.input,
    self.enemies,
    self.context.constants,
    AbilityDefs,
    dt,
    self.collision_world,
    "enemy"
  )
  attack_started = Combat.update(
    self.player,
    self.context.input,
    self.bosses,
    self.context.constants,
    AbilityDefs,
    dt,
    self.collision_world,
    "boss"
  ) or attack_started

  if attack_started and self.particles then
    local weapon = self.player:current_weapon()
    local range = (weapon and weapon.attack_range) or self.context.constants.player.attack_range
    local px = self.player.x + self.player.w / 2 + (range * 0.6) * self.player.dir
    local py = self.player.y + self.player.h / 2
    self.particles:emit_attack(px, py, self.player.dir)
  end

  Collectables.collect_pickups(self.player, self.pickups, self.collision_world)
  Collectables.collect_mask_drops(self.player, self.mask_drops, AbilityDefs, self.collision_world)

  Triggers.try_unmask(self.player, self.unmask_trigger, self.collision_world, self.context.input)

  local player_died = false
  for _, enemy in ipairs(self.enemies) do
    if enemy.alive and enemy.active and entity_hits_player(enemy, self.player) then
      local died =
        player_hit(self, self.player, enemy.damage, self.context.constants.player.hurt_cooldown)
      if died then
        player_died = true
        break
      end
    end
  end

  if not player_died then
    for _, boss in ipairs(self.bosses) do
      if boss.alive and entity_hits_player(boss, self.player) then
        local died =
          player_hit(self, self.player, boss.damage, self.context.constants.player.hurt_cooldown)
        if died then
          player_died = true
          break
        end
      end
    end
  end

  if player_died then
    enter_game_over(self)
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
    if advance_level(self) then
      return
    end
    self.current_segment = math.min(self.current_segment + 1, #self.segments)
  end

  local active_segment = self.segments[self.current_segment]
  if active_segment and active_segment.locked and self.player.x > active_segment.gate_x then
    self.player.x = active_segment.gate_x - self.player.w
    Collision.sync(self.collision_world, self.player)
  end

  if self.player.y > self.world.height + 200 then
    enter_game_over(self)
    return
  end

  self.messages = build_messages(self)

  if self.context.input:pressed("pause") then
    local Pause = require("scenes.pause")
    self.context.state.switch(Pause.new(self.context, self))
  end

  if self.particles then
    self.particles:update(dt)
  end
end

function Level:draw()
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
  love.graphics.setColor(1, 1, 1)
  local background_scale = nil
  if self.background and self.background.layers then
    local bucket = self.assets
      and self.assets.backgrounds
      and self.background.bucket
      and self.assets.backgrounds[self.background.bucket]
    for index, layer in ipairs(self.background.layers) do
      local image = bucket and bucket[layer.key]
      if index == 1 and image then
        background_scale = self.world.height / image:getHeight()
      end
      draw_layer(image, self.world.width, self.world.height, self.camera, layer.speed or 1)
    end
  end

  local floor_y = self.world.platforms[1] and self.world.platforms[1].y or self.world.height
  if self.background and self.background.ground and self.assets and self.assets.backgrounds then
    local bucket = self.background.bucket and self.assets.backgrounds[self.background.bucket]
    local image = bucket and bucket[self.background.ground.key]
    draw_ground_layer(image, self.world.width, floor_y, self.camera, background_scale)
  else
    love.graphics.setColor(0.2, 0.2, 0.2)
    for _, platform in ipairs(self.world.platforms) do
      love.graphics.rectangle("fill", platform.x, platform.y, platform.w, platform.h)
    end
  end

  if self.unmask_trigger and not self.unmask_trigger.used then
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

  if self.particles then
    self.particles:draw()
  end

  self.camera:detach()

  self.hud:draw(
    self.player,
    AbilityDefs,
    self.messages,
    self.bosses,
    self.context.settings,
    self.level_index,
    #LevelIndex
  )
end

return Level
