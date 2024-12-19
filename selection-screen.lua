local resolutionManager = require 'resolution-manager'

local selectionScreen = {
  pokemonItems = {},
  gridRows = 4,
  gridColumns = 5,
  gridCellSize = 20,
  cellMargin = 8,
  cursor = {x = 1, y = 1},
  selectedPokemon = nil,
  -- debug = true
}

function getNumbersFromStringCoords(coords)
  -- turns "14,56" into {x = 14, y = 56}
  local splitNumbers = split(coords, ",")
  return {x = tonumber(splitNumbers[1]), y = tonumber(splitNumbers[2])}
end

local function getPokemonData(pokemonFile)
  local pokemonFileWithoutExtension = string.sub(pokemonFile, 1, string.len(pokemonFile) - 4)
  local parts = split(pokemonFileWithoutExtension, "_")
  local facePosition = getNumbersFromStringCoords(parts[3])
  return parts[1], parts[2], facePosition  -- name, type, facePosition
end

local function getPokemonColor(pokemonType)
  if pokemonType == "fire" then
    return colors.darkRed
  elseif pokemonType == "water" then
    return colors.skyBlue
  elseif pokemonType == "grass" then
    return colors.darkGreen
  elseif pokemonType == "electric" then
    return colors.mustard
  elseif pokemonType == "dragon" then
    return colors.dragon
  elseif pokemonType == "steel" then
    return colors.steelBlue
  elseif pokemonType == "ice" then
    return colors.iceBlue
  elseif pokemonType == "ghost" then
    return colors.purple
  else
    return colors.white
  end
end

function selectionScreen:init(pokemonDirectory)
  local pokemonFileList = love.filesystem.getDirectoryItems(pokemonDirectory)
  self.gridRows = math.ceil(#pokemonFileList / self.gridColumns)

  local pokemonIndex = 1
  for rowIndex = 1, self.gridRows do
    for columnIndex = 1, self.gridColumns do
      if pokemonIndex > #pokemonFileList then break end
      local pokemonFile = pokemonFileList[pokemonIndex]
      local name, pType, facePosition = getPokemonData(pokemonFile)

      local pokemonImage = love.graphics.newImage(pokemonDirectory .. pokemonFile)
      local imageWidth = pokemonImage:getWidth()
      local imageHeight = pokemonImage:getHeight()

      self.pokemonItems[columnIndex .. "-" .. rowIndex] = {
        name = name,
        type = pType,
        image = pokemonImage,
        imageWidth = imageWidth,
        imageHeight = imageHeight,
        gridX = columnIndex,
        gridY = rowIndex,
        facePosition = facePosition
      }

      pokemonIndex = pokemonIndex + 1
    end
  end

  -- Precompute often-used layout values
  self.cellOffset = self.gridCellSize + self.cellMargin
  self.selectionGridWidth = self.gridColumns * self.cellOffset
  self.selectionGridHeight = self.gridRows * self.cellOffset
  self.selectionGridX = 20
  self.selectionGridY = 20

  -- Card defaults (can be static, no need to recalc unless window changes)
  self.cardWidth = 120
  self.cardHeight = 140
  self.cornerRadius = 4
  self.cardPadding = 10

  self:updateSelectedPokemon()
end

function selectionScreen:updateSelectedPokemon()
  self.selectedPokemon = self.pokemonItems[self.cursor.x .. "-" .. self.cursor.y]
  self:updateCardParams()
end

function selectionScreen:updateCardParams()
  if self.selectedPokemon then
    -- Precompute everything needed for drawing the current card
    self.cardColor = getPokemonColor(self.selectedPokemon.type)

    self.cardX = canvasWidth * 0.75 - self.cardWidth / 2
    self.cardY = canvasHeight * 0.5 - self.cardHeight / 2

    -- Inner rectangle dimensions
    self.innerRectX = self.cardX + self.cardPadding
    self.innerRectY = self.cardY + self.cardPadding
    self.innerRectW = self.cardWidth - self.cardPadding * 2
    self.innerRectH = (self.cardHeight * 0.7) - self.cardPadding * 2

    -- Pokemon image position on the card
    self.pokemonX = math.floor(self.cardX + self.cardWidth / 2)
    self.pokemonY = math.floor(self.cardY + self.cardHeight * 0.35)

    -- Text positions
    local nameYBase = self.cardY + self.cardPadding + (self.cardHeight * 0.7) - font:getHeight() * 1.2
    self.nameX = math.floor(self.cardX + self.cardPadding)
    self.nameY = math.floor(nameYBase)
    self.typeY = math.floor(self.nameY + font:getHeight() * 1.4)

    -- Precompute display strings
    self.displayName = 'Name: ' .. toCapitalCase(self.selectedPokemon.name)
    self.displayType = 'Type: ' .. toCapitalCase(self.selectedPokemon.type)
  else
    self.cardColor = colors.white
    -- If no pokemon selected, nothing to draw, but we keep defaults
  end
end

local function getCellCoordinates(self, gridX, gridY)
  local cellX = self.selectionGridX + (gridX - 1) * self.cellOffset
  local cellY = self.selectionGridY + (gridY - 1) * self.cellOffset
  return cellX, cellY
end

function selectionScreen:drawPokemonGrid()
  for _, pokemon in pairs(self.pokemonItems) do
    local cellX, cellY = getCellCoordinates(self, pokemon.gridX, pokemon.gridY)

    if self.cursor.x == pokemon.gridX and self.cursor.y == pokemon.gridY then
      love.graphics.setColor(colors.mustard)
      love.graphics.rectangle("fill",
        cellX - 3,
        cellY - 3,
        self.gridCellSize + 6,
        self.gridCellSize + 6,
        4
      )
    end

    -- love.graphics.setScissor(cellX, cellY, self.gridCellSize, self.gridCellSize)
    love.graphics.stencil(function()
      love.graphics.rectangle("fill", cellX, cellY, self.gridCellSize, self.gridCellSize, 2)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    love.graphics.setColor(colors.gray)
    love.graphics.rectangle("fill", cellX, cellY, self.gridCellSize, self.gridCellSize)
    love.graphics.setColor(colors.white)
    love.graphics.draw(
      pokemon.image,
      math.floor(cellX + self.gridCellSize / 2),
      math.floor(cellY + self.gridCellSize / 2),
      0, 1, 1,
      math.floor(pokemon.facePosition.x),
      math.floor(pokemon.facePosition.y)
    )

    love.graphics.setStencilTest()
  end
end

function selectionScreen:drawDebugInfo()
  if self.debug then
    love.graphics.setColor(colors.darkRed)
    for rowIndex = 1, self.gridRows do
      for columnIndex = 1, self.gridColumns do
        local x, y = getCellCoordinates(self, columnIndex, rowIndex)
        love.graphics.rectangle("line", x, y, self.gridCellSize, self.gridCellSize)
      end
    end
    love.graphics.setColor(colors.white)
  end
end

function selectionScreen:drawPokemonCard()
  if not self.selectedPokemon then return end

  love.graphics.setColor(self.cardColor)
  love.graphics.rectangle('fill', self.cardX, self.cardY, self.cardWidth, self.cardHeight, self.cornerRadius)

  love.graphics.setColor(colorWithAlpha('black', 0.5))
  love.graphics.rectangle('fill', self.innerRectX, self.innerRectY, self.innerRectW, self.innerRectH)

  love.graphics.setColor(colors.white)
  love.graphics.setScissor(self.innerRectX, self.innerRectY, self.innerRectW, self.innerRectH)
  love.graphics.draw(
    self.selectedPokemon.image,
    self.pokemonX,
    self.pokemonY,
    0, 1, 1,
    math.floor(self.selectedPokemon.imageWidth / 2),
    math.floor(self.selectedPokemon.imageHeight / 2)
  )

  love.graphics.setScissor()

  prettyPrint(self.displayName, self.nameX, self.nameY, {
    cell = true,
    color = colors.almostWhite,
    bgColor = colors.dark
  })
  prettyPrint(self.displayType, self.nameX, self.typeY, {
    cell = true,
    color = colors.almostWhite,
    bgColor = colors.dark
  })
end

function selectionScreen:draw()
  love.graphics.setColor(colors.white)
  self:drawPokemonGrid()
  self:drawPokemonCard()
  self:drawDebugInfo()
end

function selectionScreen:changecursor(direction)
  if direction == "up" then
    if not self.pokemonItems[self.cursor.x .. "-" .. self.cursor.y - 1] then return end
    self.cursor.y = self.cursor.y - 1
  elseif direction == "down" then
    if not self.pokemonItems[self.cursor.x .. "-" .. self.cursor.y + 1] then return end
    self.cursor.y = self.cursor.y + 1
  elseif direction == "left" then
    if not self.pokemonItems[self.cursor.x - 1 .. "-" .. self.cursor.y] then return end
    self.cursor.x = self.cursor.x - 1
  elseif direction == "right" then
    if not self.pokemonItems[self.cursor.x + 1 .. "-" .. self.cursor.y] then return end
    self.cursor.x = self.cursor.x + 1
  end

  -- Clamp cursor position
  self.cursor.x = math.max(1, math.min(self.cursor.x, self.gridColumns))
  self.cursor.y = math.max(1, math.min(self.cursor.y, self.gridRows))

  self:updateSelectedPokemon()
end

function selectionScreen:keypressed(key)
  if keys.isAnyOf(key, {"up", "down", "left", "right"}) then
    self:changecursor(key)
  end
end

return selectionScreen
