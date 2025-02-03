local bb = require 'lib.boinboin'
local scoreManager = require 'score-manager'
local pingPongManager = {
  fieldWidth = 180,
  fieldHeight = 180 - 20,
  leftPaddleSpeed = 120,
  rightPaddleSpeed = 120,
}

function pingPongManager:init(ballImg, paddleImg)
  self.paddleImg = paddleImg
  self.ballImg = ballImg
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
          scoreManager:increasePlayerScore('player2')
          self:initBall(self.box)
        end
      elseif evt.type == 'rebound-right' then
        if self:pointAgainst('player2', evt) then
          scoreManager:increasePlayerScore('player1')
          self:initBall(self.box)
        end
      end
    end
  end
end

function pingPongManager:initBall(box)
  self.ball = bb.newBall({
    x = self.fieldWidth / 2,
    y = self.fieldHeight / 2,
    r = 6,
    box = box,
    hv = 80,
    vv = 90,
    energyLossByBounce = 0,
    energyLossByFriction = 0
  })
end

function pingPongManager:pointAgainst(player, evt)
  local paddle = player == 'player1' and self.playerOnePaddle or self.playerTwoPaddle
  
  return not (evt.y >= paddle.y and evt.y <= paddle.y + self.paddleImg:getHeight())
end

function pingPongManager:update(dt)
  bb.updateBall(self.ball, dt)

  -- move paddles
  local leftPaddleDirection = love.keyboard.isDown(keys.w) and -1 or 1
  local rightPaddleDirection = love.keyboard.isDown(keys.up) and -1 or 1

  if self.leftPaddleMoving then
    self.playerOnePaddle.y = self.playerOnePaddle.y + self.leftPaddleSpeed * dt * leftPaddleDirection
  end

  if self.rightPaddleMoving then
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
  if keys.isAnyOf(key, {'w', 's'}) then
    self.leftPaddleMoving = true
  elseif keys.isAnyOf(key, {'up', 'down'}) then
    self.rightPaddleMoving = true
  end
end

function pingPongManager:keyreleased(key)
  if keys.isAnyOf(key, {'w', 's'}) then
    self.leftPaddleMoving = false
  elseif keys.isAnyOf(key, {'up', 'down'}) then
    self.rightPaddleMoving = false
  end
end

function pingPongManager:launchBall()
  self.ball.idle = false
end

return pingPongManager
