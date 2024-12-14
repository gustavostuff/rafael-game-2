local resolutionManager = require 'resolution-manager'

local selectionScreen = {
  pokemonItems = {},
  gridRows = 3,
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

  for i = 1, #pokemonFileList do
    local pokemonFile = pokemonFileList[i]
    -- file names are: <pokemon name>_<type>.png
    local name, type = getPokemonData(pokemonFile)

    table.insert(self.pokemonItems, {
      name = name,
      type = type,
      image = love.graphics.newImage(pokemonDirectory .. pokemonFile)
    })
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
  -- debug to print name and type of each pokemon

  local pokemonIndex = 1
  local rowIndex = 1
  local columnIndex = 1

  for i = 1, #self.pokemonItems do
    local pokemon = self.pokemonItems[i]

    if rowIndex > self.gridRows then
      rowIndex = 1
      columnIndex = columnIndex + 1
    end

    if columnIndex > self.gridColumns then
      columnIndex = 1
      rowIndex = rowIndex + 1
    end

    local x = (columnIndex - 1) * (self.gridCellSize + self.cellMargin)
    local y = (rowIndex - 1) * (self.gridCellSize + self.cellMargin)

    local imgX = x + self.gridCellSize / 2
    local imgY = y + self.gridCellSize / 2

    love.graphics.setColor(colors.white)

    if rowIndex == self.selectedPokemon.y and columnIndex == self.selectedPokemon.x then
      love.graphics.setColor(colors.mossGreen)
      love.graphics.rectangle("fill",
        self.selectionGridX + x,
        self.selectionGridY + y,
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
      math.floor(self.selectionGridX + x + self.gridCellSize / 2 - font:getWidth(pokemonName) / 2),
      math.floor(self.selectionGridY + y + self.gridCellSize - font:getHeight() * 1.2)
    )

    rowIndex = rowIndex + 1
  end

  if self.debug then
    -- draw red rectangles to show grid
    for i = 1, self.gridRows do
      for j = 1, self.gridColumns do
        local x = (j - 1) * (self.gridCellSize + self.cellMargin)
        local y = (i - 1) * (self.gridCellSize + self.cellMargin)

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
