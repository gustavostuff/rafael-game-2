local gameStateManager = {
  fadeInTimer = 0,
  fadeOutTimer = 0,
  fadeInDelay = 0.3,
  fadeOutDelay = 0.3,
  states = {
    TITLE_SCREEN = 1,
    GAME = 2
  },
  active = false,
  cb = nil
}

function gameStateManager:init()
  self.gameState = self.states.TITLE_SCREEN
end

function gameStateManager:transitionTo(state, cb)
  if self.active then
    return
  end
  
  self.active = true
  self.fadeInPhase = true
  self.fadeInTimer = 0
  self.fadeOutTimer = 0
  self.nextState = state
  self.cb = cb -- what happens after the state transition is done
end

function gameStateManager:update(dt)
  if not self.active then
    return
  end

  if self.fadeInPhase then
    self.fadeInTimer = self.fadeInTimer + dt
    if self.fadeInTimer >= self.fadeInDelay then
      self.fadeInPhase = false
      self.fadeInTimer = self.fadeInDelay
      self.gameState = self.nextState

      if self.cb then
        self.cb()
      end
    end
  else
    self.fadeOutTimer = self.fadeOutTimer + dt
    if self.fadeOutTimer >= self.fadeOutDelay then
      self.fadeOutTimer = self.fadeOutDelay
      self.active = false
    end
  end
end

function gameStateManager:draw()
  if not self.active then
    return
  end

  love.graphics.setColor(colors.dark)
  if self.fadeInPhase then
    love.graphics.rectangle('fill',
      canvasWidth,
      0,
      -(canvasWidth * 1.2) * (self.fadeInTimer / self.fadeInDelay),
      canvasHeight
    )
  else
    love.graphics.rectangle('fill',
      0,
      0,
      canvasWidth - (canvasWidth * 1.2) * (self.fadeOutTimer / self.fadeOutDelay),
      canvasHeight
    )
  end
end

return gameStateManager
