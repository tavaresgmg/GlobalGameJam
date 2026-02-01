local Abilities = {}

function Abilities.init_player(player)
  player.active_abilities = {}
  player.ability_set = {}
  player.bonuses = {
    attack_mult = 0,
    dash_iframe = false,
    max_health_bonus = 0,
  }
  player.special_offensive_unlocked = false
  player.special_defensive_unlocked = false
end

function Abilities.recalculate(player, ability_defs)
  player.bonuses = {
    attack_mult = 0,
    dash_iframe = false,
    max_health_bonus = 0,
  }

  for _, ability_id in ipairs(player.active_abilities) do
    local ability = ability_defs[ability_id]
    if ability and ability.passive then
      if ability.passive.attack_mult then
        player.bonuses.attack_mult = player.bonuses.attack_mult + ability.passive.attack_mult
      end
      if ability.passive.dash_iframe then
        player.bonuses.dash_iframe = true
      end
      if ability.passive.max_health_bonus then
        player.bonuses.max_health_bonus = player.bonuses.max_health_bonus
          + ability.passive.max_health_bonus
      end
    end
  end

  player.max_health = player.base_max_health + player.bonuses.max_health_bonus
  if player.health > player.max_health then
    player.health = player.max_health
  end
end

function Abilities.grant(player, ability_id, ability_defs)
  if not ability_id then
    return false
  end
  if player.ability_set[ability_id] then
    return false
  end
  if #player.active_abilities >= player.max_abilities then
    return false
  end

  table.insert(player.active_abilities, ability_id)
  player.ability_set[ability_id] = true
  Abilities.recalculate(player, ability_defs)

  return true
end

return Abilities
