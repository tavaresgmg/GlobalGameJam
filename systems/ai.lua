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

local function assign_attackers(enemies, player, max_attackers)
  local remaining = max_attackers
  for _, enemy in ipairs(enemies) do
    enemy.is_attacker = false
  end

  for _, enemy in ipairs(enemies) do
    if enemy.alive and enemy.active and enemy.force_attacker then
      enemy.is_attacker = true
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
    candidates[i].enemy.is_attacker = true
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

  assign_attackers(enemies, player, 2)

  for _, enemy in ipairs(enemies) do
    if enemy.alive then
      local dx = (player.x + player.w / 2) - (enemy.x + enemy.w / 2)
      local distance = math.abs(dx)
      local standoff_range = enemy.standoff_range or (enemy.attack_range + 40)
      local standoff_buffer = enemy.standoff_buffer or 12

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
        elseif distance <= enemy.attack_range then
          enter_state(enemy, "attack")
        else
          enemy.dir = dx >= 0 and 1 or -1
        end
      elseif enemy.state == "standoff" then
        if enemy.is_attacker then
          enter_state(enemy, "chase")
        else
          if distance < standoff_range - standoff_buffer then
            enemy.dir = dx >= 0 and -1 or 1
          elseif distance > standoff_range + standoff_buffer then
            enemy.dir = dx >= 0 and 1 or -1
          else
            enemy.dir = 0
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
