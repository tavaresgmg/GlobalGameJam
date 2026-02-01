local Abilities = require("systems.abilities")
local Collision = require("systems.collision")
local Health = require("systems.health")
local MaskDrop = require("entities.mask_drop")

local Collectables = {}

function Collectables.collect_pickups(player, pickups, collision_world)
  if not collision_world then
    return
  end

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

function Collectables.collect_mask_drops(player, drops, ability_defs, collision_world)
  if not collision_world then
    return
  end

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

function Collectables.spawn_mask_drop(drops, collision_world, boss, ability_id)
  if not ability_id then
    return nil
  end
  local drop = MaskDrop.new(boss.x + boss.w / 2 - 9, boss.y - 20, ability_id)
  table.insert(drops, drop)
  Collision.add(collision_world, drop)
  return drop
end

return Collectables
