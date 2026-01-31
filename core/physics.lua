local Physics = {}

function Physics.aabb(ax, ay, aw, ah, bx, by, bw, bh)
  return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

function Physics.resolve_floor(entity, platform, previous_y)
  if entity.vy < 0 then
    return false
  end

  local hit = Physics.aabb(
    entity.x,
    entity.y,
    entity.w,
    entity.h,
    platform.x,
    platform.y,
    platform.w,
    platform.h
  )

  if not hit then
    return false
  end

  if previous_y + entity.h <= platform.y then
    entity.y = platform.y - entity.h
    entity.vy = 0
    entity.on_ground = true
    return true
  end

  return false
end

return Physics
