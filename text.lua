local cellMapping = {
  {-1,  0},
  { 1,  0},
  { 0, -1},
  { 0,  1},
  {-1, -1},
  {-1,  1},
  { 1, -1},
  { 1,  1}
}

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

prettyPrint = function (text, x, y, data)
  data = data or {}
  local font = love.graphics.getFont()
  if not x then x = 10 end
  if not y then y = 10 end
  
  local color = data.color or colors.white
  local bgColor = data.bgColor or colors.black
  local textLines
  if type(text) == 'table' then -- text is already in table format
    textLines = text
  else
    textLines = split(text, '\n')
  end

  local lineHeight = math.floor(font:getHeight() * lineHeight)
  local rectangleHeight = lineHeight * #textLines
  for i = 1, #textLines do
    local line = textLines[i]

    if data.centered then
      x = (data.vpw or canvasW) / 2 - font:getWidth(line) / 2
      y = ((data.vph or canvasH) / 2 - rectangleHeight / 2)
    end

    if data.bottom then
      y = ((data.vph or canvasH) - (rectangleHeight + lineHeight))
    end

    if data.forcedX then
      x = data.forcedX
    end

    if data.forcedY then
      y = data.forcedY
    end
  
    -- shadow effect
    love.graphics.setColor(bgColor)
    love.graphics.print(line,
      math.floor(x - (data.shadowDisp or 1)),
      math.floor(y + (data.shadowDisp or 1)) + ((i - 1) * lineHeight)
    )

    if data.cell then
      local eightDirectionOffsets = {
        {-1, -1},
        { 0, -1},
        { 1, -1},
        {-1,  0},
        { 1,  0},
        {-1,  1},
        { 0,  1},
        { 1,  1},
      }
      for _, coord in ipairs(eightDirectionOffsets) do
        love.graphics.print(line,
          math.floor(x + coord[1]),
          math.floor(y + coord[2]) + ((i - 1) * lineHeight)
        )
      end
    end
  
    love.graphics.setColor(color)
    love.graphics.print(line, math.floor(x), math.floor(y) + ((i - 1) * lineHeight))
  end
end
