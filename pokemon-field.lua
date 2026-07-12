local flux = require 'lib.flux'

local pokemonField = {
  positions = {
    player1 = { x = 0, y = 0 },
    player2 = { x = 0, y = 0 },
  },
  basePositions = {
    player1 = { x = 0, y = 0 },
    player2 = { x = 0, y = 0 },
  },
}

function pokemonField:clearTweens()
  if flux.tweens and flux.tweens[self.positions.player1] then
    flux:clear(self.positions.player1, { x = true, y = true })
  end
  if flux.tweens and flux.tweens[self.positions.player2] then
    flux:clear(self.positions.player2, { x = true, y = true })
  end
end

function pokemonField:reset()
  local p1x = 36
  local p2x = canvasWidth - 36
  local py = canvasHeight / 2

  self:clearTweens()
  self.positions.player1.x = p1x
  self.positions.player1.y = py
  self.positions.player2.x = p2x
  self.positions.player2.y = py
  self.basePositions.player1.x = p1x
  self.basePositions.player1.y = py
  self.basePositions.player2.x = p2x
  self.basePositions.player2.y = py
end

function pokemonField:getPokemonByName(name, list)
  for _, pokemon in pairs(list) do
    if pokemon.name == name then
      return pokemon
    end
  end
end

function pokemonField:draw(pokemonPlayer1, pokemonPlayer2)
  love.graphics.setColor(colors.white)
  love.graphics.draw(
    pokemonPlayer1.image,
    self.positions.player1.x,
    self.positions.player1.y,
    0,
    -1,
    1,
    pokemonPlayer1.facePosition.x,
    pokemonPlayer1.facePosition.y
  )
  love.graphics.draw(
    pokemonPlayer2.image,
    self.positions.player2.x,
    self.positions.player2.y,
    0,
    1,
    1,
    pokemonPlayer2.facePosition.x,
    pokemonPlayer2.facePosition.y
  )
end

return pokemonField
