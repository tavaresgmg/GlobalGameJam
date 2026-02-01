local Progression = require("systems.progression")
local Collision = require("systems.collision")

local Combat = {}

local function apply_damage(player, target, damage, constants, ability_defs)
  local defeated = target:take_hit(damage, player.mode)
  if not defeated then
    local flash = constants.enemy.hit_flash_duration
    local knockback = constants.enemy.knockback_force
    if target.is_boss then
      flash = constants.boss.hit_flash_duration
      knockback = constants.boss.knockback_force
    end
    target.flash_timer = flash
    target.vx = knockback
    target.dir = player.dir
  end
  if defeated then
    if target.is_boss then
      Progression.on_boss_defeated(player, target, ability_defs)
    else
      Progression.on_mask_result(player, player.mode, constants, ability_defs)
    end
  end
end

local function special_damage_for_mode(player, constants)
  if player.mode == "offensive" then
    return constants.player.special_damage_offensive
  end
  return constants.player.special_damage_defensive
end

function Combat.use_special(player, input, targets, constants, ability_defs)
  if not input:pressed("special") then
    return false
  end
  if not Progression.is_special_ready(player) then
    return false
  end

  local range = constants.player.special_range
  local damage = special_damage_for_mode(player, constants)
  local range_sq = range * range

  for _, target in ipairs(targets) do
    if target.alive then
      local dx = (target.x + target.w / 2) - (player.x + player.w / 2)
      local dy = (target.y + target.h / 2) - (player.y + player.h / 2)
      if dx * dx + dy * dy <= range_sq then
        apply_damage(player, target, damage, constants, ability_defs)
      end
    end
  end

  Progression.consume_special(player)
  return true
end

local function hit_targets_in_hitbox(collision_world, hitbox, target_tag)
  if not collision_world then
    return nil
  end
  return Collision.query_rect(
    collision_world,
    hitbox.x,
    hitbox.y,
    hitbox.w,
    hitbox.h,
    function(item)
      return item.tag == target_tag and item.alive
    end
  )
end

function Combat.update(
  player,
  input,
  targets,
  constants,
  ability_defs,
  dt,
  collision_world,
  target_tag
)
  if player.attack_cooldown > 0 then
    player.attack_cooldown = player.attack_cooldown - dt
  end

  Combat.use_special(player, input, targets, constants, ability_defs)

  if input:pressed("attack") and player.attack_cooldown <= 0 then
    player.attack_timer = constants.player.attack_duration
    player.attack_cooldown = constants.player.attack_cooldown
    player.attack_hits = {}
  end

  if player.attack_timer <= 0 then
    return
  end

  player.attack_timer = player.attack_timer - dt
  local hitbox = player:attack_box(constants.player)
  local damage = constants.player.attack_damage * (1 + player.bonuses.attack_mult)
  local hit_targets = hit_targets_in_hitbox(collision_world, hitbox, target_tag) or targets

  for _, target in ipairs(hit_targets) do
    if target.alive then
      if not player.attack_hits[target] then
        apply_damage(player, target, damage, constants, ability_defs)
        player.attack_hits[target] = true
      end
    end
  end
end

return Combat
