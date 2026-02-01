local Health = require("systems.health")
local Abilities = require("systems.abilities")

local Progression = {}

function Progression.init_player(player)
  player.masks_absorbed = 0
  player.masks_removed = 0
  player.special_charge_absorb = 0
  player.special_charge_remove = 0
  player.special_ready_offensive = false
  player.special_ready_defensive = false
end

function Progression.on_mask_result(player, mode, constants, _)
  if mode == "offensive" then
    player.masks_absorbed = player.masks_absorbed + 1
    player.special_charge_absorb = player.special_charge_absorb + 1
    Health.heal(player, constants.player.heal_on_absorb)

    if player.special_charge_absorb >= constants.player.special_absorb_threshold then
      player.special_offensive_unlocked = true
      player.special_ready_offensive = true
    end
  else
    player.masks_removed = player.masks_removed + 1
    player.special_charge_remove = player.special_charge_remove + 1
    Health.heal(player, constants.player.heal_on_remove)

    if player.special_charge_remove >= constants.player.special_remove_threshold then
      player.special_defensive_unlocked = true
      player.special_ready_defensive = true
    end
  end
end

function Progression.consume_special(player)
  if player.mode == "offensive" then
    player.special_charge_absorb = 0
    player.special_ready_offensive = false
  else
    player.special_charge_remove = 0
    player.special_ready_defensive = false
  end
end

function Progression.is_special_ready(player)
  if player.mode == "offensive" then
    return player.special_ready_offensive and player.special_offensive_unlocked
  end
  return player.special_ready_defensive and player.special_defensive_unlocked
end

function Progression.on_boss_defeated(player, boss, ability_defs)
  if boss.reward_granted then
    return
  end

  local reward = player.mode == "offensive" and boss.reward_offensive or boss.reward_defensive
  if reward then
    Abilities.grant(player, reward, ability_defs)
  end

  boss.reward_granted = true
end

function Progression.final_outcome(player)
  if player.masks_removed >= player.masks_absorbed * 1.5 then
    return "good"
  end
  return "bad"
end

return Progression
