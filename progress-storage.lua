local unlockOrder = require 'unlock-order'

local FILENAME = 'player_progress.lua'

local STARTERS = {
  charmander = true,
  squirtle = true,
  bulbasaur = true,
}

local progressStorage = {
  data = nil,
}

local function defaultData()
  return {
    victories = { player1 = 0, player2 = 0 },
  }
end

local function mergeDefaults(raw)
  local d = defaultData()
  if type(raw) ~= 'table' then return d end
  if type(raw.victories) == 'table' then
    d.victories.player1 = tonumber(raw.victories.player1) or 0
    d.victories.player2 = tonumber(raw.victories.player2) or 0
  end
  return d
end

function progressStorage:load()
  if love.filesystem.getInfo(FILENAME) then
    local chunk, err = love.filesystem.load(FILENAME)
    if chunk then
      local ok, data = pcall(chunk)
      if ok then
        self.data = mergeDefaults(data)
        return
      end
    end
  end
  self.data = defaultData()
end

function progressStorage:save()
  local v = self.data.victories
  local body = string.format(
    'return {\n  victories = { player1 = %d, player2 = %d },\n}\n',
    v.player1 or 0,
    v.player2 or 0
  )
  love.filesystem.write(FILENAME, body)
end

function progressStorage:extraUnlockedCount()
  local total = (self.data.victories.player1 or 0) + (self.data.victories.player2 or 0)
  local n = math.floor(total / 3)
  if n > #unlockOrder then
    n = #unlockOrder
  end
  return n
end

function progressStorage:isPokemonUnlocked(name)
  if TESTING_MODE then
    return true
  end

  local n = string.lower(name)
  if STARTERS[n] then
    return true
  end
  local maxExtra = self:extraUnlockedCount()
  for i = 1, maxExtra do
    if string.lower(unlockOrder[i]) == n then
      return true
    end
  end
  return false
end

function progressStorage:nameJustUnlocked(prevExtraUnlocked)
  local newExtra = self:extraUnlockedCount()
  if newExtra > prevExtraUnlocked then
    return unlockOrder[newExtra]
  end
  return nil
end

function progressStorage:clearVictories()
  self.data.victories.player1 = 0
  self.data.victories.player2 = 0
  self:save()
end

function progressStorage:applyLocks(pokemonItems)
  for _, pokemon in pairs(pokemonItems) do
    pokemon.locked = not self:isPokemonUnlocked(pokemon.name)
  end
end

function progressStorage:recordVictory(winnerKey)
  self.data.victories[winnerKey] = (self.data.victories[winnerKey] or 0) + 1
end

return progressStorage
