local resolutionManager = require 'resolution-manager'

local selectionScreen = {
  pokemonItems = {},
  gridRows      = 4,
  gridColumns   = 4,
  gridCellSize  = 20,
  cellMargin    = 8,
  cursor        = {x = 1, y = 1},
  selectedPokemon = nil,
  verticalViewport = {
    y0 = 1,
    y1 = 4
  },
  -- debug = true
}

local function getNumbersFromStringCoords(coords)
  local parts = split(coords, ",")
  return { x = tonumber(parts[1]), y = tonumber(parts[2]) }
end

local function getPokemonData(pokemonFile)
  local fileWithoutExt = pokemonFile:sub(1, #pokemonFile - 4)
  local parts          = split(fileWithoutExt, "_")
  local facePosition   = getNumbersFromStringCoords(parts[3])
  return parts[1], parts[2], facePosition  -- name, type, facePosition
end

local function getPokemonColor(pokemonType)
  if     pokemonType == "fire"    then return colors.darkRed
  elseif pokemonType == "water"   then return colors.skyBlue
  elseif pokemonType == "grass"   then return colors.darkGreen
  elseif pokemonType == "electric"then return colors.mustard
  elseif pokemonType == "dragon"  then return colors.dragon
  elseif pokemonType == "steel"   then return colors.steelBlue
  elseif pokemonType == "ice"     then return colors.iceBlue
  elseif pokemonType == "ghost"   then return colors.purple
  else                                 return colors.white
  end
end

function selectionScreen:init(pokemonDirectory)
  local fileList  = love.filesystem.getDirectoryItems(pokemonDirectory)
  self.gridRows   = math.ceil(#fileList / self.gridColumns)
  local index     = 1

  -- Populate self.pokemonItems
  for row = 1, self.gridRows do
    for col = 1, self.gridColumns do
      if index > #fileList then break end
      local name, pType, facePosition = getPokemonData(fileList[index])
      local image = love.graphics.newImage(pokemonDirectory .. fileList[index])
      self.pokemonItems[col .. "-" .. row] = {
        name     = name,
        type     = pType,
        image    = image,
        gridX    = col,
        gridY    = row,
        facePosition = facePosition,
        imageWidth  = image:getWidth(),
        imageHeight = image:getHeight(),
      }
      index = index + 1
    end
  end

  -- Precompute grid layout
  self.cellOffset          = self.gridCellSize + self.cellMargin
  self.selectionGridWidth  = self.gridColumns * self.cellOffset
  self.selectionGridHeight = self.gridRows    * self.cellOffset
  self.selectionGridX      = 20
  self.selectionGridY      = 20

  -- Precompute card geometry
  self.cardWidth    = 120
  self.cardHeight   = 140
  self.cornerRadius = 4
  self.cardPadding  = 10

  -- Card position
  self.cardX = canvasWidth * 0.75 - self.cardWidth  / 2
  self.cardY = canvasHeight * 0.5 - self.cardHeight / 2

  -- Inner rectangle (static for all Pokemon)
  self.innerRectX = self.cardX + self.cardPadding
  self.innerRectY = self.cardY + self.cardPadding
  self.innerRectW = self.cardWidth  - self.cardPadding * 2
  self.innerRectH = (self.cardHeight * 0.7) - self.cardPadding * 2

  -- Draw pokemon inside card
  self.pokemonX = math.floor(self.cardX + self.cardWidth  / 2)
  self.pokemonY = math.floor(self.cardY + self.cardHeight * 0.35)

  -- Text positions (static offsets within the card)
  local nameYBase = self.cardY + self.cardPadding + (self.cardHeight * 0.7) - font:getHeight() * 1.2
  self.nameX = math.floor(self.cardX + self.cardPadding)
  self.nameY = math.floor(nameYBase)
  self.typeY = math.floor(self.nameY + font:getHeight() * 1.4)

  self:updateSelectedPokemon()
end

function selectionScreen:updateSelectedPokemon()
  self.selectedPokemon = self.pokemonItems[self.cursor.x .. "-" .. self.cursor.y]
  -- Only dynamic properties: color and “display strings”
  if self.selectedPokemon then
    self.cardColor   = getPokemonColor(self.selectedPokemon.type)
    self.displayName = "Name: " .. toCapitalCase(self.selectedPokemon.name)
    self.displayType = "Type: " .. toCapitalCase(self.selectedPokemon.type)
  else
    self.cardColor   = colors.white
    self.displayName = nil
    self.displayType = nil
  end

  -- Update viewport
  if self.cursor.y > self.verticalViewport.y1 then
    self.verticalViewport.y0 = self.verticalViewport.y0 + 1
    self.verticalViewport.y1 = self.verticalViewport.y1 + 1
  end

  if self.cursor.y < self.verticalViewport.y0 then
    self.verticalViewport.y0 = self.verticalViewport.y0 - 1
    self.verticalViewport.y1 = self.verticalViewport.y1 - 1
  end
end

local function getCellCoordinates(self, gridX, gridY)
  local zeroBasedX = gridX - 1
  local zeroBasedY = gridY - (self.verticalViewport.y0)
  local x = self.selectionGridX + (zeroBasedX) * self.cellOffset
  local y = self.selectionGridY + (zeroBasedY) * self.cellOffset
  return x, y
end

function selectionScreen:isInsideViewport(pokemon)
  return pokemon.gridY >= self.verticalViewport.y0 and pokemon.gridY <= self.verticalViewport.y1
end

function selectionScreen:drawPokemonGrid()
  for _, pokemon in pairs(self.pokemonItems) do
    if self:isInsideViewport(pokemon) then
      local cellX, cellY = getCellCoordinates(self, pokemon.gridX, pokemon.gridY)
      
      -- Highlight current cursor cell
      if self.cursor.x == pokemon.gridX and self.cursor.y == pokemon.gridY then
        love.graphics.setColor(colors.mustard)
        love.graphics.rectangle("fill",
          cellX - 3, cellY - 3,
          self.gridCellSize + 6,
          self.gridCellSize + 6,
          4
        )
      end
  
      -- Clip to cell
      love.graphics.stencil(function()
        love.graphics.rectangle("fill", cellX, cellY, self.gridCellSize, self.gridCellSize, 2)
      end, "replace", 1)
      love.graphics.setStencilTest("greater", 0)
  
      -- Cell background
      love.graphics.setColor(colors.gray)
      love.graphics.rectangle("fill", cellX, cellY, self.gridCellSize, self.gridCellSize)
      love.graphics.setColor(colors.white)
  
      -- Draw face
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
end

function selectionScreen:drawDebugInfo()
  if self.debug then
    love.graphics.setColor(colors.darkRed)
    for row = 1, self.gridRows do
      for col = 1, self.gridColumns do
        local x, y = getCellCoordinates(self, col, row)
        love.graphics.rectangle("line", x, y, self.gridCellSize, self.gridCellSize)
      end
    end
    love.graphics.setColor(colors.white)
  end
end

function selectionScreen:drawPokemonCard()
  if not self.selectedPokemon then return end

  -- Card background
  love.graphics.setColor(self.cardColor)
  love.graphics.rectangle('fill', self.cardX, self.cardY, self.cardWidth, self.cardHeight, self.cornerRadius)

  -- Inner rectangle
  love.graphics.setColor(colorWithAlpha('black', 0.5))
  love.graphics.rectangle('fill', self.innerRectX, self.innerRectY, self.innerRectW, self.innerRectH)

  -- Draw Pokemon
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

  -- Draw Text
  prettyPrint(self.displayName, self.nameX, self.nameY, {
    cell   = true,
    color  = colors.almostWhite,
    bgColor= colors.dark
  })
  prettyPrint(self.displayType, self.nameX, self.typeY, {
    cell   = true,
    color  = colors.almostWhite,
    bgColor= colors.dark
  })
end

function selectionScreen:draw()
  love.graphics.setColor(colors.white)
  self:drawPokemonGrid()
  self:drawPokemonCard()
  self:drawDebugInfo()
end

function selectionScreen:changecursor(direction)
  local x, y = self.cursor.x, self.cursor.y
  if     direction == "up"    then y = y - 1
  elseif direction == "down"  then y = y + 1
  elseif direction == "left"  then x = x - 1
  elseif direction == "right" then x = x + 1
  end

  -- If new position is valid, update cursor
  if self.pokemonItems[x .. "-" .. y] then
    self.cursor.x = math.max(1, math.min(x, self.gridColumns))
    self.cursor.y = math.max(1, math.min(y, self.gridRows))
    self:updateSelectedPokemon()
  end
end

function selectionScreen:keypressed(key)
  if keys.isAnyOf(key, {"up", "down", "left", "right"}) then
    self:changecursor(key)
  end
end

return selectionScreen
