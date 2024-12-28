-- selectionScreen.lua

local resolutionManager = require 'resolution-manager'
local pokemonGrid       = require 'pokemon-grid'
local pokemonCard       = require 'pokemon-card'

local selectionScreen = { debug = false }

function selectionScreen:init(d)
  pokemonGrid.debug = self.debug
  pokemonGrid:init(d)
  self.pokemonGrid = pokemonGrid

  local w, h = canvasWidth, canvasHeight

  self.pokemonCardP1 = pokemonCard.new(135, 20)

  self.pokemonCardP2 = pokemonCard.new(135, 90)

  -- Offset card 2 so they are not in the same place
  self.pokemonCardP2.cardX = self.pokemonCardP2.cardX - 200

  local s1 = self.pokemonGrid:getSelectedPokemon("p1")
  local s2 = self.pokemonGrid:getSelectedPokemon("p2")
  self.pokemonCardP1:setPokemon(s1)
  self.pokemonCardP2:setPokemon(s2)
end

function selectionScreen:draw()
  love.graphics.setColor(colors.white)
  self.pokemonGrid:drawGrid()
  self.pokemonCardP1:draw()
  self.pokemonCardP2:draw()
  self.pokemonGrid:drawDebugInfo()
end

function selectionScreen:keypressed(k)
  if keys.isAnyOf(k, { "w", "a", "s", "d" }) then
    self.pokemonGrid:changecursor("p1", k)
    self.pokemonGrid:updateViewport("p1")
    local s = self.pokemonGrid:getSelectedPokemon("p1")
    self.pokemonCardP1:setPokemon(s)
  elseif keys.isAnyOf(k, { "up", "down", "left", "right" }) then
    self.pokemonGrid:changecursor("p2", k)
    self.pokemonGrid:updateViewport("p2")
    local s = self.pokemonGrid:getSelectedPokemon("p2")
    self.pokemonCardP2:setPokemon(s)
  end
end

return selectionScreen
