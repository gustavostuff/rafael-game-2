-- _G.loveDebug = true

require 'globals'
require 'text'
keys = require 'keys'

local gameStateManager = require 'game-state-manager'
local selectionScreen = require 'selection-screen'
local progressStorage = require 'progress-storage'
local resolutionManager = require 'resolution-manager'
local scoreManager = require 'score-manager'
local pingPongManager = require 'ping-pong-manager'
local timerManager = require 'timer-manager'
local flux = require 'lib.flux'
local soundManager = require 'sound-manager'
local pokemonField = require 'pokemon-field'
local matchManager = require 'match-manager'
local gameScreen = require 'game-screen'
local postGameScreens = require 'post-game-screens'
local debugOverlay = require 'debug-overlay'

function love.load()
  canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
  canvas:setFilter("nearest", "nearest")

  resolutionManager:init(canvas)
  progressStorage:load()
  pokemonItems = selectionScreen:init("pokemon/", progressStorage)

  font = love.graphics.newFont('fonts/proggy-tiny/proggy-tiny.ttf', 16)
  bigFont = love.graphics.newFont('fonts/proggy-tiny/proggy-tiny.ttf', 32)
  love.graphics.setFont(font)
  love.graphics.setLineWidth(4)
  love.graphics.setLineStyle("rough")

  titleScreen = love.graphics.newImage('title-screen.png')
  soundManager:init()

  gameStateManager:init()
  local ballImg = love.graphics.newImage('other/pokeball.png')
  local paddleImg = love.graphics.newImage('other/paddle.png')

  -- if TESTING_MODE then
  --   pingPongManager.baseBallHorizontalSpeed = 160
  --   pingPongManager.baseBallVerticalSpeed = 180
  --   scoreManager:init({ maxScore = 1 })
  -- else
  --   scoreManager:init({ maxScore = 10 })
  -- end

  matchManager:init(pingPongManager, scoreManager, selectionScreen, pokemonItems)
  pingPongManager:init(ballImg, paddleImg, function(winner, loser, isGameOver)
    matchManager:onScore(winner, loser, isGameOver)
  end, function()
    soundManager:playPaddleBounce()
  end)

  pokemonField:reset()
end

function love.update(dt)
  gameStateManager:update(dt)

  if gameStateManager:stateIs(gameStateManager.states.GAME) then
    pingPongManager:update(dt)
    timerManager:update()
    flux.update(dt)
  end
end

function love.draw()
  love.graphics.setCanvas({canvas, depthstencil = true})
  love.graphics.clear(colors.dark)

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

    local text = "Are you ready?"
    prettyPrint(text, nil, nil, {
      cell = true,
      centered = true,
      vpw = canvasWidth,
      vph = canvasHeight,
      color = colors.white,
      bgColor = colors.black,
    })
  elseif gameStateManager:stateIs(gameStateManager.states.GAME) then
    gameScreen:draw(pingPongManager, scoreManager, selectionScreen, pokemonItems)
  elseif gameStateManager:stateIs(gameStateManager.states.UNLOCK_REVEAL) and matchManager.pendingUnlockPokemon then
    postGameScreens:drawUnlockReveal(matchManager.pendingUnlockPokemon)
  elseif gameStateManager:stateIs(gameStateManager.states.GAME_OVER) then
    postGameScreens:drawGameOver(matchManager.gameOver)
  end

  gameStateManager:draw()

  love.graphics.setCanvas()
  love.graphics.setColor(colors.white)
  resolutionManager:renderCanvas(canvas)
  debugOverlay:draw(selectionScreen, resolutionManager)
end

function love.keypressed(key)
  local ctrl = love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')
  local shift = love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')
  if key == 'r' and ctrl and shift then
    local choice = love.window.showMessageBox(
      "Reset progress",
      "Reset all unlocked Pokémon and victory count?",
      { "Cancel", "Reset" },
      "warning",
      true
    )
    if choice == 2 then
      progressStorage:clearVictories()
      if selectionScreen.pokemonGrid and selectionScreen.pokemonGrid.pokemonItems then
        progressStorage:applyLocks(selectionScreen.pokemonGrid.pokemonItems)
        selectionScreen.pokemonGrid:selectFirstUnlocked()
        selectionScreen.pokemonCard:setPokemon(selectionScreen.pokemonGrid:getSelectedPokemon())
      end
      love.window.showMessageBox(
        "Reset complete",
        "Everything has been reset.",
        { "OK" },
        "info",
        true
      )
    end
    return
  end

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
      gameStateManager:transitionTo(gameStateManager.states.GAME, function()
        scoreManager:resetScores()
        pingPongManager:resetBall()
        pokemonField:reset()
      end)
    end
  elseif gameStateManager:stateIs(gameStateManager.states.UNLOCK_REVEAL) then
    if keys.isEnterKey(key) then
      matchManager:clearPendingUnlock()
      gameStateManager:transitionTo(gameStateManager.states.GAME_OVER)
    end
  elseif gameStateManager:stateIs(gameStateManager.states.GAME) then
    if key == 'space' then
      pingPongManager:launchBall()
    end
    if key == 'r' then
      pingPongManager:resetBall()
    end
    if keys.isAnyOf(key, {'up', 'down', 'w', 's'}) then
      pingPongManager:keypressed(key)
    end
  elseif gameStateManager:stateIs(gameStateManager.states.GAME_OVER) then
    if keys.isEnterKey(key) then
      matchManager:resetGame()
      gameStateManager:transitionTo(gameStateManager.states.SELECTION_SCREEN_P1)
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
