local bb = require 'lib.boinboin'
local pingPongManager = {}

function pingPongManager:init(ballImg)
  self.ballImg = ballImg
  bb.debug({
    lifespan = 2
  })

  local boxWidth = 180
  local boxHeight = 180
  self.box = bb.newBox({
    x = canvasWidth / 2 - boxWidth / 2,
    y = 0,
    w = boxWidth,
    h = boxHeight
  })
  self.ball = bb.newBall({
    x = 180 / 2,
    y = 180 / 2,
    r = 6,
    box = self.box,
    hv = 200,
    vv = 240,
    energyLossByBounce = 0,
    energyLossByFriction = 0
  })
end

function pingPongManager:update(dt)
  bb.updateBall(self.ball, dt, function (evt)
    if evt.type == 'rebound' then
      --
    elseif evt.type == 'stray' then
      --
    end
  end)
end

function pingPongManager:draw()
  love.graphics.setColor(colors.darkGreen)
  love.graphics.rectangle('fill', self.box.x, self.box.y, self.box.w, self.box.h)

  love.graphics.setColor(colors.white)
  -- bb.drawDebug()

  love.graphics.setColor(colors.white)
  love.graphics.draw(
    self.ballImg,
    math.floor(self.ball.x),
    math.floor(self.ball.y),
    0,
    1,
    1,
    math.floor(self.ballImg:getWidth() / 2),
    math.floor(self.ballImg:getHeight() / 2)
  )
end

function pingPongManager:launchBall()
  self.ball.idle = false
end

return pingPongManager
