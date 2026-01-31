local Time = {}

function Time.clamp_dt(dt)
  local max_dt = 1 / 30
  if dt > max_dt then
    return max_dt
  end
  return dt
end

return Time
