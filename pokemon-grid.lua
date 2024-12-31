-- pokemonGrid.lua
local pokemonGrid = {
  gridRows      = 4,
  gridColumns   = 5,
  gridPadding   = 5,
  gridCellSize  = 20,
  cellMargin    = 8,
  cursor        = { x = 1, y = 1 },
  verticalViewport = { y0 = 1, y1 = 4 },
  pokemonItems  = {},   -- Will hold all Pokémon loaded
  debug         = false, -- Optionally toggle debug
  currentPlayer = 1,
}

local function getNumbersFromStringCoords(coords)
  local parts = split(coords, ",")
  return { x = tonumber(parts[1]), y = tonumber(parts[2]) }
end

local function getPokemonData(pokemonFile)
  local fileWithoutExt = pokemonFile:sub(1, #pokemonFile - 4)
  local parts          = split(fileWithoutExt, "_")
  return {
    name         = parts[1],
    type         = parts[2],
    facePosition = getNumbersFromStringCoords(parts[3])
  }
end

-- Used by selectionScreen to init the grid
function pokemonGrid:init(pokemonDirectory)
  -- Load the list of files in the directory
  local fileList      = love.filesystem.getDirectoryItems(pokemonDirectory)
  self.gridRows       = math.ceil(#fileList / self.gridColumns)
  local index         = 1

  -- Load each Pokémon
  for row = 1, self.gridRows do
    for col = 1, self.gridColumns do
      if index > #fileList then break end

      local fileName = fileList[index]
      local pData    = getPokemonData(fileName)
      local image    = love.graphics.newImage(pokemonDirectory .. fileName)

      self.pokemonItems[col .. "-" .. row] = {
        name         = pData.name,
        type         = pData.type,
        image        = image,
        gridX        = col,
        gridY        = row,
        facePosition = pData.facePosition,
        imageWidth   = image:getWidth(),
        imageHeight  = image:getHeight()
      }
      index = index + 1
    end
  end

  -- Precompute total grid size and origin
  self.cellOffset          = self.gridCellSize + self.cellMargin
  self.selectionGridWidth  = self.gridColumns * self.cellOffset
  self.selectionGridHeight = self.gridRows    * self.cellOffset
  self.selectionGridX      = 20
  self.selectionGridY      = 21
end

-- Helper: convert from (gridX, gridY) to actual screen position
local function getCellCoordinates(self, gridX, gridY)
  local zeroBasedX = gridX - 1
  local zeroBasedY = gridY - self.verticalViewport.y0
  local x = self.selectionGridX + zeroBasedX * self.cellOffset
  local y = self.selectionGridY + zeroBasedY * self.cellOffset
  return x, y
end

function pokemonGrid:isInsideViewport(pokemon)
  return pokemon.gridY >= self.verticalViewport.y0
     and pokemon.gridY <= self.verticalViewport.y1
end

-- Draw the grid and highlight the cursor
function pokemonGrid:drawGrid()
  -- love.graphics.setColor(colorWithAlpha("black", 0.5))
  -- love.graphics.rectangle("fill",
  --   self.selectionGridX - self.gridPadding - 2,
  --   self.selectionGridY - self.gridPadding - 2,
  --   self.selectionGridWidth + 5,
  --   152,
  --   4
  -- )
  for _, pokemon in pairs(self.pokemonItems) do
    if self:isInsideViewport(pokemon) then
      local cellX, cellY = getCellCoordinates(self, pokemon.gridX, pokemon.gridY)

      -- Highlight current cursor cell
      if self.cursor.x == pokemon.gridX and self.cursor.y == pokemon.gridY then
        love.graphics.setColor(colors.yellow)
        love.graphics.rectangle("fill", cellX - 3, cellY - 3,
                                self.gridCellSize + 6,
                                self.gridCellSize + 6,
                                4)
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

  love.graphics.setColor(colors.white)
  love.graphics.print('Player ' .. self.currentPlayer ..' selection', 20, 5)
end

-- Show helpful debug rectangles
function pokemonGrid:drawDebugInfo()
  if not self.debug then return end
  love.graphics.setColor(colors.darkRed)
  for row = 1, self.gridRows do
    for col = 1, self.gridColumns do
      local x, y = getCellCoordinates(self, col, row)
      love.graphics.rectangle("line", x, y, self.gridCellSize, self.gridCellSize)
    end
  end
  love.graphics.setColor(colors.white)
end

function pokemonGrid:isGoingDownToEmptyCell(direction)
  if direction ~= "down" then return false end

  local y = self.cursor.y
  if y == self.gridRows - 1 and self.pokemonItems[self.cursor.x .. "-" .. y + 1] == nil then
    return true
  end
end

function pokemonGrid:getEmptyCellsCount()
  return (self.gridRows * self.gridColumns) % tableLength(self.pokemonItems)
end


function pokemonGrid:movingRightToEmptyCell(direction)
  local x, y = self.cursor.x, self.cursor.y

  return (self:getEmptyCellsCount(direction) > 0) and
    y == self.gridRows and
    direction == 'right' and
    self.pokemonItems[(x + 1) .. "-" .. y] == nil
end

-- Move the cursor up/down/left/right
function pokemonGrid:changecursor(direction)
  local x, y = self.cursor.x, self.cursor.y
  if     direction == "up"    then y = y - 1
  elseif direction == "down"  then y = y + 1
  elseif direction == "left"  then x = x - 1
  elseif direction == "right" then x = x + 1
  end

  -- handle last row what may contain empty cells
  if self:isGoingDownToEmptyCell(direction) then
    -- select the last item in the list
    self.cursor = {
      x = self.gridColumns - self:getEmptyCellsCount(),
      y = self.gridRows
    }
    return
  end

  -- handle moving right from the last item (when there are empty cells)
  if self:movingRightToEmptyCell(direction) then
    self.cursor = {
      x = x,
      y = y - 1
    }
    return
  end

  -- If new position is valid, update cursor
  if self.pokemonItems[x .. "-" .. y] then
    self.cursor.x = math.max(1, math.min(x, self.gridColumns))
    self.cursor.y = math.max(1, math.min(y, self.gridRows))
  end
end

-- For simple “selected Pokémon” flow:
-- Let external code call this once the cursor changes
function pokemonGrid:getSelectedPokemon()
  return self.pokemonItems[self.cursor.x .. "-" .. self.cursor.y]
end

function pokemonGrid:setSelectedPokemon(x, y)
  self.cursor.x = x
  self.cursor.y = y
end

-- For viewport scrolling
function pokemonGrid:updateViewport()
  local cy = self.cursor.y
  -- Scroll down if cursor goes below y1
  if cy > self.verticalViewport.y1 then
    self.verticalViewport.y0 = self.verticalViewport.y0 + 1
    self.verticalViewport.y1 = self.verticalViewport.y1 + 1
  end
  -- Scroll up if cursor goes above y0
  if cy < self.verticalViewport.y0 then
    self.verticalViewport.y0 = self.verticalViewport.y0 - 1
    self.verticalViewport.y1 = self.verticalViewport.y1 - 1
  end
end

return pokemonGrid
