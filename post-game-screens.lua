local postGameScreens = {}

function postGameScreens:drawUnlockReveal(pendingUnlockPokemon)
  love.graphics.setColor(colors.dark)
  love.graphics.rectangle("fill", 0, 0, canvasWidth, canvasHeight)

  love.graphics.setFont(bigFont)
  local title = "New Pokemon!"
  prettyPrint(title,
    (canvasWidth - bigFont:getWidth(title)) / 2,
    16,
    { cell = true, color = colors.yellow, bgColor = colors.black }
  )

  love.graphics.setFont(font)
  local nameLine = toCapitalCase(pendingUnlockPokemon.name) .. "!"
  prettyPrint(nameLine,
    (canvasWidth - font:getWidth(nameLine)) / 2,
    46,
    { cell = true, color = colors.white, bgColor = colors.black }
  )

  love.graphics.setColor(colors.white)
  love.graphics.draw(
    pendingUnlockPokemon.image,
    math.floor(canvasWidth / 2),
    math.floor(canvasHeight / 2 + 10),
    0,
    1,
    1,
    pendingUnlockPokemon.facePosition.x,
    pendingUnlockPokemon.facePosition.y
  )

  local hint = "Press Enter"
  prettyPrint(hint,
    (canvasWidth - font:getWidth(hint)) / 2,
    canvasHeight - 26,
    { cell = true, color = colors.yellow, bgColor = colors.black }
  )
  love.graphics.setFont(font)
end

function postGameScreens:drawGameOver(gameOver)
  love.graphics.setColor(colors.dark)
  love.graphics.rectangle("fill", 0, 0, canvasWidth, canvasHeight)

  local winnerLabel = gameOver.winner == 'player1' and 'P1' or 'P2'
  local loserLabel = gameOver.loser == 'player1' and 'P1' or 'P2'
  local titleLeft = winnerLabel
  local titleRight = " Wins!"
  local subtitleLeft = "Loser: "
  local subtitleMid = loserLabel
  local subtitleRight = "  |  Press Enter to reset"
  local winnerColor = winnerLabel == 'P1' and colors.blue or colors.red
  local loserColor = loserLabel == 'P1' and colors.blue or colors.red

  love.graphics.setFont(bigFont)
  local titleWidth = bigFont:getWidth(titleLeft) + bigFont:getWidth(titleRight)
  local titleX = (canvasWidth - titleWidth) / 2
  local titleY = (canvasHeight - bigFont:getHeight()) / 2 - 16
  prettyPrint(titleLeft, titleX, titleY, {
    cell = true,
    color = winnerColor,
    bgColor = colors.black,
  })
  prettyPrint(titleRight, titleX + bigFont:getWidth(titleLeft), titleY, {
    cell = true,
    color = colors.white,
    bgColor = colors.black,
  })
  love.graphics.setFont(font)
  local subtitleWidth = font:getWidth(subtitleLeft) + font:getWidth(subtitleMid) + font:getWidth(subtitleRight)
  local subtitleX = (canvasWidth - subtitleWidth) / 2
  local subtitleY = (canvasHeight - font:getHeight()) / 2 + 12
  prettyPrint(subtitleLeft, subtitleX, subtitleY, {
    cell = true,
    color = colors.white,
    bgColor = colors.black,
  })
  prettyPrint(subtitleMid, subtitleX + font:getWidth(subtitleLeft), subtitleY, {
    cell = true,
    color = loserColor,
    bgColor = colors.black,
  })
  prettyPrint(
    subtitleRight,
    subtitleX + font:getWidth(subtitleLeft) + font:getWidth(subtitleMid),
    subtitleY,
    {
      cell = true,
      color = colors.yellow,
      bgColor = colors.black,
    }
  )
end

return postGameScreens
