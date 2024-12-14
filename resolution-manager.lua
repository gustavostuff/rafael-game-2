local resolutionManager = {
  modes = {
    KEEP_ASPECT = 1,
    PIXEL_PERFECT = 2,
    STRETCH = 3,
  },
}

function resolutionManager:init(canvas)
  self.canvas = canvas
  self.canvasWidth = self.canvas:getWidth()
  self.canvasHeight = self.canvas:getHeight()
  self.canvasScaleX = 1
  self.canvasScaleY = 1
  self.defaultMode = resolutionManager.modes.PIXEL_PERFECT
  self:setMode(self.defaultMode)

  self:recalculate()
end

function resolutionManager:setMode(mode)
  self.mode = mode
  self:recalculate()
end

function resolutionManager:normalizeScale()
  if self.canvasScaleX > self.canvasScaleY then
    self.canvasScaleX = self.canvasScaleY
  else
    self.canvasScaleY = self.canvasScaleX
  end
end

function resolutionManager:setCanvasPosition()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  self.canvasX = math.floor(w / 2 - self.canvas:getWidth() * self.canvasScaleX / 2)
  self.canvasY = math.floor(h / 2 - self.canvas:getHeight() * self.canvasScaleY / 2)
end

function resolutionManager:recalculate()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()

  if self.mode == resolutionManager.modes.KEEP_ASPECT then
    self.canvasScaleX = w / self.canvasWidth
    self.canvasScaleY = h / self.canvasHeight
    self:normalizeScale()
  elseif self.mode == resolutionManager.modes.PIXEL_PERFECT then
    self.canvasScaleX = math.floor(w / self.canvasWidth)
    self.canvasScaleY = math.floor(h / self.canvasHeight)
    self:normalizeScale()
  elseif self.mode == resolutionManager.modes.STRETCH then
    self.canvasScaleX = w / self.canvasWidth
    self.canvasScaleY = h / self.canvasHeight
  end

  self:setCanvasPosition()
end

function resolutionManager:renderCanvas()
  love.graphics.draw(
    self.canvas,
    self.canvasX,
    self.canvasY,
    0,
    self.canvasScaleX,
    self.canvasScaleY
  )
end

function resolutionManager:getScaledMouse(touchX, touchY)
  local x, y = love.mouse.getPosition()

  if touchX and touchY then
    x, y = touchX, touchY
  end

  return {
    x = ((x - self.canvasX) / self.canvasScaleX),
    y = ((y - self.canvasY) / self.canvasScaleY)
  }
end

return resolutionManager
