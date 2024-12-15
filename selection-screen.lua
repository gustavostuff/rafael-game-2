local resolutionManager = require 'resolution-manager'

local selectionScreen = {
  pokemonItems = {},
  gridRows = 4,
  gridColumns = 4,
  gridCellSize = 64,
  cellMargin = 16,
  selectedPokemon = {x = 1, y = 1},
  -- debug = true
}

function getPokemonData(pokemonFile)
  local parts = split(pokemonFile, "_")
  local name = parts[1]
  local type = parts[2]

  return name, type
end

function selectionScreen:init(pokemonDirectory)
  local pokemonFileList = love.filesystem.getDirectoryItems(pokemonDirectory)

  local pokemonIndex = 1
  for rowIndex = 1, self.gridRows do
    for columnIndex = 1, self.gridColumns do
      if pokemonIndex > #pokemonFileList then break end

      local pokemonFile = pokemonFileList[pokemonIndex]
      local name, type = getPokemonData(pokemonFile)

      -- Precompute grid positions (x, y)
      local x = (columnIndex - 1) * (self.gridCellSize + self.cellMargin)
      local y = (rowIndex - 1) * (self.gridCellSize + self.cellMargin)

      table.insert(self.pokemonItems, {
        name = name,
        type = type,
        image = love.graphics.newImage(pokemonDirectory .. pokemonFile),
        gridX = x,
        gridY = y
      })

      pokemonIndex = pokemonIndex + 1
    end
  end

  self.selectionGridWidth = self.gridColumns * (self.gridCellSize + self.cellMargin)
  self.selectionGridHeight = self.gridRows * (self.gridCellSize + self.cellMargin)
  self.selectionGridX = canvasWidth / 2 - self.selectionGridWidth / 2
  self.selectionGridY = canvasHeight / 2 - self.selectionGridHeight / 2

  -- top-left corner:
  self.selectionGridX = self.cellMargin / 2
  self.selectionGridY = self.cellMargin / 2
end

function selectionScreen:draw()
  for i, pokemon in ipairs(self.pokemonItems) do
    local imgX = pokemon.gridX + self.gridCellSize / 2
    local imgY = pokemon.gridY + self.gridCellSize / 2

    love.graphics.setColor(colors.white)

    -- Highlight selected Pokémon
    if self.selectedPokemon.x == (pokemon.gridX / (self.gridCellSize + self.cellMargin)) + 1 and
       self.selectedPokemon.y == (pokemon.gridY / (self.gridCellSize + self.cellMargin)) + 1 then
      love.graphics.setColor(colors.mossGreen)
      love.graphics.rectangle("fill",
        self.selectionGridX + pokemon.gridX,
        self.selectionGridY + pokemon.gridY,
        self.gridCellSize,
        self.gridCellSize,
        4
      )
      love.graphics.setColor(colors.white)
    end

    love.graphics.draw(pokemon.image,
      math.floor(self.selectionGridX + imgX),
      math.floor(self.selectionGridY + imgY),
      0, 1, 1,
      pokemon.image:getWidth() / 2,
      pokemon.image:getHeight() / 2
    )

    love.graphics.setColor(colors.white)
    local pokemonName = pokemon.name
    love.graphics.print(
      pokemonName,
      math.floor(self.selectionGridX + pokemon.gridX + self.gridCellSize / 2 - font:getWidth(pokemonName) / 2),
      math.floor(self.selectionGridY + pokemon.gridY + self.gridCellSize - font:getHeight() * 1.2)
    )
  end

  if self.debug then
    -- Draw grid for debugging
    for rowIndex = 1, self.gridRows do
      for columnIndex = 1, self.gridColumns do
        local x = (columnIndex - 1) * (self.gridCellSize + self.cellMargin)
        local y = (rowIndex - 1) * (self.gridCellSize + self.cellMargin)

        love.graphics.setColor(colors.brickRed)
        love.graphics.rectangle("line",
          self.selectionGridX + x,
          self.selectionGridY + y,
          self.gridCellSize,
          self.gridCellSize
        )
      end
    end
  end
end

function selectionScreen:changeSelectedPokemon(direction)
  if direction == "up" then
    self.selectedPokemon.y = self.selectedPokemon.y - 1
  elseif direction == "down" then
    self.selectedPokemon.y = self.selectedPokemon.y + 1
  elseif direction == "left" then
    self.selectedPokemon.x = self.selectedPokemon.x - 1
  elseif direction == "right" then
    self.selectedPokemon.x = self.selectedPokemon.x + 1
  end

  if self.selectedPokemon.x < 1 then
    self.selectedPokemon.x = self.gridColumns
  elseif self.selectedPokemon.x > self.gridColumns then
    self.selectedPokemon.x = 1
  end

  if self.selectedPokemon.y < 1 then
    self.selectedPokemon.y = self.gridRows
  elseif self.selectedPokemon.y > self.gridRows then
    self.selectedPokemon.y = 1
  end
end

function selectionScreen:keypressed(key)
  if keys.isAnyOf(key, {"up", "down", "left", "right"}) then
    self:changeSelectedPokemon(key)
  end
end

return selectionScreen
