-- selectionScreen.lua
local resolutionManager = require 'resolution-manager'
local gameStateManager  = require 'game-state-manager'
local pokemonGrid  = require 'pokemon-grid'
local pokemonCard  = require 'pokemon-card'

local selectionScreen = {
  -- If you want to enable debugging for the grid
  debug = false,
  selectedPokemon = {}
}

function selectionScreen:init(pokemonDirectory)
  -- 1) Init the grid module
  pokemonGrid.debug = self.debug
  pokemonGrid:init(pokemonDirectory)
  self.pokemonGrid = pokemonGrid

  -- 2) Init the card module
  --    Suppose we have a global or passed-in canvas size:
  local w, h = canvasWidth, canvasHeight
  pokemonCard:init(w, h)
  self.pokemonCard = pokemonCard

  -- Grab the initially selected Pokémon from the grid
  local firstSelection = pokemonGrid:getSelectedPokemon()
  pokemonCard:setPokemon(firstSelection)
end

function selectionScreen:drawSelectedPokemon(playerNumber)
  if self.selectedPokemon['player' .. playerNumber] then
    local scissor = { x = 20, y = 133, w = 64, h = 33 }

    if playerNumber == 2 then
      scissor.x = 88
    end

    love.graphics.setScissor(scissor.x, scissor.y, scissor.w, scissor.h)
    love.graphics.clear(colors.darkGray)

    local pokemon = self.selectedPokemon['player' .. playerNumber]
    love.graphics.draw(
      pokemon.image,
      math.floor(scissor.x + scissor.w / 2),
      math.floor(scissor.y + scissor.h / 2),
      0, 1, 1,
      math.floor(pokemon.facePosition.x),
      math.floor(pokemon.facePosition.y)
    )

    love.graphics.setColor(colors.white)
    prettyPrint('P' .. playerNumber, scissor.x + 3, scissor.y + scissor.h - 11, {cell   = true})
    love.graphics.setScissor()
  end
end

function selectionScreen:draw()
  love.graphics.setColor(colors.white)
  pokemonGrid:drawGrid()

  self:drawSelectedPokemon(1)
  self:drawSelectedPokemon(2)

  pokemonCard:draw()
  pokemonGrid:drawDebugInfo()
end

function selectionScreen:moveCursor(key)
  if keys.isAnyOf(key, {"up", "down", "left", "right"}) then
    pokemonGrid:changecursor(key)
    pokemonGrid:updateViewport()

    -- Update the card with the new selection
    local newSelection = pokemonGrid:getSelectedPokemon()
    pokemonCard:setPokemon(newSelection)
  end
end

function selectionScreen:keypressed(key, gameState)
  -- Let the grid handle cursor changes
  if gameState == gameStateManager.states.SELECTION_SCREEN_P1 then
    self:moveCursor(key)

    if keys.isEnterKey(key) then
      gameStateManager:transitionTo(gameStateManager.states.SELECTION_SCREEN_P2, function ()
        self.selectedPokemon['player' .. self.pokemonGrid.currentPlayer] = self.pokemonGrid:getSelectedPokemon()
        self.pokemonGrid:setSelectedPokemon(1, 1)
        self.pokemonGrid.verticalViewport = { y0 = 1, y1 = 4 }
        self.pokemonCard:setPokemon(self.pokemonGrid:getSelectedPokemon())
        self.pokemonGrid.currentPlayer = 2
      end)
    end
  elseif gameState == gameStateManager.states.SELECTION_SCREEN_P2 then
    self:moveCursor(key)
    if keys.isEnterKey(key) then
      gameStateManager:transitionTo(gameStateManager.states.CONFIRM_SELECTION, function ()
        self.selectedPokemon['player' .. self.pokemonGrid.currentPlayer] = self.pokemonGrid:getSelectedPokemon()
      end)
    end
  end
end

return selectionScreen
