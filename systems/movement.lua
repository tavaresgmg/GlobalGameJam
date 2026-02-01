local Collision = require("systems.collision")

local Movement = {}

local function start_dash(player)
  player.is_dashing = true
  player.dash_timer = player.dash_duration
  player.vy = 0
  if player.bonuses and player.bonuses.dash_iframe then
    player.invulnerable_timer = player.dash_duration
  end
end

local function try_jump(player)
  if player.jump_count < player.max_jumps and (player.on_ground or player.coyote_timer > 0) then
    player.vy = -player.jump_speed
    player.on_ground = false
    player.jump_count = player.jump_count + 1
    player.coyote_timer = 0
    return true
  end
  return false
end

function Movement.update_player(player, input, world, collision_world, dt)
  local move = 0

  if player.dash_cooldown_timer > 0 then
    player.dash_cooldown_timer = math.max(0, player.dash_cooldown_timer - dt)
  end

  if player.is_dashing then
    player.dash_timer = player.dash_timer - dt
    if player.dash_timer <= 0 then
      player.is_dashing = false
      player.dash_cooldown_timer = player.dash_cooldown
    end
  end

  if player.on_ground then
    player.coyote_timer = player.coyote_time
  elseif player.coyote_timer > 0 then
    player.coyote_timer = math.max(0, player.coyote_timer - dt)
  end

  if player.jump_buffer_timer > 0 then
    player.jump_buffer_timer = math.max(0, player.jump_buffer_timer - dt)
  end

  if input:pressed("jump") then
    player.jump_buffer_timer = player.jump_buffer_time
  end

  if not player.is_dashing then
    if input:down("left") then
      move = move - 1
    end
    if input:down("right") then
      move = move + 1
    end

    player.vx = move * player.speed
    if move ~= 0 then
      player.dir = move
    end

    if player.jump_buffer_timer > 0 then
      if try_jump(player) then
        player.jump_buffer_timer = 0
      end
    end

    if input:pressed("dash") and player.dash_cooldown_timer <= 0 then
      start_dash(player)
    end
  end

  if player.is_dashing then
    player.vx = player.dash_speed * player.dir
  else
    player.vy = player.vy + world.gravity * dt
  end

  local goal_x = player.x + player.vx * dt
  local goal_y = player.y + player.vy * dt

  player.on_ground = false
  local cols, len = Collision.move(collision_world, player, goal_x, goal_y)
  if cols and len and len > 0 then
    for i = 1, len do
      local col = cols[i]
      if col.normal.y < 0 then
        player.on_ground = true
        player.jump_count = 0
        player.vy = 0
      elseif col.normal.y > 0 then
        player.vy = 0
      end
    end
  end
end

function Movement.update_enemies(enemies, world, collision_world, dt)
  for _, enemy in ipairs(enemies) do
    if enemy.alive and (enemy.active or enemy.always_active) then
      local speed = enemy.vx
      if enemy.is_charging then
        speed = enemy.charge_speed
      end
      if enemy.state == "attack" or enemy.state == "cooldown" then
        speed = speed * 0.2
      end
      enemy.vy = enemy.vy + world.gravity * dt
      local goal_x = enemy.x + speed * enemy.dir * dt
      local goal_y = enemy.y + enemy.vy * dt

      if enemy.patrol_left and enemy.patrol_right and not enemy.chase_only then
        if goal_x < enemy.patrol_left then
          goal_x = enemy.patrol_left
          enemy.dir = 1
        elseif goal_x + enemy.w > enemy.patrol_right then
          goal_x = enemy.patrol_right - enemy.w
          enemy.dir = -1
        end
      end

      enemy.on_ground = false
      local cols, len = Collision.move(collision_world, enemy, goal_x, goal_y)
      if cols and len and len > 0 then
        for i = 1, len do
          local col = cols[i]
          if col.normal.y < 0 then
            enemy.on_ground = true
            enemy.vy = 0
          elseif col.normal.y > 0 then
            enemy.vy = 0
          end
        end
      end
    else
      enemy.collisions = nil
      enemy.collision_len = 0
    end
  end
end

return Movement
