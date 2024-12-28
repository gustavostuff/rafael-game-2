-- pokemonGrid.lua

local pokemonGrid = {
  gridRows = 4,
  gridColumns = 4,
  gridCellSize = 20,
  cellMargin = 8,
  cursorP1 = { x = 1, y = 1 },
  cursorP2 = { x = 1, y = 1 },
  verticalViewport = { y0 = 1, y1 = 4 },
  pokemonItems = {},
  debug = false
}

local function getNumbersFromStringCoords(c)
  local p = split(c, ",")
  return {
    x = tonumber(p[1]),
    y = tonumber(p[2])
  }
end

local function getPokemonData(f)
  local s = f:sub(1, #f - 4)
  local parts = split(s, "_")
  return {
    name = parts[1],
    type = parts[2],
    facePosition = getNumbersFromStringCoords(parts[3])
  }
end

function pokemonGrid:init(d)
  local fl = love.filesystem.getDirectoryItems(d)
  self.gridRows = math.ceil(#fl / self.gridColumns)
  local i = 1
  for r = 1, self.gridRows do
    for c = 1, self.gridColumns do
      if i > #fl then break end
      local fn = fl[i]
      local pd = getPokemonData(fn)
      local img = love.graphics.newImage(d .. fn)
      self.pokemonItems[c .. "-" .. r] = {
        name = pd.name,
        type = pd.type,
        image = img,
        gridX = c,
        gridY = r,
        facePosition = pd.facePosition,
        imageWidth = img:getWidth(),
        imageHeight = img:getHeight()
      }
      i = i + 1
    end
  end
  self.cellOffset = self.gridCellSize + self.cellMargin
  self.selectionGridWidth = self.gridColumns * self.cellOffset
  self.selectionGridHeight = self.gridRows * self.cellOffset
  self.selectionGridX = 20
  self.selectionGridY = 20
end

local function getCellCoordinates(s, gx, gy)
  local zx = gx - 1
  local zy = gy - s.verticalViewport.y0
  local x = s.selectionGridX + zx * s.cellOffset
  local y = s.selectionGridY + zy * s.cellOffset
  return x, y
end

function pokemonGrid:isInsideViewport(p)
  return p.gridY >= self.verticalViewport.y0 and p.gridY <= self.verticalViewport.y1
end

function pokemonGrid:drawGrid()
  for _, v in pairs(self.pokemonItems) do
    if self:isInsideViewport(v) then
      local cx, cy = getCellCoordinates(self, v.gridX, v.gridY)
      if (self.cursorP1.x == v.gridX and self.cursorP1.y == v.gridY)
         or (self.cursorP2.x == v.gridX and self.cursorP2.y == v.gridY) then
        love.graphics.setColor(colors.yellow)
        love.graphics.rectangle("fill", cx - 3, cy - 3, self.gridCellSize + 6, self.gridCellSize + 6, 4)
      end
      love.graphics.stencil(function()
        love.graphics.rectangle("fill", cx, cy, self.gridCellSize, self.gridCellSize, 2)
      end, "replace", 1)
      love.graphics.setStencilTest("greater", 0)
      love.graphics.setColor(colors.gray)
      love.graphics.rectangle("fill", cx, cy, self.gridCellSize, self.gridCellSize)
      love.graphics.setColor(colors.white)
      love.graphics.draw(
        v.image,
        math.floor(cx + self.gridCellSize / 2),
        math.floor(cy + self.gridCellSize / 2),
        0,
        1,
        1,
        math.floor(v.facePosition.x),
        math.floor(v.facePosition.y)
      )
      love.graphics.setStencilTest()
    end
  end
end

function pokemonGrid:drawDebugInfo()
  if not self.debug then return end
  love.graphics.setColor(colors.darkRed)
  for r = 1, self.gridRows do
    for c = 1, self.gridColumns do
      local x, y = getCellCoordinates(self, c, r)
      love.graphics.rectangle("line", x, y, self.gridCellSize, self.gridCellSize)
    end
  end
  love.graphics.setColor(colors.white)
end

function pokemonGrid:isGoingDownToEmptyCell(c, d)
  if d ~= "down" then return false end
  if c.y == self.gridRows - 1 and self.pokemonItems[c.x .. "-" .. (c.y + 1)] == nil then
    return true
  end
end

function pokemonGrid:getEmptyCellsCount()
  return (self.gridRows * self.gridColumns) % tableLength(self.pokemonItems)
end

function pokemonGrid:movingRightToEmptyCell(c, d)
  local x, y = c.x, c.y
  return (self:getEmptyCellsCount() > 0)
     and y == self.gridRows
     and d == "right"
     and not self.pokemonItems[(x + 1) .. "-" .. y]
end

function pokemonGrid:changecursor(player, d)
  if d == "w" then d = "up"
  elseif d == "s" then d = "down"
  elseif d == "a" then d = "left"
  elseif d == "d" then d = "right"
  end
  local c = (player == "p2") and self.cursorP2 or self.cursorP1
  local x, y = c.x, c.y
  if d == "up" then y = y - 1
  elseif d == "down" then y = y + 1
  elseif d == "left" then x = x - 1
  elseif d == "right" then x = x + 1
  end
  if self:isGoingDownToEmptyCell(c, d) then
    c.x = self.gridColumns - self:getEmptyCellsCount()
    c.y = self.gridRows
    return
  end
  if self:movingRightToEmptyCell(c, d) then
    c.x = x
    c.y = y - 1
    return
  end
  if self.pokemonItems[x .. "-" .. y] then
    c.x = math.max(1, math.min(x, self.gridColumns))
    c.y = math.max(1, math.min(y, self.gridRows))
  end
end


function pokemonGrid:getSelectedPokemon(player)
  local c = player == "p2" and self.cursorP2 or self.cursorP1
  return self.pokemonItems[c.x .. "-" .. c.y]
end

function pokemonGrid:updateViewport(player)
  local c = player == "p2" and self.cursorP2 or self.cursorP1
  local cy = c.y
  if cy > self.verticalViewport.y1 then
    self.verticalViewport.y0 = self.verticalViewport.y0 + 1
    self.verticalViewport.y1 = self.verticalViewport.y1 + 1
  end
  if cy < self.verticalViewport.y0 then
    self.verticalViewport.y0 = self.verticalViewport.y0 - 1
    self.verticalViewport.y1 = self.verticalViewport.y1 - 1
  end
end

return pokemonGrid
