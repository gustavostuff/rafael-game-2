-- selectionScreen.lua
local resolutionManager = require 'resolution-manager'
local pokemonGrid  = require 'pokemon-grid'
local pokemonCard  = require 'pokemon-card'

local selectionScreen = {
  -- If you want to enable debugging for the grid
  debug = false
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

function selectionScreen:draw()
  love.graphics.setColor(colors.white)
  pokemonGrid:drawGrid()
  pokemonCard:draw()
  pokemonGrid:drawDebugInfo()
end

function selectionScreen:keypressed(key)
  -- Let the grid handle cursor changes
  if keys.isAnyOf(key, {"up", "down", "left", "right"}) then
    pokemonGrid:changecursor(key)
    pokemonGrid:updateViewport()

    -- Update the card with the new selection
    local newSelection = pokemonGrid:getSelectedPokemon()
    pokemonCard:setPokemon(newSelection)
  end
end

return selectionScreen
