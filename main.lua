-- _G.loveDebug = true

require 'globals'
require 'text'
keys = require 'keys'

local gameStateManager = require 'game-state-manager'
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

  titleScreen = love.graphics.newImage('title-screen.png')

  love.audio.setVolume(0.5)
  bgMusic = love.audio.newSource('bg-music.ogg', 'stream')
  bgMusic:setLooping(true)
  bgMusic:play()

  gameStateManager:init()
end

function love.update(dt)
  gameStateManager:update(dt)
end

function printDebugInfo()
  if not loveDebug then return end

  local cursor = selectionScreen.pokemonGrid.cursor
  local viewport = selectionScreen.pokemonGrid.verticalViewport
  local mouse = resolutionManager:getScaledMouse(love.mouse.getPosition())

  local items = {
    'FPS ' .. love.timer.getFPS(),
    'Mouse scaled: ' .. math.floor(mouse.x) .. ', ' .. math.floor(mouse.y),
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

  if gameStateManager.gameState == gameStateManager.states.TITLE_SCREEN then
    love.graphics.draw(titleScreen, 0, 0)
  elseif gameStateManager.gameState == gameStateManager.states.SELECTION_SCREEN_P1 then
    selectionScreen:draw()
  elseif gameStateManager.gameState == gameStateManager.states.SELECTION_SCREEN_P2 then
    selectionScreen:draw()
  elseif gameStateManager.gameState == gameStateManager.states.CONFIRM_SELECTION then
    selectionScreen:draw()
  end
  gameStateManager:draw()
  
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

  if key == 'f12' then
    loveDebug = not loveDebug
  end

  if gameStateManager.gameState == gameStateManager.states.TITLE_SCREEN then
    if keys.isEnterKey(key) then
      gameStateManager:transitionTo(gameStateManager.states.SELECTION_SCREEN_P1)
    end
  else
    selectionScreen:keypressed(key, gameStateManager.gameState)
  end
end

function love.resize(w, h)
	resolutionManager:recalculate()
end
