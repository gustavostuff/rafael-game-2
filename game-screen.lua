local attackManager = require 'attack-manager'
local pokemonField = require 'pokemon-field'

local gameScreen = {}

function gameScreen:draw(pingPongManager, scoreManager, selectionScreen, pokemonItems)
  local pokemonPlayer1 = pokemonField:getPokemonByName(
    selectionScreen.selectedPokemon['player1'].name,
    pokemonItems
  )
  local pokemonPlayer2 = pokemonField:getPokemonByName(
    selectionScreen.selectedPokemon['player2'].name,
    pokemonItems
  )

  pingPongManager:draw()
  scoreManager:draw()
  pokemonField:draw(pokemonPlayer1, pokemonPlayer2)

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
        bgColor = colors.black,
      }
    )
    love.graphics.setFont(font)
  end

  attackManager:draw(pokemonField.positions)
end

return gameScreen
