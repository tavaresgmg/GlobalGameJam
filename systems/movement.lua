local Physics = require("core.physics")

local Movement = {}

function Movement.update_player(player, input, world, dt)
  local previous_y = player.y
  local move = 0

  if input:is_down("left") then
    move = move - 1
  end
  if input:is_down("right") then
    move = move + 1
  end

  player.vx = move * player.speed
  if move ~= 0 then
    player.dir = move
  end

  if input:consume("jump") and player.on_ground then
    player.vy = -player.jump_speed
    player.on_ground = false
  end

  player.vy = player.vy + world.gravity * dt
  player.x = player.x + player.vx * dt
  player.y = player.y + player.vy * dt

  player.on_ground = false
  for _, platform in ipairs(world.platforms) do
    if Physics.resolve_floor(player, platform, previous_y) then
      break
    end
  end
end

function Movement.update_enemies(enemies, world, dt)
  for _, enemy in ipairs(enemies) do
    if enemy.alive then
      enemy.x = enemy.x + enemy.vx * enemy.dir * dt

      if enemy.x < enemy.left_bound then
        enemy.x = enemy.left_bound
        enemy.dir = 1
      elseif enemy.x + enemy.w > enemy.right_bound then
        enemy.x = enemy.right_bound - enemy.w
        enemy.dir = -1
      end

      local previous_y = enemy.y
      enemy.vy = enemy.vy + world.gravity * dt
      enemy.y = enemy.y + enemy.vy * dt

      enemy.on_ground = false
      for _, platform in ipairs(world.platforms) do
        if Physics.resolve_floor(enemy, platform, previous_y) then
          break
        end
      end
    end
  end
end

return Movement
