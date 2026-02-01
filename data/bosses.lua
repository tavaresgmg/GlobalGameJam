local bosses = {
  {
    id = "boss_ferro",
    name = "Capanga do Ferro",
    max_health = 272,
    speed = 90,
    charge_speed = 260,
    charge_range = 160,
    charge_cooldown = 2.0,
    reward_offensive = "offensive_attack_25",
    reward_defensive = "defensive_shield_plus_2",
  },
  {
    id = "boss_noite",
    name = "Capanga da Noite",
    max_health = 340,
    speed = 110,
    charge_speed = 300,
    charge_range = 180,
    charge_cooldown = 2.2,
    reward_offensive = "offensive_dash_iframe",
    reward_defensive = "defensive_special_burst",
  },
  {
    id = "boss_final",
    name = "Coronel Supremo",
    max_health = 544,
    speed = 120,
    charge_speed = 320,
    charge_range = 200,
    charge_cooldown = 1.8,
    reward_offensive = nil,
    reward_defensive = nil,
    is_final = true,
  },
}

return bosses
