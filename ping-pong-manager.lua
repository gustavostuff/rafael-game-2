local bb = require 'lib.boinboin'
local timerManager = require 'timer-manager'
local scoreManager = require 'score-manager'
local pingPongManager = {
  fieldWidth = 180,
  fieldHeight = 180 - 20,
  leftPaddleSpeed = 120,
  rightPaddleSpeed = 120,
}

function pingPongManager:init(ballImg, paddleImg, onScore, onPaddleBounce)
  self.paddleImg = paddleImg
  self.ballImg = ballImg
  self.onScore = onScore
  self.onPaddleBounce = onPaddleBounce
  self.fieldX = canvasWidth / 2 - self.fieldWidth / 2
  self.fieldY = 10

  self.playerOnePaddle = {
    x = self.fieldX - self.paddleImg:getWidth(),
    y = self.fieldY,
  }
  self.playerTwoPaddle = {
    x = self.fieldX + self.fieldWidth,
    y = self.fieldY,
  }
  self.leftUpPressed = false
  self.leftDownPressed = false
  self.rightUpPressed = false
  self.rightDownPressed = false
  self.launchDelayId = nil
  self.launchCountdownId = nil
  self.launchCountdown = nil

  bb.debug({
    lifespan = 2
  })

  self.box = bb.newBox({
    x = self.fieldX,
    y = self.fieldY,
    w = self.fieldWidth,
    h = self.fieldHeight
  })
  self:initBall(self.box)

  bb.onEvent = function(evt)
    if evt.type == 'rebound-left' or evt.type == 'rebound-right' then
      -- scoreManager:increasePlayerScore(evt.type == 'rebound-left' and 'player2' or 'player1')
      if evt.type == 'rebound-left' then
        if self:pointAgainst('player1', evt) then
          scoreManager:decreasePlayerScore('player1')
          local isGameOver = scoreManager:getPlayerScore('player1') <= 0
          if self.onScore then
            self.onScore('player2', 'player1', isGameOver)
          end
          if isGameOver then
            return
          end
          self:initBall(self.box)
        end
      elseif evt.type == 'rebound-right' then
        if self:pointAgainst('player2', evt) then
          scoreManager:decreasePlayerScore('player2')
          local isGameOver = scoreManager:getPlayerScore('player2') <= 0
          if self.onScore then
            self.onScore('player1', 'player2', isGameOver)
          end
          if isGameOver then
            return
          end
          self:initBall(self.box)
        end
      end
    end
  end
end

function pingPongManager:initBall(box)
  if self.launchDelayId then
    timerManager:cancel(self.launchDelayId)
    self.launchDelayId = nil
  end
  if self.launchCountdownId then
    timerManager:cancel(self.launchCountdownId)
    self.launchCountdownId = nil
  end
  self.launchCountdown = nil
  local hSign = love.math.random(0, 1) == 0 and -1 or 1
  local vSign = love.math.random(0, 1) == 0 and -1 or 1
  self.ball = bb.newBall({
    x = self.fieldWidth / 2,
    y = self.fieldHeight / 2,
    r = 6,
    box = box,
    hv = 80 * hSign,
    vv = 90 * vSign,
    -- hv = 20,
    -- vv = 22,
    energyLossByBounce = 0,
    energyLossByFriction = 0
  })
end

function pingPongManager:pointAgainst(player, evt)
  local paddle = player == 'player1' and self.playerOnePaddle or self.playerTwoPaddle
  local paddleTop = paddle.y
  local paddleBottom = paddle.y + self.paddleImg:getHeight()
  local ballRadius = self.ball.r
  local y = evt.y

  if y >= paddleTop and y <= paddleBottom then
    if self.onPaddleBounce then
      self.onPaddleBounce()
    end
    return false
  end

  if y >= paddleTop - ballRadius and y <= paddleBottom + ballRadius then
    if not self.ball:isBeyondTop() and not self.ball:isBeyondBottom() then
      self.ball.vv = -self.ball.vv
    end
    if self.onPaddleBounce then
      self.onPaddleBounce()
    end
    return false
  end

  return true
end

function pingPongManager:update(dt)
  bb.updateBall(self.ball, dt)

  -- move paddles
  local leftPaddleDirection = self.leftUpPressed and -1 or (self.leftDownPressed and 1 or 0)
  local rightPaddleDirection = self.rightUpPressed and -1 or (self.rightDownPressed and 1 or 0)

  if leftPaddleDirection ~= 0 then
    self.playerOnePaddle.y = self.playerOnePaddle.y + self.leftPaddleSpeed * dt * leftPaddleDirection
  end

  if rightPaddleDirection ~= 0 then
    self.playerTwoPaddle.y = self.playerTwoPaddle.y + self.rightPaddleSpeed * dt * rightPaddleDirection
  end

  -- correct out of bounds paddles
  self.playerOnePaddle.y = math.min(
    math.max(
      self.playerOnePaddle.y,
      self.fieldY
    ),
      self.fieldY + self.fieldHeight - self.paddleImg:getHeight()
    )
  
  self.playerTwoPaddle.y = math.min(
    math.max(
      self.playerTwoPaddle.y,
      self.fieldY
    ),
      self.fieldY + self.fieldHeight - self.paddleImg:getHeight()
    )
end

function pingPongManager:draw()
  love.graphics.setColor(colors.darkGreen)
  love.graphics.rectangle('fill',
    self.fieldX,
    self.fieldY,
    self.fieldWidth,
    self.fieldHeight
  )

  love.graphics.setColor(colors.white)
  -- bb.drawDebug()

  -- draw ball
  love.graphics.setColor(colors.white)
  love.graphics.draw(
    self.ballImg,
    math.floor(self.ball.x - self.ball.r),
    math.floor(self.ball.y - self.ball.r)
  )

  -- draw paddles

  love.graphics.setColor(colors.white)
  love.graphics.draw(
    self.paddleImg,
    math.floor(self.playerOnePaddle.x),
    math.floor(self.playerOnePaddle.y)
  )

  love.graphics.draw(
    self.paddleImg,
    math.floor(self.playerTwoPaddle.x),
    math.floor(self.playerTwoPaddle.y)
  )
end

function pingPongManager:keypressed(key)
  if key == 'w' then
    self.leftUpPressed = true
  elseif key == 's' then
    self.leftDownPressed = true
  elseif key == 'up' then
    self.rightUpPressed = true
  elseif key == 'down' then
    self.rightDownPressed = true
  end
end

function pingPongManager:keyreleased(key)
  if key == 'w' then
    self.leftUpPressed = false
  elseif key == 's' then
    self.leftDownPressed = false
  elseif key == 'up' then
    self.rightUpPressed = false
  elseif key == 'down' then
    self.rightDownPressed = false
  end
end

function pingPongManager:launchBall()
  self.ball.idle = false
  if self.launchDelayId then
    timerManager:cancel(self.launchDelayId)
    self.launchDelayId = nil
  end
  if self.launchCountdownId then
    timerManager:cancel(self.launchCountdownId)
    self.launchCountdownId = nil
  end
  self.launchCountdown = nil
end

function pingPongManager:startLaunchCountdown(delaySeconds)
  if self.launchDelayId then
    timerManager:cancel(self.launchDelayId)
    self.launchDelayId = nil
  end
  if self.launchCountdownId then
    timerManager:cancel(self.launchCountdownId)
    self.launchCountdownId = nil
  end

  local function startCountdown()
    self.launchCountdown = 3
    self.launchCountdownId = timerManager:every(1, function()
      self.launchCountdown = self.launchCountdown - 1
      if self.launchCountdown <= 0 then
        if self.launchCountdownId then
          timerManager:cancel(self.launchCountdownId)
          self.launchCountdownId = nil
        end
        self.launchCountdown = nil
        self:launchBall()
      end
    end)
  end

  if delaySeconds and delaySeconds > 0 then
    self.launchDelayId = timerManager:after(delaySeconds, function()
      self.launchDelayId = nil
      startCountdown()
    end)
  else
    startCountdown()
  end
end

function pingPongManager:getLaunchCountdown()
  if not self.ball or not self.ball.idle or not self.launchCountdown then
    return nil
  end
  return self.launchCountdown
end

function pingPongManager:resetBall(startCountdown)
  self:initBall(self.box)
  if startCountdown ~= false then
    self:startLaunchCountdown(0)
  end
end

return pingPongManager
