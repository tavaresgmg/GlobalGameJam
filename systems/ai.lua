local AI = {}

local function enter_state(enemy, state)
  enemy.state = state
  if state == "alert" then
    enemy.state_timer = 0.25
  elseif state == "attack" then
    enemy.attack_timer = enemy.attack_windup
    enemy.attack_active = false
  elseif state == "cooldown" then
    enemy.cooldown_timer = enemy.attack_cooldown
  elseif state == "standoff" then
    enemy.standoff_timer = 0.25
  elseif state == "evade" then
    enemy.evade_timer = enemy.evade_duration or 0.2
  end
end

local function call_allies(enemies, caller)
  for _, enemy in ipairs(enemies) do
    if enemy.alive and enemy ~= caller then
      local dx = (enemy.x + enemy.w / 2) - (caller.x + caller.w / 2)
      if math.abs(dx) <= caller.call_range then
        enemy.active = true
        if enemy.state == "idle" then
          enter_state(enemy, "alert")
        end
      end
    end
  end
end

local function count_active(enemies)
  local count = 0
  for _, enemy in ipairs(enemies) do
    if enemy.alive and enemy.active then
      count = count + 1
    end
  end
  return count
end

local function player_is_attacking(player)
  return (player.attack_timer and player.attack_timer > 0)
    or (player.attack_cooldown and player.attack_cooldown > 0)
end

local function ensure_flank_sides(enemies)
  local left_count = 0
  local right_count = 0
  for _, enemy in ipairs(enemies) do
    if enemy.alive and enemy.active and enemy.flank_side then
      if enemy.flank_side < 0 then
        left_count = left_count + 1
      else
        right_count = right_count + 1
      end
    end
  end

  for _, enemy in ipairs(enemies) do
    if enemy.alive and enemy.active and not enemy.flank_side then
      if left_count <= right_count then
        enemy.flank_side = -1
        left_count = left_count + 1
      else
        enemy.flank_side = 1
        right_count = right_count + 1
      end
    end
  end
end

local function update_speed(enemy, distance)
  local base = enemy.base_speed or enemy.vx or 0
  local mult = 1
  if enemy.sprint_range and enemy.sprint_mult and distance > enemy.sprint_range then
    mult = enemy.sprint_mult
  end
  enemy.vx = base * mult
end

local function flank_dir(enemy, player)
  local offset = enemy.flank_offset or (enemy.attack_range + 50)
  local tolerance = enemy.flank_tolerance or 10
  local target_x = (player.x + player.w / 2) + (enemy.flank_side or 1) * offset
  local enemy_center = enemy.x + enemy.w / 2
  if math.abs(enemy_center - target_x) <= tolerance then
    return 0
  end
  return enemy_center < target_x and 1 or -1
end

local function assign_attackers(enemies, player, max_attackers, dt)
  local remaining = max_attackers
  for _, enemy in ipairs(enemies) do
    if enemy.attack_lock_timer and enemy.attack_lock_timer > 0 then
      enemy.attack_lock_timer = math.max(0, enemy.attack_lock_timer - dt)
      if enemy.is_attacker then
        remaining = remaining - 1
      end
    else
      enemy.is_attacker = false
    end
  end

  for _, enemy in ipairs(enemies) do
    if enemy.alive and enemy.active and enemy.force_attacker then
      if not enemy.is_attacker then
        enemy.is_attacker = true
        enemy.attack_lock_timer = enemy.attack_lock_time or 0.8
      end
      remaining = remaining - 1
    end
  end

  if remaining <= 0 then
    return
  end

  local candidates = {}
  for _, enemy in ipairs(enemies) do
    if enemy.alive and enemy.active and not enemy.is_attacker then
      local dx = (player.x + player.w / 2) - (enemy.x + enemy.w / 2)
      local score = math.abs(dx) - (enemy.attack_priority or 0) * 10
      table.insert(candidates, { enemy = enemy, score = score })
    end
  end

  table.sort(candidates, function(a, b)
    return a.score < b.score
  end)

  for i = 1, math.min(remaining, #candidates) do
    local enemy = candidates[i].enemy
    enemy.is_attacker = true
    enemy.attack_lock_timer = enemy.attack_lock_time or 0.8
  end
end

function AI.update(enemies, player, default_range, dt)
  for _, enemy in ipairs(enemies) do
    if enemy.alive then
      local range = enemy.agro_range or default_range
      local dx = (player.x + player.w / 2) - (enemy.x + enemy.w / 2)
      local distance = math.abs(dx)

      if enemy.always_active then
        enemy.active = true
      else
        enemy.active = distance <= range
      end

      if enemy.active and enemy.state == "idle" then
        enter_state(enemy, "alert")
        call_allies(enemies, enemy)
      end
    end
  end

  ensure_flank_sides(enemies)

  local active_count = count_active(enemies)
  local max_attackers = math.min(3, math.max(1, math.ceil(active_count / 3)))
  assign_attackers(enemies, player, max_attackers, dt)

  for _, enemy in ipairs(enemies) do
    if enemy.alive then
      local dx = (player.x + player.w / 2) - (enemy.x + enemy.w / 2)
      local distance = math.abs(dx)
      if enemy.dir ~= 0 then
        enemy.face_dir = enemy.dir
      elseif enemy.face_lock_distance and distance > enemy.face_lock_distance then
        enemy.face_dir = dx >= 0 and 1 or -1
      elseif not enemy.face_dir then
        enemy.face_dir = dx >= 0 and 1 or -1
      end
      local contact_gap = math.max(0, distance - (player.w / 2 + enemy.w / 2))
      local standoff_range = enemy.standoff_range or (enemy.attack_range + 40)
      local standoff_buffer = enemy.standoff_buffer or 12
      local player_attacking = player_is_attacking(player)

      update_speed(enemy, distance)

      if enemy.flank_timer and enemy.flank_timer > 0 then
        enemy.flank_timer = math.max(0, enemy.flank_timer - dt)
      elseif enemy.flank_switch_time then
        enemy.flank_timer = enemy.flank_switch_time
        if enemy.flank_side and enemy.flank_switch_chance then
          if math.random() <= enemy.flank_switch_chance then
            enemy.flank_side = -enemy.flank_side
          end
        end
      end

      if enemy.evade_cooldown_timer and enemy.evade_cooldown_timer > 0 then
        enemy.evade_cooldown_timer = math.max(0, enemy.evade_cooldown_timer - dt)
      end

      if not enemy.active then
        enemy.dir = 0
        enemy.state = "idle"
      elseif enemy.state == "alert" then
        enemy.state_timer = enemy.state_timer - dt
        if enemy.state_timer <= 0 then
          if enemy.is_attacker then
            enter_state(enemy, "chase")
          else
            enter_state(enemy, "standoff")
          end
        end
      elseif enemy.state == "chase" then
        if not enemy.is_attacker then
          enter_state(enemy, "standoff")
        elseif
          enemy.evade_duration
          and enemy.evade_cooldown_timer <= 0
          and player_attacking
          and contact_gap <= (enemy.evade_range or enemy.attack_range)
        then
          enemy.evade_cooldown_timer = enemy.evade_cooldown or 0.9
          enter_state(enemy, "evade")
        elseif contact_gap <= enemy.attack_range then
          enter_state(enemy, "attack")
        else
          enemy.dir = dx >= 0 and 1 or -1
        end
      elseif enemy.state == "standoff" then
        if enemy.is_attacker then
          enter_state(enemy, "chase")
        else
          if
            enemy.evade_duration
            and enemy.evade_cooldown_timer <= 0
            and player_attacking
            and contact_gap <= (enemy.evade_range or enemy.attack_range)
          then
            enemy.evade_cooldown_timer = enemy.evade_cooldown or 0.9
            enter_state(enemy, "evade")
          else
            local hold_range = (enemy.attack_range or 0) * 0.6
            if contact_gap > standoff_range + standoff_buffer then
              enemy.dir = flank_dir(enemy, player)
            elseif contact_gap < hold_range then
              enemy.dir = 0
            else
              enemy.dir = 0
            end
          end
        end
      elseif enemy.state == "evade" then
        if enemy.evade_timer > 0 then
          enemy.evade_timer = enemy.evade_timer - dt
          enemy.dir = dx >= 0 and -1 or 1
        else
          if enemy.is_attacker then
            enter_state(enemy, "chase")
          else
            enter_state(enemy, "standoff")
          end
        end
      elseif enemy.state == "attack" then
        enemy.attack_timer = enemy.attack_timer - dt
        if enemy.attack_timer <= 0 then
          enemy.attack_active = true
          enemy.attack_timer = enemy.attack_duration
          enter_state(enemy, "cooldown")
        end
      elseif enemy.state == "cooldown" then
        if enemy.attack_active then
          enemy.attack_timer = enemy.attack_timer - dt
          if enemy.attack_timer <= 0 then
            enemy.attack_active = false
          end
        end
        enemy.cooldown_timer = enemy.cooldown_timer - dt
        if enemy.cooldown_timer <= 0 then
          if enemy.is_attacker then
            enter_state(enemy, "chase")
          else
            enter_state(enemy, "standoff")
          end
        end
      end
    end
  end
end

return AI
