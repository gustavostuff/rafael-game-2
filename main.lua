require 'globals'
keys = require 'keys'

local selectionScreen = require 'selection-screen'
local resolutionManager = require 'resolution-manager'

function love.load()
  canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
  canvas:setFilter("nearest", "nearest")

  resolutionManager:init(canvas)
  selectionScreen:init("pokemon/")

  font = love.graphics.newFont('fonts/proggy-tiny/proggy-tiny.ttf', 16)
  love.graphics.setFont(font)
end

function love.update(dt)

end

function love.draw()
  love.graphics.setCanvas({canvas, depthstencil = true})
	love.graphics.clear(colors.black)

  ---------------------------------------------------------------

  selectionScreen:draw()

  
  ---------------------------------------------------------------
  
	love.graphics.setCanvas()
	love.graphics.setColor(colors.white)
	resolutionManager:renderCanvas(canvas)
  -- drawColorPalette()
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end

  selectionScreen:keypressed(key)
end

function love.resize(w, h)
	resolutionManager:recalculate()
end
