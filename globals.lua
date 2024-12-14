defaultCanvasScale = 3
canvasWidth = 640
canvasHeight = 360

font = love.graphics.newFont('fonts/proggy-tiny/proggy-tiny.ttf', 16)
-- bigFont = love.graphics.newFont('fonts/proggy-tiny/proggy-tiny.ttf', 32)

-- Generated with ChatGPT based on https://lospec.com/palette-list/dawnbringer-32
colors = {
  black = {love.math.colorFromBytes(0, 0, 0)},
  darkPurple = {love.math.colorFromBytes(34, 32, 52)},
  coolBlue = {love.math.colorFromBytes(69, 127, 229)},
  forestGreen = {love.math.colorFromBytes(102, 147, 147)},
  lightGreen = {love.math.colorFromBytes(127, 180, 108)},

  darkRed = {love.math.colorFromBytes(215, 18, 38)},
  oliveGreen = {love.math.colorFromBytes(217, 150, 96)},
  mustard = {love.math.colorFromBytes(239, 201, 64)},
  teal = {love.math.colorFromBytes(191, 195, 239)},
  slate = {love.math.colorFromBytes(153, 153, 153)},

  jungleGreen = {love.math.colorFromBytes(106, 190, 48)},
  mossGreen = {love.math.colorFromBytes(57, 125, 70)},
  limeGreen = {love.math.colorFromBytes(181, 205, 56)},
  skyBlue = {love.math.colorFromBytes(82, 188, 254)},
  oceanBlue = {love.math.colorFromBytes(92, 159, 255)},

  lightGrey = {love.math.colorFromBytes(205, 219, 220)},
  white = {love.math.colorFromBytes(255, 255, 255)},
  lavender = {love.math.colorFromBytes(155, 136, 183)},
  coral = {love.math.colorFromBytes(105, 178, 48)},
  deepPink = {love.math.colorFromBytes(101, 34, 103)},

  grape = {love.math.colorFromBytes(89, 86, 112)},
  clayRed = {love.math.colorFromBytes(234, 125, 120)},
  brickRed = {love.math.colorFromBytes(210, 47, 118)},
  wine = {love.math.colorFromBytes(216, 119, 123)},
  darkMagenta = {love.math.colorFromBytes(216, 119, 123)},

  darkForest = {love.math.colorFromBytes(137, 151, 116)},
  brown = {love.math.colorFromBytes(168, 96, 48)}
}

function drawColorPalette()
  local index = 1
  for name, value in pairs(colors) do
    love.graphics.setColor(colors.white)
    love.graphics.print(name, 10, 10 + index * 20)

    love.graphics.setColor(value)
    love.graphics.rectangle('fill', 100, 10 + index * 20, 20, 20)

    index = index + 1
  end

  love.graphics.setColor(colors.white)
end

function colorWithAlpha(colorName, alpha)
  local color = colors[colorName]
  return {color[1], color[2], color[3], alpha}
end

function doCirclesCollide(c1, c2)
  local dx = c1.x - c2.x
  local dy = c1.y - c2.y
  local distance = math.sqrt(dx*dx + dy*dy)

  return distance < c1.r + c2.r
end

function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end
