local bump = require("support.bump")

local Collision = {}

local function filter(item, other)
  if item.is_trigger or other.is_trigger then
    return "cross"
  end
  if item.alive == false or other.alive == false then
    return "cross"
  end
  return "slide"
end

function Collision.new_world(cell_size)
  return bump.newWorld(cell_size or 32)
end

function Collision.add(world, entity)
  if entity.in_world then
    return
  end
  world:add(entity, entity.x, entity.y, entity.w, entity.h)
  entity.in_world = true
end

function Collision.remove(world, entity)
  if entity.in_world and world:hasItem(entity) then
    world:remove(entity)
    entity.in_world = false
  end
end

function Collision.sync(world, entity)
  if entity.in_world and world:hasItem(entity) then
    world:update(entity, entity.x, entity.y, entity.w, entity.h)
  end
end

function Collision.move(world, entity, goal_x, goal_y)
  if not entity.in_world or not world:hasItem(entity) then
    return nil, 0
  end

  local actual_x, actual_y, cols, len = world:move(entity, goal_x, goal_y, filter)
  entity.x, entity.y = actual_x, actual_y
  entity.collisions = cols
  entity.collision_len = len
  return cols, len
end

function Collision.query_rect(world, x, y, w, h, predicate)
  return world:queryRect(x, y, w, h, predicate)
end

return Collision
