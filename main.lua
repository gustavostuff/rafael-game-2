-- _G.loveDebug = true

-- When true: shorter matches (1 life / bar per player) and faster ball.
local TESTING_MODE = true

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
local gameOver = {
  winner = nil,
  loser = nil
}
local pendingUnlockPokemon = nil
local victoryResetFeedbackT = 0
local VICTORY_RESET_FEEDBACK_DURATION = 2.5
local scoreSound = nil
local paddleBounceSound = nil
local attackDelayId = nil
local pokemonPositions = {
  player1 = { x = 0, y = 0 },
  player2 = { x = 0, y = 0 }
}
local pokemonBasePositions = {
  player1 = { x = 0, y = 0 },
  player2 = { x = 0, y = 0 }
}

local function getPokemonByName(name, list)
  for _, pokemon in pairs(list) do
    if pokemon.name == name then
      return pokemon
    end
  end
end

local function resetPokemonPositions()
  local p1x = 36
  local p2x = canvasWidth - 36
  local py = canvasHeight / 2

  if flux.tweens and flux.tweens[pokemonPositions.player1] then
    flux:clear(pokemonPositions.player1, { x = true, y = true })
  end
  if flux.tweens and flux.tweens[pokemonPositions.player2] then
    flux:clear(pokemonPositions.player2, { x = true, y = true })
  end
  pokemonPositions.player1.x = p1x
  pokemonPositions.player1.y = py
  pokemonPositions.player2.x = p2x
  pokemonPositions.player2.y = py
  pokemonBasePositions.player1.x = p1x
  pokemonBasePositions.player1.y = py
  pokemonBasePositions.player2.x = p2x
  pokemonBasePositions.player2.y = py
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
  if attackImages[typeName] == nil then
    local path = 'attacks/' .. typeName .. '.png'
    if love.filesystem.getInfo(path) then
      attackImages[typeName] = love.graphics.newImage(path)
    else
      attackImages[typeName] = false
    end
  end
  return attackImages[typeName] or nil
end

local function triggerAttack(player, onDone)
  local selected = selectionScreen.selectedPokemon[player]
  if not selected or not selected.type then
    if onDone then
      onDone()
    end
    return
  end

  if attackEffect.timeoutId then
    timerManager:cancel(attackEffect.timeoutId)
  end
  if attackEffect.oscillateId then
    timerManager:cancel(attackEffect.oscillateId)
  end

  attackEffect.player = player
  attackEffect.img = getAttackImage(selected.type)
  if not attackEffect.img then
    attackEffect.player = nil
    attackEffect.visible = false
    if onDone then
      onDone()
    end
    return
  end
  attackEffect.visible = true
  attackEffect.flipY = false

  attackEffect.oscillateId = timerManager:every(0.15, function()
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
    if onDone then
      onDone()
    end
  end)
end

local function handleScore(winner, loser, isGameOver)
  if scoreSound then
    scoreSound:stop()
    scoreSound:play()
  end

  if attackDelayId then
    timerManager:cancel(attackDelayId)
    attackDelayId = nil
  end
  if flux.tweens and flux.tweens[pokemonPositions.player1] then
    flux:clear(pokemonPositions.player1, { x = true })
  end
  if flux.tweens and flux.tweens[pokemonPositions.player2] then
    flux:clear(pokemonPositions.player2, { x = true })
  end

  if not isGameOver then
    attackDelayId = timerManager:after(1, function()
      attackDelayId = nil
      local attackerPos = pokemonPositions[winner]
      local defenderPos = pokemonPositions[loser]
      local targetX
      if winner == 'player1' then
        targetX = defenderPos.x - 100
      else
        targetX = defenderPos.x + 100
      end

      flux.to(attackerPos, 0.5, { x = targetX }):oncomplete(function()
        triggerAttack(winner, function()
          pingPongManager:startLaunchCountdown(0)
          local baseX = pokemonBasePositions[winner].x
          flux.to(attackerPos, 0.5, { x = baseX }):oncomplete(function()
            resetPokemonPositions()
          end)
        end)
      end)
    end)
    return
  end

  gameOver.winner = winner
  gameOver.loser = loser
  local prevExtra = progressStorage:extraUnlockedCount()
  progressStorage:recordVictory(winner)
  progressStorage:save()
  local unlockedName = progressStorage:nameJustUnlocked(prevExtra)
  progressStorage:applyLocks(selectionScreen.pokemonGrid.pokemonItems)
  pingPongManager:resetBall(false)

  if unlockedName then
    pendingUnlockPokemon = getPokemonByName(unlockedName, pokemonItems)
  else
    pendingUnlockPokemon = nil
  end

  if unlockedName and pendingUnlockPokemon then
    gameStateManager:transitionTo(gameStateManager.states.UNLOCK_REVEAL)
  else
    pendingUnlockPokemon = nil
    gameStateManager:transitionTo(gameStateManager.states.GAME_OVER)
  end
end

local function handlePaddleBounce()
  if paddleBounceSound then
    paddleBounceSound:stop()
    paddleBounceSound:play()
  end
end

local function resetGame()
  gameOver.winner = nil
  gameOver.loser = nil
  scoreManager:resetScores()
  pingPongManager:resetBall()
  if attackDelayId then
    timerManager:cancel(attackDelayId)
    attackDelayId = nil
  end
  if attackEffect.timeoutId then
    timerManager:cancel(attackEffect.timeoutId)
    attackEffect.timeoutId = nil
  end
  if attackEffect.oscillateId then
    timerManager:cancel(attackEffect.oscillateId)
    attackEffect.oscillateId = nil
  end
  attackEffect.visible = false
  attackEffect.player = nil
  attackEffect.img = nil
  attackEffect.flipY = false
  selectionScreen.selectedPokemon = {}
  selectionScreen.pokemonGrid.currentPlayer = 1
  progressStorage:applyLocks(selectionScreen.pokemonGrid.pokemonItems)
  selectionScreen.pokemonGrid.verticalViewport = { y0 = 1, y1 = 4 }
  selectionScreen.pokemonGrid:selectFirstUnlocked()
  selectionScreen.pokemonCard:setPokemon(selectionScreen.pokemonGrid:getSelectedPokemon())
  resetPokemonPositions()
end

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

  love.audio.setVolume(0.5)
  bgMusic = love.audio.newSource('bg-music.ogg', 'stream')
  bgMusic:setLooping(true)
  bgMusic:play()
  scoreSound = love.audio.newSource('sounds/score.wav', 'static')
  paddleBounceSound = love.audio.newSource('sounds/pokeball_bounce.wav', 'static')

  gameStateManager:init()
  local ballImg = love.graphics.newImage('other/pokeball.png')
  local paddleImg = love.graphics.newImage('other/paddle.png')

  if TESTING_MODE then
    pingPongManager.baseBallHorizontalSpeed = 160
    pingPongManager.baseBallVerticalSpeed = 180
    scoreManager:init({ maxScore = 1 })
  else
    scoreManager:init({ maxScore = 10 })
  end
  pingPongManager:init(ballImg, paddleImg, handleScore, handlePaddleBounce)

  resetPokemonPositions()
end

function love.update(dt)
  gameStateManager:update(dt)

  if victoryResetFeedbackT > 0 then
    victoryResetFeedbackT = math.max(0, victoryResetFeedbackT - dt)
  end

  if gameStateManager:stateIs(gameStateManager.states.GAME) then
    pingPongManager:update(dt)
    timerManager:update()
    flux.update(dt)
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
  prettyPrint(table.concat(items, '\n'), 20, 20, {
    cell = true,
    color = colors.white,
    bgColor = colors.black
  })
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

    local text = "Are you ready?"
    prettyPrint(text, nil, nil, {
      cell = true,
      centered = true,
      vpw = canvasWidth,
      vph = canvasHeight,
      color = colors.white,
      bgColor = colors.black
    })
  elseif gameStateManager:stateIs(gameStateManager.states.GAME) then
    local pokemonPlayer1 = getPokemonByName(selectionScreen.selectedPokemon['player1'].name, pokemonItems)
    local pokemonPlayer2 = getPokemonByName(selectionScreen.selectedPokemon['player2'].name, pokemonItems)

    pingPongManager:draw()
    scoreManager:draw()

    -- draw pokemon on top of the field
    love.graphics.setColor(colors.white)
    love.graphics.draw(
      pokemonPlayer1.image,
      pokemonPositions.player1.x,
      pokemonPositions.player1.y,
      0,
      -1,
      1,
      pokemonPlayer1.facePosition.x,
      pokemonPlayer1.facePosition.y
    )
    love.graphics.draw(
      pokemonPlayer2.image,
      pokemonPositions.player2.x,
      pokemonPositions.player2.y,
      0,
      1,
      1,
      pokemonPlayer2.facePosition.x,
      pokemonPlayer2.facePosition.y
    )

    local countdown = pingPongManager:getLaunchCountdown()
    if countdown and countdown > 0 then
      local text = tostring(countdown)
      love.graphics.setFont(bigFont)
      prettyPrint(text,
        (canvasWidth - bigFont:getWidth(text)) / 2,
        (canvasHeight - bigFont:getHeight()) / 2,
        {
          cell = true,
          color = colors.white,
          bgColor = colors.black
        }
      )
      love.graphics.setFont(font)
    end

    if attackEffect.visible and attackEffect.img and attackEffect.player then
      local faceX = attackEffect.player == 'player1' and pokemonPositions.player1.x or pokemonPositions.player2.x
      local faceY = attackEffect.player == 'player1' and pokemonPositions.player1.y or pokemonPositions.player2.y
      local attackScaleX = attackEffect.player == 'player2' and -1 or 1
      local attackScaleY = attackEffect.flipY and -1 or 1
      local originX = 0

      love.graphics.draw(
        attackEffect.img,
        math.floor(faceX),
        math.floor(faceY),
        0,
        attackScaleX,
        attackScaleY,
        originX,
        math.floor(attackEffect.img:getHeight() / 2)
      )
    end
  elseif gameStateManager:stateIs(gameStateManager.states.UNLOCK_REVEAL) and pendingUnlockPokemon then
    love.graphics.setColor(colors.dark)
    love.graphics.rectangle("fill", 0, 0, canvasWidth, canvasHeight)

    love.graphics.setFont(bigFont)
    local title = "New Pokemon!"
    prettyPrint(title,
      (canvasWidth - bigFont:getWidth(title)) / 2,
      16,
      { cell = true, color = colors.yellow, bgColor = colors.black }
    )

    love.graphics.setFont(font)
    local nameLine = toCapitalCase(pendingUnlockPokemon.name) .. "!"
    prettyPrint(nameLine,
      (canvasWidth - font:getWidth(nameLine)) / 2,
      46,
      { cell = true, color = colors.white, bgColor = colors.black }
    )

    love.graphics.setColor(colors.white)
    love.graphics.draw(
      pendingUnlockPokemon.image,
      math.floor(canvasWidth / 2),
      math.floor(canvasHeight / 2 + 10),
      0,
      1,
      1,
      pendingUnlockPokemon.facePosition.x,
      pendingUnlockPokemon.facePosition.y
    )

    local hint = "Press Enter"
    prettyPrint(hint,
      (canvasWidth - font:getWidth(hint)) / 2,
      canvasHeight - 26,
      { cell = true, color = colors.yellow, bgColor = colors.black }
    )
    love.graphics.setFont(font)
  elseif gameStateManager:stateIs(gameStateManager.states.GAME_OVER) then
    love.graphics.setColor(colors.dark)
    love.graphics.rectangle("fill", 0, 0, canvasWidth, canvasHeight)

    local winnerLabel = gameOver.winner == 'player1' and 'P1' or 'P2'
    local loserLabel = gameOver.loser == 'player1' and 'P1' or 'P2'
    local titleLeft = winnerLabel
    local titleRight = " Wins!"
    local subtitleLeft = "Loser: "
    local subtitleMid = loserLabel
    local subtitleRight = "  |  Press Enter to reset"
    local winnerColor = winnerLabel == 'P1' and colors.blue or colors.red
    local loserColor = loserLabel == 'P1' and colors.blue or colors.red

    love.graphics.setFont(bigFont)
    local titleWidth = bigFont:getWidth(titleLeft) + bigFont:getWidth(titleRight)
    local titleX = (canvasWidth - titleWidth) / 2
    local titleY = (canvasHeight - bigFont:getHeight()) / 2 - 16
    prettyPrint(titleLeft, titleX, titleY, {
      cell = true,
      color = winnerColor,
      bgColor = colors.black
    })
    prettyPrint(titleRight, titleX + bigFont:getWidth(titleLeft), titleY, {
      cell = true,
      color = colors.white,
      bgColor = colors.black
    })
    love.graphics.setFont(font)
    local subtitleWidth = font:getWidth(subtitleLeft) + font:getWidth(subtitleMid) + font:getWidth(subtitleRight)
    local subtitleX = (canvasWidth - subtitleWidth) / 2
    local subtitleY = (canvasHeight - font:getHeight()) / 2 + 12
    prettyPrint(subtitleLeft, subtitleX, subtitleY, {
      cell = true,
      color = colors.white,
      bgColor = colors.black
    })
    prettyPrint(subtitleMid, subtitleX + font:getWidth(subtitleLeft), subtitleY, {
      cell = true,
      color = loserColor,
      bgColor = colors.black
    })
    prettyPrint(
      subtitleRight,
      subtitleX + font:getWidth(subtitleLeft) + font:getWidth(subtitleMid),
      subtitleY,
      {
        cell = true,
        color = colors.yellow,
        bgColor = colors.black
      }
    )
  end
  gameStateManager:draw()

  if victoryResetFeedbackT > 0 then
    love.graphics.setFont(font)
    local msg = "Victory counts reset"
    local rem = victoryResetFeedbackT
    local fadeOut = 0.45
    local a = rem < fadeOut and (rem / fadeOut) or 1
    local pad = 6
    local w = font:getWidth(msg) + pad * 2
    local h = math.floor(font:getHeight() * 1.2) + pad * 2
    local x = math.floor((canvasWidth - w) / 2)
    local y = 10
    love.graphics.setColor(0, 0, 0, 0.78 * a)
    love.graphics.rectangle("fill", x, y, w, h, 4)
    prettyPrint(msg, x + pad, y + pad, {
      cell = true,
      color = { colors.white[1], colors.white[2], colors.white[3], a },
      bgColor = { colors.black[1], colors.black[2], colors.black[3], a },
    })
    love.graphics.setColor(colors.white)
  end
  
  ---------------------------------------------------------------
  
	love.graphics.setCanvas()
	love.graphics.setColor(colors.white)
	resolutionManager:renderCanvas(canvas)
  printDebugInfo()
  -- drawColorPalette()
end

function love.keypressed(key)
  local ctrl = love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')
  local shift = love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')
  if key == 'r' and ctrl and shift then
    progressStorage:clearVictories()
    if selectionScreen.pokemonGrid and selectionScreen.pokemonGrid.pokemonItems then
      progressStorage:applyLocks(selectionScreen.pokemonGrid.pokemonItems)
      selectionScreen.pokemonGrid:selectFirstUnlocked()
      selectionScreen.pokemonCard:setPokemon(selectionScreen.pokemonGrid:getSelectedPokemon())
    end
    victoryResetFeedbackT = VICTORY_RESET_FEEDBACK_DURATION
    if paddleBounceSound then
      paddleBounceSound:stop()
      paddleBounceSound:play()
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
      gameStateManager:transitionTo(gameStateManager.states.GAME, function ()
        scoreManager:resetScores()
        pingPongManager:resetBall()
        resetPokemonPositions()
      end)
    end
  elseif gameStateManager:stateIs(gameStateManager.states.UNLOCK_REVEAL) then
    if keys.isEnterKey(key) then
      pendingUnlockPokemon = nil
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
      resetGame()
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
