local scoreManager = {}

function scoreManager:init()
  self.score = 0
end

function scoreManager:increasePlayerScore(player)
  if not self[player] then
    self[player] = 0
  end

  self[player] = self[player] + 1
end

function scoreManager:getPlayerScore(player)
  return self[player] or 0
end

function scoreManager:draw()
  local p1Score = 'P1: ' .. self:getPlayerScore('player1')
  local p2Score = 'P2: ' .. self:getPlayerScore('player2')

  love.graphics.setColor(colors.white)
  love.graphics.print(p1Score, 10, 10)
  love.graphics.print(p2Score, canvasWidth - 10 - font:getWidth(p2Score), 10)
end

return scoreManager
