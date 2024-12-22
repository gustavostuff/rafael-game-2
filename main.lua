-- _G.debug = true

require 'globals'
require 'text'
keys = require 'keys'

local selectionScreen = require 'selection-screen'
local resolutionManager = require 'resolution-manager'

function love.load()
  canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
  canvas:setFilter("nearest", "nearest")

  resolutionManager:init(canvas)
  selectionScreen:init("pokemon/")

  font = love.graphics.newFont('fonts/proggy-tiny/proggy-tiny.ttf', 16)
  bigFont = love.graphics.newFont('fonts/proggy-tiny/proggy-tiny.ttf', 32)
  love.graphics.setFont(font)
  love.graphics.setLineWidth(4)
  love.graphics.setLineStyle("rough")
end

function love.update(dt)

end

function printDebugInfo()
  if not debug then return end

  local cursor = selectionScreen.pokemonGrid.cursor
  local viewport = selectionScreen.pokemonGrid.verticalViewport

  local items = {
    'FPS ' .. love.timer.getFPS(),
    'Canvas size: ' .. resolutionManager.canvasWidth .. 'x' .. resolutionManager.canvasHeight,
    'Canvas scale: ' .. resolutionManager.canvasScaleX .. 'x' .. resolutionManager.canvasScaleY,
    'Canvas position: ' .. resolutionManager.canvasX .. 'x' .. resolutionManager.canvasY,
    'Selection rows: ' .. selectionScreen.pokemonGrid.gridRows,
    'Selection columns: ' .. selectionScreen.pokemonGrid.gridColumns,
    'Selection cursor x: ' .. cursor.x .. ' y: ' .. cursor.y,
    'Grid displacement y0: ' .. viewport.y0 .. ' y1: ' .. viewport.y1,
    'Empty cells at the bottom: ' .. selectionScreen.pokemonGrid:getEmptyCellsCount(),
  }

  love.graphics.setFont(bigFont)
  love.graphics.setColor(colorWithAlpha("black", 0.5))
  love.graphics.rectangle("fill", 10, 10, 400, 300)
  love.graphics.setColor(colors.white)
  love.graphics.print(table.concat(items, '\n'), 20, 20)
  love.graphics.setFont(font)
end

function love.draw()
  love.graphics.setCanvas({canvas, depthstencil = true})
	love.graphics.clear(colors.dark)

  ---------------------------------------------------------------

  selectionScreen:draw()
  
  ---------------------------------------------------------------
  
	love.graphics.setCanvas()
	love.graphics.setColor(colors.white)
	resolutionManager:renderCanvas(canvas)
  printDebugInfo()
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
