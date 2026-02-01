local Level01 = {}

function Level01.build(settings, constants)
  local floor_y = settings.height - 40

  local world = {
    width = settings.width * 5,
    height = settings.height,
    gravity = constants.gravity,
  }

  local platforms = {
    { x = 0, y = floor_y, w = world.width, h = 40 },
    { x = 240, y = floor_y - 120, w = 140, h = 20 },
    { x = 540, y = floor_y - 200, w = 160, h = 20 },
    { x = 860, y = floor_y - 140, w = 160, h = 20 },
    { x = 1120, y = floor_y - 100, w = 140, h = 20 },
    { x = 1440, y = floor_y - 180, w = 180, h = 20 },
    { x = 1700, y = floor_y - 120, w = 150, h = 20 },
    { x = 2040, y = floor_y - 160, w = 160, h = 20 },
    { x = 2320, y = floor_y - 220, w = 180, h = 20 },
    { x = 2580, y = floor_y - 140, w = 200, h = 20 },
    { x = 2920, y = floor_y - 120, w = 160, h = 20 },
    { x = 3180, y = floor_y - 200, w = 180, h = 20 },
    { x = 3440, y = floor_y - 140, w = 200, h = 20 },
    { x = 3680, y = floor_y - 100, w = 160, h = 20 },
    { x = 3920, y = floor_y - 180, w = 180, h = 20 },
    { x = 4200, y = floor_y - 140, w = 200, h = 20 },
    { x = 4460, y = floor_y - 220, w = 160, h = 20 },
    { x = 4680, y = floor_y - 120, w = 120, h = 20 },
  }

  local enemy_spawns = {
    { kind = "grunt", x = 260, left = 200, right = 380, speed_mult = 0.9 },
    { kind = "rusher", x = 420, left = 380, right = 520, speed_mult = 1.1 },
    { kind = "grunt", x = 300, platform = 2, speed_mult = 1.0 },
    { kind = "rusher", x = 620, platform = 3, speed_mult = 1.2 },
    { kind = "grunt", x = 940, platform = 4, speed_mult = 0.85 },
    { kind = "rusher", x = 1160, platform = 5, speed_mult = 1.05 },

    { kind = "grunt", x = 1280, left = 1220, right = 1400, speed_mult = 1.0 },
    { kind = "rusher", x = 1500, left = 1440, right = 1620, speed_mult = 1.15 },
    { kind = "grunt", x = 1520, platform = 6, speed_mult = 0.9 },
    { kind = "rusher", x = 1760, platform = 7, speed_mult = 1.25 },
    { kind = "grunt", x = 1880, left = 1820, right = 2000, speed_mult = 0.95 },
    { kind = "rusher", x = 2120, platform = 8, speed_mult = 1.1 },
    { kind = "grunt", x = 2380, platform = 9, speed_mult = 0.9 },

    { kind = "grunt", x = 2480, left = 2420, right = 2600, speed_mult = 1.0 },
    { kind = "rusher", x = 2680, platform = 10, speed_mult = 1.15 },
    { kind = "grunt", x = 2760, left = 2700, right = 2880, speed_mult = 0.9 },
    { kind = "rusher", x = 3000, platform = 11, speed_mult = 1.2 },
    { kind = "grunt", x = 3120, left = 3060, right = 3240, speed_mult = 0.95 },
    { kind = "rusher", x = 3260, platform = 12, speed_mult = 1.1 },
    { kind = "grunt", x = 3520, platform = 13, speed_mult = 1.05 },

    { kind = "grunt", x = 3640, left = 3580, right = 3760, speed_mult = 0.9 },
    { kind = "rusher", x = 3760, platform = 14, speed_mult = 1.2 },
    { kind = "grunt", x = 3860, left = 3800, right = 3980, speed_mult = 0.95 },
    { kind = "rusher", x = 4040, platform = 15, speed_mult = 1.25 },
    { kind = "grunt", x = 4140, left = 4080, right = 4260, speed_mult = 1.0 },
    { kind = "rusher", x = 4320, platform = 16, speed_mult = 1.1 },
    { kind = "grunt", x = 4520, platform = 17, speed_mult = 0.9 },
    { kind = "rusher", x = 4740, platform = 18, speed_mult = 1.2 },
    { kind = "grunt", x = 4400, left = 4340, right = 4520, speed_mult = 0.85 },
    { kind = "rusher", x = 4580, platform = 17, speed_mult = 1.3 },
    { kind = "grunt", x = 4640, left = 4580, right = 4720, speed_mult = 1.05 },
    { kind = "rusher", x = 4720, platform = 18, speed_mult = 1.15 },
    { kind = "grunt", x = 4500, left = 4440, right = 4600, speed_mult = 0.95 },
    { kind = "rusher", x = 4680, left = 4620, right = 4760, speed_mult = 1.2 },
    { kind = "grunt", x = 4760, left = 4700, right = 4780, speed_mult = 0.9 },
    { kind = "rusher", x = 4660, platform = 18, speed_mult = 1.1 },
  }

  local spawn = { x = 80, y = floor_y - constants.player.height }

  local unmask_trigger = {
    x = 1240,
    y = floor_y - 80,
    w = 60,
    h = 60,
    used = false,
    tag = "unmask",
    is_trigger = true,
    in_world = false,
  }

  local segments = {
    {
      start_x = 0,
      gate_x = 1200,
      locked = true,
      enemy_ids = { 1, 2, 3, 4, 5, 6 },
      boss_ids = {},
    },
    {
      start_x = 1200,
      gate_x = 2400,
      locked = true,
      enemy_ids = { 7, 8, 9, 10, 11, 12, 13 },
      boss_ids = { 1 },
    },
    {
      start_x = 2400,
      gate_x = 3600,
      locked = true,
      enemy_ids = { 14, 15, 16, 17, 18, 19, 20 },
      boss_ids = { 2 },
    },
    {
      start_x = 3600,
      gate_x = 4800,
      locked = true,
      enemy_ids = {
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        36,
      },
      boss_ids = { 3 },
    },
  }

  return {
    world = world,
    platforms = platforms,
    enemy_spawns = enemy_spawns,
    spawn = spawn,
    unmask_trigger = unmask_trigger,
    segments = segments,
    floor_y = floor_y,
  }
end

return Level01
