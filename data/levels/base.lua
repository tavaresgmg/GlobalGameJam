local LevelBase = {}

local function in_range(x, start_x, end_x)
  return x >= start_x and x < end_x
end

local function build_level_data(data, level_index)
  local segment = data.segments[level_index]
  if not segment then
    return data
  end

  local start_x = segment.start_x
  local end_x = segment.gate_x
  local offset_x = -start_x
  local segment_length = end_x - start_x

  local world = {
    width = segment_length,
    height = data.world.height,
    gravity = data.world.gravity,
  }

  local platforms = {}
  local platform_map = {}

  for i, platform in ipairs(data.platforms) do
    if i == 1 then
      local floor = {
        x = 0,
        y = platform.y,
        w = segment_length,
        h = platform.h,
      }
      table.insert(platforms, floor)
      platform_map[i] = #platforms
    else
      if platform.x + platform.w > start_x and platform.x < end_x then
        local platform_start = math.max(platform.x, start_x)
        local platform_end = math.min(platform.x + platform.w, end_x)
        local sliced_platform = {
          x = platform_start + offset_x,
          y = platform.y,
          w = math.max(0, platform_end - platform_start),
          h = platform.h,
        }
        table.insert(platforms, sliced_platform)
        platform_map[i] = #platforms
      end
    end
  end

  local enemy_spawns = {}
  for _, spawn in ipairs(data.enemy_spawns or {}) do
    if in_range(spawn.x, start_x, end_x) then
      local mapped_platform = nil
      local include_spawn = true
      if spawn.platform then
        mapped_platform = platform_map[spawn.platform]
        if not mapped_platform then
          include_spawn = false
        end
      end

      if include_spawn then
        local sliced_spawn = {
          kind = spawn.kind,
          x = spawn.x + offset_x,
        }
        if mapped_platform then
          sliced_spawn.platform = mapped_platform
        end
        if spawn.left then
          local clamped_left = math.max(spawn.left, start_x)
          sliced_spawn.left = clamped_left + offset_x
        end
        if spawn.right then
          local clamped_right = math.min(spawn.right, end_x)
          sliced_spawn.right = clamped_right + offset_x
        end
        if spawn.speed_mult then
          sliced_spawn.speed_mult = spawn.speed_mult
        end
        if spawn.speed then
          sliced_spawn.speed = spawn.speed
        end
        table.insert(enemy_spawns, sliced_spawn)
      end
    end
  end

  local pickup_spawns = {}
  for _, pickup in ipairs(data.pickup_spawns or {}) do
    if in_range(pickup.x, start_x, end_x) then
      table.insert(pickup_spawns, {
        x = pickup.x + offset_x,
        y = pickup.y,
      })
    end
  end

  local boss_spawns = {}
  for _, boss in ipairs(data.boss_spawns or {}) do
    if in_range(boss.x, start_x, end_x) then
      table.insert(boss_spawns, {
        boss_index = boss.boss_index,
        x = boss.x + offset_x,
      })
    end
  end

  local unmask_trigger = nil
  if data.unmask_trigger and in_range(data.unmask_trigger.x, start_x, end_x) then
    unmask_trigger = {
      x = data.unmask_trigger.x + offset_x,
      y = data.unmask_trigger.y,
      w = data.unmask_trigger.w,
      h = data.unmask_trigger.h,
      used = false,
      tag = data.unmask_trigger.tag,
      is_trigger = true,
      in_world = false,
    }
  end

  local enemy_ids = {}
  for i = 1, #enemy_spawns do
    table.insert(enemy_ids, i)
  end
  local boss_ids = {}
  for i = 1, #boss_spawns do
    table.insert(boss_ids, i)
  end

  local segments = {
    {
      start_x = 0,
      gate_x = segment_length,
      locked = segment.locked,
      enemy_ids = enemy_ids,
      boss_ids = boss_ids,
    },
  }

  return {
    world = world,
    platforms = platforms,
    enemy_spawns = enemy_spawns,
    spawn = {
      x = data.spawn.x,
      y = data.spawn.y,
    },
    unmask_trigger = unmask_trigger,
    segments = segments,
    floor_y = data.floor_y,
    pickup_spawns = pickup_spawns,
    boss_spawns = boss_spawns,
    level_index = level_index,
  }
end

function LevelBase.build(settings, constants, level_index)
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

  local pickup_spawns = {
    { x = 520, y = floor_y - 80 },
    { x = 1320, y = floor_y - 80 },
    { x = 2080, y = floor_y - 80 },
    { x = 2760, y = floor_y - 80 },
    { x = 3440, y = floor_y - 80 },
    { x = 4080, y = floor_y - 80 },
    { x = 4680, y = floor_y - 80 },
  }

  local boss_spawns = {
    { boss_index = 1, x = 1700 },
    { boss_index = 2, x = 2900 },
    { boss_index = 3, x = 4100 },
  }

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

  local data = {
    world = world,
    platforms = platforms,
    enemy_spawns = enemy_spawns,
    spawn = spawn,
    unmask_trigger = unmask_trigger,
    segments = segments,
    floor_y = floor_y,
    pickup_spawns = pickup_spawns,
    boss_spawns = boss_spawns,
  }

  if level_index then
    return build_level_data(data, level_index)
  end

  return data
end

return LevelBase
