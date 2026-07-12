local flux = require 'lib.flux'
local timerManager = require 'timer-manager'
local attackManager = require 'attack-manager'
local pokemonField = require 'pokemon-field'
local soundManager = require 'sound-manager'
local progressStorage = require 'progress-storage'
local gameStateManager = require 'game-state-manager'

local matchManager = {
  gameOver = {
    winner = nil,
    loser = nil,
  },
  pendingUnlockPokemon = nil,
  attackDelayId = nil,
}

function matchManager:init(pingPongManager, scoreManager, selectionScreen, pokemonItems)
  self.pingPongManager = pingPongManager
  self.scoreManager = scoreManager
  self.selectionScreen = selectionScreen
  self.pokemonItems = pokemonItems
end

function matchManager:onScore(winner, loser, isGameOver)
  soundManager:playScore()

  if self.attackDelayId then
    timerManager:cancel(self.attackDelayId)
    self.attackDelayId = nil
  end
  pokemonField:clearTweens()

  if not isGameOver then
    self.attackDelayId = timerManager:after(1, function()
      self.attackDelayId = nil
      local attackerPos = pokemonField.positions[winner]
      local defenderPos = pokemonField.positions[loser]
      local targetX
      if winner == 'player1' then
        targetX = defenderPos.x - 100
      else
        targetX = defenderPos.x + 100
      end

      flux.to(attackerPos, 0.5, { x = targetX }):oncomplete(function()
        local selected = self.selectionScreen.selectedPokemon[winner]
        attackManager:trigger(winner, selected, function()
          self.pingPongManager:startLaunchCountdown(0)
          local baseX = pokemonField.basePositions[winner].x
          flux.to(attackerPos, 0.5, { x = baseX }):oncomplete(function()
            pokemonField:reset()
          end)
        end)
      end)
    end)
    return
  end

  self.gameOver.winner = winner
  self.gameOver.loser = loser
  local prevExtra = progressStorage:extraUnlockedCount()
  progressStorage:recordVictory(winner)
  progressStorage:save()
  local unlockedName = progressStorage:nameJustUnlocked(prevExtra)
  progressStorage:applyLocks(self.selectionScreen.pokemonGrid.pokemonItems)
  self.pingPongManager:resetBall(false)

  if unlockedName then
    self.pendingUnlockPokemon = pokemonField:getPokemonByName(unlockedName, self.pokemonItems)
  else
    self.pendingUnlockPokemon = nil
  end

  if unlockedName and self.pendingUnlockPokemon then
    gameStateManager:transitionTo(gameStateManager.states.UNLOCK_REVEAL)
  else
    self.pendingUnlockPokemon = nil
    gameStateManager:transitionTo(gameStateManager.states.GAME_OVER)
  end
end

function matchManager:resetGame()
  self.gameOver.winner = nil
  self.gameOver.loser = nil
  self.scoreManager:resetScores()
  self.pingPongManager:resetBall()

  if self.attackDelayId then
    timerManager:cancel(self.attackDelayId)
    self.attackDelayId = nil
  end
  attackManager:reset()

  self.selectionScreen.selectedPokemon = {}
  self.selectionScreen.pokemonGrid.currentPlayer = 1
  progressStorage:applyLocks(self.selectionScreen.pokemonGrid.pokemonItems)
  self.selectionScreen.pokemonGrid.verticalViewport = { y0 = 1, y1 = 4 }
  self.selectionScreen.pokemonGrid:selectFirstUnlocked()
  self.selectionScreen.pokemonCard:setPokemon(self.selectionScreen.pokemonGrid:getSelectedPokemon())
  pokemonField:reset()
end

function matchManager:clearPendingUnlock()
  self.pendingUnlockPokemon = nil
end

return matchManager
