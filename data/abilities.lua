local abilities = {
  offensive_attack_25 = {
    id = "offensive_attack_25",
    name = "Furia da Mascara",
    type = "offensive",
    passive = {
      attack_mult = 0.25,
    },
  },
  offensive_dash_iframe = {
    id = "offensive_dash_iframe",
    name = "Dash Imune",
    type = "offensive",
    passive = {
      dash_iframe = true,
    },
  },
  offensive_special_charge = {
    id = "offensive_special_charge",
    name = "Furia Especial",
    type = "offensive",
    special = "absorb",
  },
  defensive_shield_plus_2 = {
    id = "defensive_shield_plus_2",
    name = "Escudo Libertador",
    type = "defensive",
    passive = {
      max_health_bonus = 20,
    },
  },
  defensive_special_burst = {
    id = "defensive_special_burst",
    name = "Luz Purificadora",
    type = "defensive",
    special = "remove",
  },
}

return abilities
