-- _G.loveDebug = true

require 'globals'
require 'text'
keys = require 'keys'

local gameStateManager = require 'game-state-manager'
local selectionScreen = require 'selection-screen'
local resolutionManager = require 'resolution-manager'
local scoreManager = require 'score-manager'
local pingPongManager = require 'ping-pong-manager'
local timerManager = require 'timer-manager'

local function getPokemonByName(name, list)
  for _, pokemon in pairs(list) do
    if pokemon.name == name then
      return pokemon
    end
  end
end

local attackImages = {}
local attackEffect = {
  visible = false,
  player = nil,
  img = nil,
  flipY = false,
  timeoutId = nil,
  oscillateId = nil
}

local function getAttackImage(typeName)
  if not attackImages[typeName] then
    attackImages[typeName] = love.graphics.newImage('attacks/' .. typeName .. '.png')
  end
  return attackImages[typeName]
end

local function triggerAttack(player)
  local selected = selectionScreen.selectedPokemon[player]
  if not selected or not selected.type then return end

  if attackEffect.timeoutId then
    timerManager:cancel(attackEffect.timeoutId)
  end
  if attackEffect.oscillateId then
    timerManager:cancel(attackEffect.oscillateId)
  end

  attackEffect.player = player
  attackEffect.img = getAttackImage(selected.type)
  attackEffect.visible = true
  attackEffect.flipY = false

  attackEffect.oscillateId = timerManager:every(0.25, function()
    attackEffect.flipY = not attackEffect.flipY
  end)

  attackEffect.timeoutId = timerManager:after(1, function()
    if attackEffect.oscillateId then
      timerManager:cancel(attackEffect.oscillateId)
      attackEffect.oscillateId = nil
    end
    attackEffect.timeoutId = nil
    attackEffect.visible = false
    attackEffect.player = nil
    attackEffect.img = nil
  end)
end

function love.load()
  canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
  canvas:setFilter("nearest", "nearest")

  resolutionManager:init(canvas)
  pokemonItems = selectionScreen:init("pokemon/")

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
  local ballImg = love.graphics.newImage('other/pokeball.png')
  local paddleImg = love.graphics.newImage('other/paddle.png')
  pingPongManager:init(ballImg, paddleImg, triggerAttack)

  lifeIndicator = love.graphics.newImage('other/life_indicator.png')
end

function love.update(dt)
  gameStateManager:update(dt)

  if gameStateManager:stateIs(gameStateManager.states.GAME) then
    pingPongManager:update(dt)
    timerManager:update()
  end
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
    love.graphics.setColor(colorWithAlpha("black", 0.5))
    love.graphics.rectangle("fill", 0, 0, canvasWidth, canvasHeight)

    love.graphics.setColor(colors.white)
    local text = "Are you ready?"
    love.graphics.print(text, (canvasWidth - font:getWidth(text)) / 2, (canvasHeight - font:getHeight()) / 2)
  elseif gameStateManager:stateIs(gameStateManager.states.GAME) then
    local pokemonPlayer1 = getPokemonByName(selectionScreen.selectedPokemon['player1'].name, pokemonItems)
    local pokemonPlayer2 = getPokemonByName(selectionScreen.selectedPokemon['player2'].name, pokemonItems)

    -- draw pokemon
    love.graphics.setColor(colors.white)
    love.graphics.draw(
      pokemonPlayer1.image,
      36,
      canvasHeight / 2,
      0,
      -1,
      1,
      pokemonPlayer1.facePosition.x,
      pokemonPlayer1.facePosition.y
    )
    love.graphics.draw(
      pokemonPlayer2.image,
      canvasWidth - 36,
      canvasHeight / 2,
      0,
      1,
      1,
      pokemonPlayer2.facePosition.x,
      pokemonPlayer2.facePosition.y
    )

    -- draw life bar:

    love.graphics.setColor(colors.white)
    love.graphics.draw(lifeIndicator, 5, canvasHeight - 10)
    love.graphics.draw(lifeIndicator, canvasWidth - lifeIndicator:getWidth() - 5, canvasHeight - 10)

    pingPongManager:draw()
    scoreManager:draw()

    if attackEffect.visible and attackEffect.img and attackEffect.player then
      local faceX = attackEffect.player == 'player1' and 36 or canvasWidth - 36
      local faceY = canvasHeight / 2
      local attackOffset = 20
      local attackScaleX = 1
      local attackScaleY = attackEffect.flipY and -1 or 1

      if attackEffect.player == 'player2' then
        attackScaleX = -1
        attackOffset = -attackOffset
      end

      love.graphics.draw(
        attackEffect.img,
        math.floor(faceX + attackOffset),
        math.floor(faceY),
        0,
        attackScaleX,
        attackScaleY,
        math.floor(attackEffect.img:getWidth() / 2),
        math.floor(attackEffect.img:getHeight() / 2)
      )
    end
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
  elseif gameStateManager.gameState == gameStateManager.states.CONFIRM_SELECTION then
    if keys.isEnterKey(key) then
      gameStateManager:transitionTo(gameStateManager.states.GAME)
    end
  elseif gameStateManager:stateIs(gameStateManager.states.GAME) then
    if key == 'space' then
      pingPongManager:launchBall()
    end
    if keys.isAnyOf(key, {'up', 'down', 'w', 's'}) then
      pingPongManager:keypressed(key)
    end
  else
    selectionScreen:keypressed(key, gameStateManager.gameState)
  end
end

function love.keyreleased(key)
  if gameStateManager:stateIs(gameStateManager.states.GAME) then
    if keys.isAnyOf(key, {'up', 'down', 'w', 's'}) then
      pingPongManager:keyreleased(key)
    end
  end
end
function love.resize(w, h)
	resolutionManager:recalculate()
end
