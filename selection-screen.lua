local selectionScreen = {
  pokemonItems = {},
  gridRows = 3,
  gridColumns = 4,
  gridCellSize = 64,
  cellMargin = 4
}

function getPokemonData(pokemonFile)
  local name = pokemonFile:sub(1, pokemonFile:find("_") - 1)
  local type = pokemonFile:sub(pokemonFile:find("_") + 1, pokemonFile:find(".") - 1)

  return name, type
end

function selectionScreen:load(pokemonDirectory)
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

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(pokemon.image, x, y)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(pokemon.name .. " " .. pokemon.type, x + 4, y + 4)

    rowIndex = rowIndex + 1
  end
end

return selectionScreen
