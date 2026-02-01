local Collision = require("systems.collision")

local Triggers = {}

function Triggers.overlaps(collision_world, player, trigger)
  if not collision_world or not trigger then
    return false
  end

  local overlaps = Collision.query_rect(
    collision_world,
    player.x,
    player.y,
    player.w,
    player.h,
    function(item)
      return item == trigger
    end
  )

  return #overlaps > 0
end

function Triggers.try_unmask(player, trigger, collision_world, input)
  if not trigger or trigger.used or player.mode ~= "offensive" then
    return false
  end

  if Triggers.overlaps(collision_world, player, trigger) and input:pressed("interact") then
    player:unmask()
    trigger.used = true
    Collision.remove(collision_world, trigger)
    return true
  end

  return false
end

return Triggers
