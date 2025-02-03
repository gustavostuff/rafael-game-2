--[[
  BoinBoin: mathematically accurate bouncing ball
  MIT Licensed: https://github.com/tavuntu/boinboin/blob/master/LICENSE.md
]]

local bb = {
  debugMode = false,
  fpBallColors = { -- FP = Footprint
    ['normal']      = {0,   0.6, 0}, -- green
    ['off-limits']  = {1,   0,   0}, -- red
    ['corrected']   = {1,   1,   0}, -- yellow
    ['has-bounced'] = {0,   0.7, 1}, -- blue
  },
  debugInfo = {
    fpBalls = {},
    fpLines = {},
    lifespan = 1
  },
  onEvent = function (evt) end
}
local defaultBallSpeed = 300 -- pixels/s
-- Add footprint ball
local addFpBall = function (x, y, r, t) -- x, y, radius, type
  if not bb.debugMode then return end

  local data = {
    x = x,
    y = y,
    r = r,
    t = t,
    color = bb.fpBallColors[t],
    lifespan = bb.debugInfo.lifespan,
    --id = (bb.debugInfo.fpBalls[#bb.debugInfo.fpBalls] or {id = 0}).id + 1
  }
  table.insert(bb.debugInfo.fpBalls, data)
end

local addFpLine = function (x, y, x2, y2)
  if not bb.debugMode then return end

  local data = {
    x = x,
    y = y,
    x2 = x2,
    y2 = y2,
    color = {1, 0, 0},
    lifespan = 3
  }
  table.insert(bb.debugInfo.fpLines, data)
end

local function getIntersection(p1, p2, p3, p4)
  local deltaX = p1.x - p2.x
  local deltaY = p3.y - p4.y
  local deltaX2 = p1.y - p2.y
  local deltaY2 = p3.x - p4.x
  local d = deltaX * deltaY - deltaX2 * deltaY2 -- down part

  if d == 0 then
    error('Number of intersection points is zero or infinity.')
  end

  -- upper part of the formula
  local u1 = p1.x * p2.y - p1.y * p2.x
  local u4 = p3.x * p4.y - p3.y * p4.x

  -- intersection point
  local x = (u1 * deltaY2 - deltaX * u4) / d
  local y = (u1 * deltaY - deltaX2 * u4) / d
  
  return x, y
end

local function calculateReboundProjection(direction, newX, newY, ball)
  if direction == 'left' or direction == 'right' then
    ball.x = ball.x + (newX - ball.x) * 2
    ball.hv = -ball.hv
  elseif direction == 'top' or direction == 'bottom' then
    ball.y = ball.y + (newY - ball.y) * 2
    ball.vv = -ball.vv
  end

  local eventType = ball:isBeyondBox() and 'off-limits' or 'has-bounced'

  if eventType == 'has-bounced' then
    bb.addDistanceTraveled(ball, dt)
  end

  return ball.x, ball.y, ball.r, eventType
end

local function getPairOfLines(ball, offsetX1, offsetY1, offsetX2, offsetY2)
  return { x = ball.box.x + offsetX1, y = ball.box.y + offsetY1 },
         { x = ball.box.x + offsetX2, y = ball.box.y + offsetY2 },
         { x = ball.x,                y = ball.y                },
         { x = ball.previousX,        y = ball.previousY        }
end

local function decreaseSpeed(ball, event, dt)
  if event == 'rebound' then
    ball.hv = ball.hv * (1 - ball.energyLossByBounce)
    ball.vv = ball.vv * (1 - ball.energyLossByBounce)
  elseif event == 'friction' then
    ball.hv = ball.hv * (1 - ball.energyLossByFriction * dt)
    ball.vv = ball.vv * (1 - ball.energyLossByFriction * dt)
  end

  if (math.abs(ball.hv) < ball.minSpeed) and (math.abs(ball.vv) < ball.minSpeed) then
    ball.hv, ball.vv = 0, 0
    ball.idle = true
    ball.initialPoint = nil
    ball.distanceTraveled = 0
    bb.emitEvent({
      name = 'stopped'
    })
  end
end

local function updateDebugInfo(ball, dt)
  if bb.debugMode then
    for i = #bb.debugInfo.fpBalls, 1, -1 do
      local ball = bb.debugInfo.fpBalls[i]
      ball.lifespan = ball.lifespan - dt

      if ball.lifespan <= 0 then
        table.remove(bb.debugInfo.fpBalls, i)
      end
    end
    for i = #bb.debugInfo.fpLines, 1, -1 do
      local line = bb.debugInfo.fpLines[i]
      line.lifespan = line.lifespan - dt

      if line.lifespan <= 0 then
        table.remove(bb.debugInfo.fpLines, i)
      end
    end
  end
end

local checkForLeft = function (ball, cornerCheck)
  local bx = ball.box
  if ball:isBeyondLeft() then
    local newX, newY = getIntersection(getPairOfLines(ball, ball.r, 0, ball.r, bx.h))
    addFpBall(newX, newY, ball.r, 'corrected')
    bb.emitEvent({ type = 'rebound-left', x = newX, y = newY })
    ball.previousX, ball.previousY = newX, newY
    addFpBall(calculateReboundProjection('left', newX, newY, ball))
  end
end

local checkForRight = function (ball, cornerCheck)
  local bx = ball.box
  if ball:isBeyondRight() then
    local newX, newY = getIntersection(getPairOfLines(ball, bx.w - ball.r, 0, bx.w - ball.r, bx.h))
    addFpBall(newX, newY, ball.r, 'corrected')
    bb.emitEvent({ type = 'rebound-right', x = newX, y = newY })
    ball.previousX, ball.previousY = newX, newY
    addFpBall(calculateReboundProjection('right', newX, newY, ball))
  end
end

local checkForTop = function (ball, cornerCheck)
  local bx = ball.box
  if ball:isBeyondTop() then
    local newX, newY = getIntersection(getPairOfLines(ball, 0, ball.r, bx.w, ball.r))
    addFpBall(newX, newY, ball.r, 'corrected')
    bb.emitEvent({ name = 'rebound', x = newX, y = newY })
    ball.previousX, ball.previousY = newX, newY
    addFpBall(calculateReboundProjection('top', newX, newY, ball))
  end
end

local checkForBottom = function (ball, cornerCheck)
  local bx = ball.box
  if ball:isBeyondBottom() then
    local newX, newY = getIntersection(getPairOfLines(ball, 0, bx.h - ball.r, bx.w, bx.h - ball.r))
    addFpBall(newX, newY, ball.r, 'corrected')
    bb.emitEvent({ name = 'rebound', x = newX, y = newY })
    ball.previousX, ball.previousY = newX, newY
    addFpBall(calculateReboundProjection('bottom', newX, newY, ball))
  end
end

local function checkSpecialBounces(ball)
  if ball:bouncedLeftCloseToTop() then
    checkForLeft(ball)
    checkForTop(ball)
  elseif ball:bouncedTopCloseToLeft() then
    checkForTop(ball)
    checkForLeft(ball)
  elseif ball:bouncedRightCloseToTop() then
    checkForRight(ball)
    checkForTop(ball)
  elseif ball:bouncedTopCloseToRight() then
    checkForTop(ball)
    checkForRight(ball)
  elseif ball:bouncedBottomCloseToLeft() then
    checkForBottom(ball)
    checkForLeft(ball)
  elseif ball:bouncedLeftCloseToBottom() then
    checkForLeft(ball)
    checkForBottom(ball)
  elseif ball:bouncedBottomCloseToRight() then
    checkForBottom(ball)
    checkForRight(ball)
  elseif ball:bouncedRightCloseToBottom() then
    checkForRight(ball)
    checkForBottom(ball)
  else -- bounced far from a corner:
    checkForLeft(ball)
    checkForRight(ball)
    checkForTop(ball)
    checkForBottom(ball)
  end
end

bb.debug = function (options)
  options = options or {}

  bb.debugMode = true

  bb.debugInfo.lifespan = options.lifespan or bb.debugInfo.lifespan
end

bb.emitEvent = function(data)
  bb.onEvent(data)
end

bb.drawDebug = function ()
  if not bb.debugMode then return end
  local lineWidthBkp = love.graphics.getLineWidth()
  local lineStyleBkp = love.graphics.getLineStyle()
  love.graphics.setLineWidth(1)
  love.graphics.setLineStyle('smooth')

  for i = 1, #bb.debugInfo.fpBalls do
    local ball = bb.debugInfo.fpBalls[i]
    -- love.graphics.setColor(ball.color[1], ball.color[2], ball.color[3], ball.lifespan)
    love.graphics.setColor(ball.color)
    love.graphics.circle('line', ball.x, ball.y, ball.r, 64)
  end

  for i = 1, #bb.debugInfo.fpLines do
    local line = bb.debugInfo.fpLines[i]
    -- love.graphics.setColor(line.color[1], line.color[2], line.color[3], line.lifespan)
    love.graphics.setColor(line.color)
    love.graphics.line(
      math.floor(line.x),
      math.floor(line.y),
      math.floor(line.x2),
      math.floor(line.y2)
    )
  end
  love.graphics.setLineWidth(lineWidthBkp)
end
-- end of debug

bb.newBox = function (data)
  data = data or {}
  return {
    x = data.x or 0,
    y = data.y or 0,
    w = data.w or love.graphics.getWidth(),
    h = data.h or love.graphics.getHeight(),
  }
end

bb.newBall = function (data)
  data = data or {}
  if not data.box then
    error('A ball should be associated to a box.')
  end

  local ball = {
    x = (data.box.x + data.x) or (data.box.x + data.box.w / 2),
    y = (data.box.y + data.y) or (data.box.y + data.box.h / 2),
    r = data.r or (((data.box.w + data.box.h) / 2) / 30), -- radius
    box = data.box,
    hv = data.hv or defaultBallSpeed, -- horizontal velocity
    vv = data.vv or -defaultBallSpeed, -- vertical velocity
    energyLossByBounce = data.energyLossByBounce or 0.1,
    energyLossByFriction = data.energyLossByFriction or 0.4,
    minSpeed = data.minSpeed or 10,
    idle = true, -- is the ball moving?
    distanceTraveled = 0,
    stopWhenDistanceIs = data.stopWhenDistanceIs
  }

  -- boncing far from corners

  function ball:isBeyondLeft()
    return (self.x - self.r) < self.box.x
  end

  function ball:isBeyondRight()
    return (self.x + self.r) > (self.box.x + self.box.w)
  end

  function ball:isBeyondTop()
    return (self.y - self.r) < self.box.y
  end

  function ball:isBeyondBottom()
    return (self.y + self.r) > (self.box.y + self.box.h)
  end

  -- bouncing close to corners

  function ball:isInTopLeftQuadrant()
    return self:isBeyondTop() and self:isBeyondLeft()
  end

  function ball:isInTopRightQuadrant()
    return self:isBeyondTop() and self:isBeyondRight()
  end

  function ball:isInBottomLeftQuadrant()
    return self:isBeyondBottom() and self:isBeyondLeft()
  end

  function ball:isInBottomRightQuadrant()
    return self:isBeyondBottom() and self:isBeyondRight()
  end

  -- check where it bounced first when close to a corner (check 2 sides)

  --  O
  -- 
  --    ┌─O────────
  --    │
  --    │     O
  --    │ 
  --    │
  function ball:bouncedTopCloseToLeft()
    return self:isInTopLeftQuadrant() and
      (self.y - self.box.y) < (self.x - self.box.x)
  end

  function ball:bouncedLeftCloseToTop()
    return self:isInTopLeftQuadrant() and
      (self.y - self.box.y) >= (self.x - self.box.x)
  end

  function ball:bouncedTopCloseToRight()
    return self:isInTopRightQuadrant() and
      (self.y - self.box.y) < ((self.box.x + self.box.w) - self.x)
  end

  function ball:bouncedRightCloseToTop()
    return self:isInTopRightQuadrant() and
     (self.y - self.box.y) >= ((self.box.x + self.box.w) - self.x)
  end

  ---------

  function ball:bouncedBottomCloseToLeft()
    return self:isInBottomLeftQuadrant() and
      ((self.box.y + self.box.h) - self.y) < (self.x - self.box.x)
  end

  function ball:bouncedLeftCloseToBottom()
    return self:isInBottomLeftQuadrant() and
      ((self.box.y + self.box.h) - self.y) >= (self.x - self.box.x)
  end

  function ball:bouncedBottomCloseToRight()
    return self:isInBottomRightQuadrant() and
      ((self.box.y + self.box.h) - self.y) < ((self.box.x + self.box.w) - self.x)
  end

  function ball:bouncedRightCloseToBottom()
    return self:isInBottomRightQuadrant() and
      ((self.box.y + self.box.h) - self.y) >= ((self.box.x + self.box.w) - self.x)
  end

  -- utility method

  function ball:isBeyondBox()
    return self:isBeyondLeft() or
           self:isBeyondRight() or
           self:isBeyondTop() or
           self:isBeyondBottom()
  end

  return ball
end

bb.addDistanceTraveled = function (ball, dt)
  local dx = ball.previousX - ball.x
  local dy = ball.previousY - ball.y
  local displacement = math.sqrt(dx * dx + dy * dy)
  ball.distanceTraveled = ball.distanceTraveled + displacement

  bb.emitEvent({
    name = 'moved',
    distance = displacement
  })

  if ball.stopWhenDistanceIs and ball.distanceTraveled > ball.stopWhenDistanceIs then
    bb.stopBall(ball)
  end
end

bb.stopBall = function (ball)
  ball.idle = true
  ball.initialPoint = nil
  ball.distanceTraveled = 0
  bb.emitEvent({
    name = 'stopped'
  })
end

bb.updateBall = function (ball, dt)
  if ball.idle then return end

  ball.previousX = ball.x
  ball.previousY = ball.y

  if not ball.initialPoint then
    ball.initialPoint = { x = ball.x, y = ball.y }
  end

  ball.x = ball.x + ball.hv * dt
  ball.y = ball.y + ball.vv * dt

  decreaseSpeed(ball, 'friction', dt)

  if #bb.debugInfo.fpLines == 0 then
    addFpLine(ball.x, ball.y, ball.x, ball.y)
  end
  
  if ball:isBeyondBox() then
    addFpBall(ball.x, ball.y, ball.r, 'off-limits')
    if #bb.debugInfo.fpLines > 1 then
      local lines = bb.debugInfo.fpLines
      addFpLine(ball.x, ball.y, lines[#lines - 1].x2, lines[#lines - 1].y2)
    end
  else
    bb.addDistanceTraveled(ball, dt)
    --addFpBall(ball.x, ball.y, ball.r, 'normal')
  end

  checkSpecialBounces(ball)

  -- update debug info
  updateDebugInfo(ball, dt)
end

return bb
