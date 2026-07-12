local debugOverlay = {}

function debugOverlay:draw(selectionScreen, resolutionManager)
  if not loveDebug then
    return
  end

  local cursor = selectionScreen.pokemonGrid.cursor
  local viewport = selectionScreen.pokemonGrid.verticalViewport
  local mouse = resolutionManager:getScaledMouse(love.mouse.getPosition())

  local items = {
    'FPS ' .. love.timer.getFPS(),
    'Mouse scaled: ' .. math.floor(mouse.x) .. ', ' .. math.floor(mouse.y),
    'Canvas size: ' .. resolutionManager.canvasWidth .. 'x' .. resolutionManager.canvasHeight,
    'Canvas scale: ' .. resolutionManager.canvasScaleX .. 'x' .. resolutionManager.canvasScaleY,
    'Canvas position: ' .. resolutionManager.canvasX .. 'x' .. resolutionManager.canvasY,
    'Selection rows: ' .. selectionScreen.pokemonGrid.gridRows,
    'Selection columns: ' .. selectionScreen.pokemonGrid.gridColumns,
    'Selection cursor x: ' .. cursor.x .. ' y: ' .. cursor.y,
    'Grid displacement y0: ' .. viewport.y0 .. ' y1: ' .. viewport.y1,
    'Empty cells at the bottom: ' .. selectionScreen.pokemonGrid:getEmptyCellsCount(),
  }

  love.graphics.setFont(bigFont)
  love.graphics.setColor(colorWithAlpha("black", 0.5))
  love.graphics.rectangle("fill", 10, 10, 400, 300)
  prettyPrint(table.concat(items, '\n'), 20, 20, {
    cell = true,
    color = colors.white,
    bgColor = colors.black,
  })
  love.graphics.setFont(font)
end

return debugOverlay
