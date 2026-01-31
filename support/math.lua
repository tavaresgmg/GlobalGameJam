local Math = {}

function Math.clamp(value, min, max)
  if value < min then
    return min
  end
  if value > max then
    return max
  end
  return value
end

function Math.sign(value)
  if value < 0 then
    return -1
  end
  if value > 0 then
    return 1
  end
  return 0
end

return Math
