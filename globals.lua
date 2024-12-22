defaultCanvasScale = 1
canvasWidth = 320 * defaultCanvasScale
canvasHeight = 180 * defaultCanvasScale
lineHeight = 1.2

font = love.graphics.newFont('fonts/proggy-tiny/proggy-tiny.ttf', 16)
-- bigFont = love.graphics.newFont('fonts/proggy-tiny/proggy-tiny.ttf', 32)

local function hexToRgb(hex)
  -- Remove the '#' if it exists
  hex = hex:gsub("#", "")

  local r = tonumber(hex:sub(1, 2), 16) / 255
  local g = tonumber(hex:sub(3, 4), 16) / 255
  local b = tonumber(hex:sub(5, 6), 16) / 255

  return {r, g, b}
end

colors = {
  black = hexToRgb("#000000"),
  white = hexToRgb("#FFFFFF"),
  dark = hexToRgb("#222034"),
  almostWhite = hexToRgb("#F0F0F0"),
  green = hexToRgb("#00FF00"),
  darkGreen = hexToRgb("#008000"),
  blue = hexToRgb("#0000FF"),
  darkBlue = hexToRgb("#000080"),
  skyBlue = hexToRgb("#87CEEB"),
  steelBlue = hexToRgb("#88ACD4"),
  iceBlue = hexToRgb("#80eed1"),
  red = hexToRgb("#FF0000"),
  darkRed = hexToRgb("#800000"),
  gray = hexToRgb("#808080"),
  darkGray = hexToRgb("#404040"),
  yellow = hexToRgb("#cfc953"),
  dragon = hexToRgb("#A5A8B5"),
  purple = hexToRgb("#9473b4"),
  pink = hexToRgb("#bd63a2")
}

function tableLength(t, flat)
  if flat then
    return #t
  else
    local count = 0
    for _ in pairs(t) do
      count = count + 1
    end
    return count
  end
end

function toCapitalCase(str)
  return str:gsub("^%l", string.upper)
end

function drawColorPalette()
  local index = 1
  for name, value in pairs(colors) do
    love.graphics.setColor(colors.white)
    love.graphics.print(name, 830, 10 + index * 20)

    love.graphics.setColor(value)
    love.graphics.rectangle('fill', 800, 10 + index * 20, 20, 20)

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
