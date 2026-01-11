local timerManager = {
  timers = {},
  intervals = {},
  nextIdValue = 0
}

local function nextId(self)
  self.nextIdValue = self.nextIdValue + 1
  return self.nextIdValue
end

function timerManager:after(delay, fn)
  local id = nextId(self)
  self.timers[id] = {
    time = love.timer.getTime() + delay,
    fn = fn,
    canceled = false
  }
  return id
end

function timerManager:every(interval, fn)
  local id = nextId(self)
  self.intervals[id] = {
    interval = interval,
    next = love.timer.getTime() + interval,
    fn = fn,
    canceled = false
  }
  return id
end

function timerManager:cancel(id)
  if self.timers[id] then
    self.timers[id].canceled = true
  end
  if self.intervals[id] then
    self.intervals[id].canceled = true
  end
end

function timerManager:clear()
  self.timers = {}
  self.intervals = {}
end

function timerManager:update()
  local now = love.timer.getTime()

  for id, timer in pairs(self.timers) do
    if timer.canceled then
      self.timers[id] = nil
    elseif now >= timer.time then
      timer.fn()
      self.timers[id] = nil
    end
  end

  for id, interval in pairs(self.intervals) do
    if interval.canceled then
      self.intervals[id] = nil
    else
      while now >= interval.next do
        interval.fn()
        interval.next = interval.next + interval.interval
      end
    end
  end
end

return timerManager
