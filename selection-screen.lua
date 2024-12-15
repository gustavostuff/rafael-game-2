local resolutionManager = require 'resolution-manager'

local selectionScreen = {
  pokemonItems = {},
  gridRows = 4,
  gridColumns = 4,
  gridCellSize = 64,
  cellMargin = 4,
  cursor = {x = 1, y = 1},
  -- debug = true
}

local function getPokemonData(pokemonFile)
  local pokemonFileWithoutExtension = string.sub(pokemonFile, 1, string.len(pokemonFile) - 4)
  local parts = split(pokemonFileWithoutExtension, "_")
  return parts[1], parts[2]  -- name, type
end

function selectionScreen:init(pokemonDirectory)
  local pokemonFileList = love.filesystem.getDirectoryItems(pokemonDirectory)

  -- always 4 columns, dynamic rows:
  self.gridRows = math.ceil(#pokemonFileList / self.gridColumns)

  local pokemonIndex = 1
  for rowIndex = 1, self.gridRows do
    for columnIndex = 1, self.gridColumns do
      if pokemonIndex > #pokemonFileList then
        break
      end

      local pokemonFile = pokemonFileList[pokemonIndex]
      local name, type = getPokemonData(pokemonFile)

      -- Grid coordinates start from 0 for convenience
      local x = columnIndex
      local y = rowIndex

      self.pokemonItems[x .. "-" .. y] = {
        name = name,
        type = type,
        image = love.graphics.newImage(pokemonDirectory .. pokemonFile),
        gridX = x,
        gridY = y
      }

      pokemonIndex = pokemonIndex + 1
    end
  end

  self.selectionGridWidth = self.gridColumns * (self.gridCellSize + self.cellMargin)
  self.selectionGridHeight = self.gridRows * (self.gridCellSize + self.cellMargin)

  -- top-left corner:
  self.selectionGridX = self.cellMargin / 2
  self.selectionGridY = self.cellMargin / 2
end

function selectionScreen:drawPokemonGrid(cellOffset)
  for coords, pokemon in pairs(self.pokemonItems) do
    -- Localize computed positions
    local cellX = self.selectionGridX + (pokemon.gridX - 1) * cellOffset
    local cellY = self.selectionGridY + (pokemon.gridY - 1) * cellOffset
    local imgX = cellX + self.gridCellSize / 2
    local imgY = cellY + self.gridCellSize / 2

    -- Check if this pokemon is currently selected by cursor
    if (self.cursor.x) == pokemon.gridX and (self.cursor.y) == pokemon.gridY then
      love.graphics.setColor(colors.mossGreen)
      love.graphics.rectangle("fill", cellX, cellY, self.gridCellSize, self.gridCellSize, 4)
      love.graphics.setColor(colors.white)
    end

    love.graphics.draw(
      pokemon.image,
      math.floor(imgX), math.floor(imgY),
      0, 1, 1,
      pokemon.image:getWidth() / 2,
      pokemon.image:getHeight() / 2
    )

    local pokemonName = pokemon.name
    local nameX = math.floor(cellX + self.gridCellSize / 2 - font:getWidth(pokemonName) / 2)
    local nameY = math.floor(cellY + self.gridCellSize - font:getHeight() * 1.2)
    love.graphics.print(pokemonName, nameX, nameY)
  end
end

function selectionScreen:drawDebugInfo()
  if self.debug then
    love.graphics.setColor(colors.brickRed)
    for rowIndex = 1, self.gridRows do
      for columnIndex = 1, self.gridColumns do
        local x = self.selectionGridX + (columnIndex - 1) * cellOffset
        local y = self.selectionGridY + (rowIndex - 1) * cellOffset

        love.graphics.rectangle("line", x, y, self.gridCellSize, self.gridCellSize)
      end
    end
    love.graphics.setColor(colors.white)
  end
end

function selectionScreen:draw()
  local cellOffset = self.gridCellSize + self.cellMargin
  love.graphics.setColor(colors.white)

  self:drawPokemonGrid(cellOffset)
  self:drawCurrentPokemonCard()
  self:drawDebugInfo()
end

function selectionScreen:getSelectedPokemon()
  return self.pokemonItems[self.cursor.x .. "-" .. self.cursor.y]
end

function selectionScreen:drawCurrentPokemonCard()
  local pokemon = self:getSelectedPokemon()
  if pokemon then
    -- print('pokemon type: ' .. pokemon.type)
    love.graphics.setColor(colors.white)
    if pokemon.type == "fire" then
      love.graphics.setColor(colors.brickRed)
    elseif pokemon.type == "water" then
      love.graphics.setColor(colors.skyBlue)
    elseif pokemon.type == "grass" then
      love.graphics.setColor(colors.jungleGreen)
    elseif pokemon.type == "electric" then
      love.graphics.setColor(colors.mustard)
    else
      love.graphics.setColor(colors.white)
    end

    local cardWidth = 120
    local cardHeight = 160
    local cardX = canvasWidth * 0.75 - cardWidth / 2
    local cardY = canvasHeight * 0.5 - cardHeight / 2
    local cornerRadius = 4

    love.graphics.rectangle('fill', cardX, cardY, cardWidth, cardHeight, cornerRadius)

    love.graphics.setColor(colors.white)
    love.graphics.draw(pokemon.image,
      math.floor(cardX + cardWidth / 2),
      math.floor(cardY + cardHeight * 0.25),
      0, 1, 1,
      pokemon.image:getWidth() / 2,
      pokemon.image:getHeight() / 2
    )
  end
end

function selectionScreen:changecursor(direction)
  if direction == "up" then
    self.cursor.y = self.cursor.y - 1
  elseif direction == "down" then
    self.cursor.y = self.cursor.y + 1
  elseif direction == "left" then
    self.cursor.x = self.cursor.x - 1
  elseif direction == "right" then
    self.cursor.x = self.cursor.x + 1
  end

  -- Clamp cursor position
  self.cursor.x = math.max(1, math.min(self.cursor.x, self.gridColumns))
  self.cursor.y = math.max(1, math.min(self.cursor.y, self.gridRows))
end

function selectionScreen:keypressed(key)
  if keys.isAnyOf(key, {"up", "down", "left", "right"}) then
    self:changecursor(key)
  end
end

return selectionScreen
