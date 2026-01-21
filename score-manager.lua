local scoreManager = {}

function scoreManager:init(options)
  options = options or {}
  self.maxScore = options.maxScore or 11
  self.barWidth = options.barWidth or 3
  self.barGap = options.barGap or 1
  self.barHeight = options.barHeight or 4

  self:resetScores()
end

function scoreManager:resetScores()
  self.player1 = self.maxScore
  self.player2 = self.maxScore
end

function scoreManager:increasePlayerScore(player)
  if not self[player] then
    self[player] = 0
  end

  self[player] = self[player] + 1
end

function scoreManager:decreasePlayerScore(player)
  if not self[player] then
    self[player] = self.maxScore
  end

  self[player] = math.max(0, self[player] - 1)
end

function scoreManager:getPlayerScore(player)
  return self[player] or 0
end

local function drawBars(x, y, count, maxCount, barWidth, barHeight, barGap)
  if count <= 0 then return end

  local clamped = math.min(count, maxCount)
  for i = 0, clamped - 1 do
    local bx = x + i * (barWidth + barGap)
    love.graphics.rectangle("fill", bx, y, barWidth, barHeight)
  end
end

function scoreManager:draw()
  local p1Score = self:getPlayerScore('player1')
  local p2Score = self:getPlayerScore('player2')
  local barY = canvasHeight - 7

  love.graphics.setColor(colors.yellow)
  drawBars(5, barY, p1Score, self.maxScore, self.barWidth, self.barHeight, self.barGap)

  local rightStart = canvasWidth - 5 - (self.maxScore * self.barWidth) - ((self.maxScore - 1) * self.barGap)
  drawBars(rightStart, barY, p2Score, self.maxScore, self.barWidth, self.barHeight, self.barGap)
end

return scoreManager
