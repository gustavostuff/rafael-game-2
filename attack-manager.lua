local timerManager = require 'timer-manager'

local attackManager = {
  effect = {
    visible = false,
    player = nil,
    img = nil,
    flipY = false,
    timeoutId = nil,
    oscillateId = nil,
  },
}

local attackImages = {}
local attackSounds = {}

local function getAttackImage(typeName)
  if attackImages[typeName] == nil then
    local path = 'attacks/' .. typeName .. '.png'
    if love.filesystem.getInfo(path) then
      attackImages[typeName] = love.graphics.newImage(path)
    else
      attackImages[typeName] = false
    end
  end
  return attackImages[typeName] or nil
end

local function getAttackSound(typeName)
  if attackSounds[typeName] == nil then
    local path = 'sounds/attacks/' .. typeName .. '.mp3'
    if love.filesystem.getInfo(path) then
      attackSounds[typeName] = love.audio.newSource(path, 'static')
    else
      attackSounds[typeName] = false
    end
  end
  return attackSounds[typeName] or nil
end

function attackManager:trigger(player, selectedPokemon, onDone)
  if not selectedPokemon or not selectedPokemon.type then
    if onDone then
      onDone()
    end
    return
  end

  if self.effect.timeoutId then
    timerManager:cancel(self.effect.timeoutId)
  end
  if self.effect.oscillateId then
    timerManager:cancel(self.effect.oscillateId)
  end

  self.effect.player = player
  self.effect.img = getAttackImage(selectedPokemon.type)
  if not self.effect.img then
    self.effect.player = nil
    self.effect.visible = false
    if onDone then
      onDone()
    end
    return
  end

  self.effect.visible = true
  self.effect.flipY = false

  local attackSound = getAttackSound(selectedPokemon.type)
  if attackSound then
    attackSound:stop()
    attackSound:play()
  end

  self.effect.oscillateId = timerManager:every(0.15, function()
    self.effect.flipY = not self.effect.flipY
  end)

  self.effect.timeoutId = timerManager:after(1, function()
    if self.effect.oscillateId then
      timerManager:cancel(self.effect.oscillateId)
      self.effect.oscillateId = nil
    end
    self.effect.timeoutId = nil
    self.effect.visible = false
    self.effect.player = nil
    self.effect.img = nil
    if onDone then
      onDone()
    end
  end)
end

function attackManager:draw(pokemonPositions)
  local effect = self.effect
  if not effect.visible or not effect.img or not effect.player then
    return
  end

  local faceX = effect.player == 'player1' and pokemonPositions.player1.x or pokemonPositions.player2.x
  local faceY = effect.player == 'player1' and pokemonPositions.player1.y or pokemonPositions.player2.y
  local attackScaleX = effect.player == 'player2' and -1 or 1
  local attackScaleY = effect.flipY and -1 or 1

  love.graphics.draw(
    effect.img,
    math.floor(faceX),
    math.floor(faceY),
    0,
    attackScaleX,
    attackScaleY,
    0,
    math.floor(effect.img:getHeight() / 2)
  )
end

function attackManager:reset()
  if self.effect.timeoutId then
    timerManager:cancel(self.effect.timeoutId)
    self.effect.timeoutId = nil
  end
  if self.effect.oscillateId then
    timerManager:cancel(self.effect.oscillateId)
    self.effect.oscillateId = nil
  end
  self.effect.visible = false
  self.effect.player = nil
  self.effect.img = nil
  self.effect.flipY = false
end

return attackManager
