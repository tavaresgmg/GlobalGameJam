local Physics = require("core.physics")

local Combat = {}

function Combat.update(player, input, enemies, config, dt)
  if player.attack_cooldown > 0 then
    player.attack_cooldown = player.attack_cooldown - dt
  end

  if input:consume("attack") and player.attack_cooldown <= 0 then
    player.attack_timer = config.attack_duration
    player.attack_cooldown = config.attack_cooldown
  end

  if player.attack_timer <= 0 then
    return
  end

  player.attack_timer = player.attack_timer - dt
  local hitbox = player:attack_box(config)

  for _, enemy in ipairs(enemies) do
    if enemy.alive then
      local hit =
        Physics.aabb(hitbox.x, hitbox.y, hitbox.w, hitbox.h, enemy.x, enemy.y, enemy.w, enemy.h)

      if hit then
        enemy:take_hit()
      end
    end
  end
end

return Combat
