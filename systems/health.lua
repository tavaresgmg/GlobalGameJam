local Health = {}

function Health.heal(entity, amount)
  if amount <= 0 then
    return
  end
  entity.health = math.min(entity.health + amount, entity.max_health)
end

function Health.damage(entity, amount)
  if amount <= 0 then
    return false
  end
  if entity.invulnerable_timer and entity.invulnerable_timer > 0 then
    return false
  end
  entity.health = math.max(0, entity.health - amount)
  return entity.health == 0
end

return Health
