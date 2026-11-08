local flux = require 'lib.flux'
local timerManager = require 'timer-manager'
local pokemonField = require 'pokemon-field'

local ANGRY_DURATION = 2
local APPROACH_TIME = 2.2
local MEET_GAP = 8
local RAYQUAZA_DESCEND_TIME = 0.35
local SEPARATE_TIME = 0.35
local RAYQUAZA_LEAVE_TIME = 0.5

local taoTrioCutscene = {
  active = false,
  playedThisMatch = false,
  rayquaza = nil,
  rayquazaPos = { x = 0, y = 0 },
  rayquazaVisible = false,
  trembleActive = false,
  trembleTimerId = nil,
}

local function stopTremble()
  taoTrioCutscene.trembleActive = false
  pokemonField:clearTweens()
  local p1 = pokemonField.positions.player1
  local p2 = pokemonField.positions.player2
  p1.y = pokemonField.basePositions.player1.y
  p2.y = pokemonField.basePositions.player2.y
end

local function trembleStep(pos, baseY)
  if not taoTrioCutscene.trembleActive or not taoTrioCutscene.active then
    pos.y = baseY
    return
  end
  flux.to(pos, 0.045, { y = baseY - 4 }):ease("sineinout"):oncomplete(function()
    if not taoTrioCutscene.trembleActive then
      pos.y = baseY
      return
    end
    flux.to(pos, 0.045, { y = baseY + 4 }):ease("sineinout"):oncomplete(function()
      trembleStep(pos, baseY)
    end)
  end)
end

local function startTremble()
  taoTrioCutscene.trembleActive = true
  local p1 = pokemonField.positions.player1
  local p2 = pokemonField.positions.player2
  local b1 = pokemonField.basePositions.player1.y
  local b2 = pokemonField.basePositions.player2.y
  trembleStep(p1, b1)
  trembleStep(p2, b2)
end

local function loadRayquaza(pokemonItems)
  local mon = pokemonField:getPokemonByName("rayquaza", pokemonItems)
  if mon then
    return mon
  end
  local path = "pokemon/rayquaza_dragon_14,30.png"
  if love.filesystem.getInfo(path) then
    local image = love.graphics.newImage(path)
    return {
      name = "rayquaza",
      image = image,
      facePosition = { x = 14, y = 30 },
    }
  end
end

function taoTrioCutscene:init(pokemonItems, pingPongManager)
  self.rayquaza = loadRayquaza(pokemonItems)
  self.pingPongManager = pingPongManager
end

function taoTrioCutscene:resetMatch()
  self.active = false
  self.playedThisMatch = false
  self.rayquazaVisible = false
  if self.pingPongManager then
    self.pingPongManager.cutsceneFrozen = false
  end
  stopTremble()
  if self.trembleTimerId then
    timerManager:cancel(self.trembleTimerId)
    self.trembleTimerId = nil
  end
end

function taoTrioCutscene:isActive()
  return self.active
end

local function isTiedWithAtLeastOneGoalEach(scoreManager)
  local p1Bars = scoreManager:getPlayerScore("player1")
  local p2Bars = scoreManager:getPlayerScore("player2")
  if p1Bars ~= p2Bars then
    return false
  end
  local p1Goals = scoreManager.maxScore - p1Bars
  local p2Goals = scoreManager.maxScore - p2Bars
  return p1Goals >= 1 and p2Goals >= 1
end

function taoTrioCutscene:shouldTrigger(selectionScreen, scoreManager)
  if self.playedThisMatch or self.active then
    return false
  end
  if not isTiedWithAtLeastOneGoalEach(scoreManager) then
    return false
  end
  local p1 = selectionScreen.selectedPokemon["player1"]
  local p2 = selectionScreen.selectedPokemon["player2"]
  if not p1 or not p2 or not p1.name or not p2.name then
    return false
  end
  local hasReshiram, hasZekrom = false, false
  for _, name in ipairs({ string.lower(p1.name), string.lower(p2.name) }) do
    if name == "reshiram" then
      hasReshiram = true
    elseif name == "zekrom" then
      hasZekrom = true
    end
  end
  return hasReshiram and hasZekrom
end

function taoTrioCutscene:draw()
  if not self.rayquazaVisible or not self.rayquaza then
    return
  end
  love.graphics.setColor(colors.white)
  love.graphics.draw(
    self.rayquaza.image,
    self.rayquazaPos.x,
    self.rayquazaPos.y,
    0,
    1,
    1,
    self.rayquaza.facePosition.x,
    self.rayquaza.facePosition.y
  )
end

function taoTrioCutscene:start(pingPongManager, onComplete)
  if not self.rayquaza or self.active then
    return false
  end

  self.active = true
  self.playedThisMatch = true
  self.rayquazaVisible = false
  pingPongManager.cutsceneFrozen = true

  pokemonField:clearTweens()

  local p1 = pokemonField.positions.player1
  local p2 = pokemonField.positions.player2
  local meetX = canvasWidth / 2
  local p1TargetX = meetX - MEET_GAP
  local p2TargetX = meetX + MEET_GAP

  startTremble()

  local function approachEachOther()
    stopTremble()
    flux.to(p1, APPROACH_TIME, { x = p1TargetX }):ease("quadinout")
    flux.to(p2, APPROACH_TIME, { x = p2TargetX }):ease("quadinout"):oncomplete(function()
      self.rayquazaVisible = true
      self.rayquazaPos.x = meetX
      self.rayquazaPos.y = -self.rayquaza.image:getHeight()

      flux.to(self.rayquazaPos, RAYQUAZA_DESCEND_TIME, { y = canvasHeight / 2 }):ease("backout"):oncomplete(function()
        local base1 = pokemonField.basePositions.player1
        local base2 = pokemonField.basePositions.player2
        flux.to(p1, SEPARATE_TIME, { x = base1.x }):ease("quadout")
        flux.to(p2, SEPARATE_TIME, { x = base2.x }):ease("quadout"):oncomplete(function()
          flux.to(self.rayquazaPos, RAYQUAZA_LEAVE_TIME, { y = -self.rayquaza.image:getHeight() }):ease("backin"):oncomplete(function()
            self.rayquazaVisible = false
            self.active = false
            pingPongManager.cutsceneFrozen = false
            p1.y = base1.y
            p2.y = base2.y
            if onComplete then
              onComplete()
            end
          end)
        end)
      end)
    end)
  end

  self.trembleTimerId = timerManager:after(ANGRY_DURATION, function()
    self.trembleTimerId = nil
    if self.active then
      approachEachOther()
    end
  end)
  return true
end

return taoTrioCutscene
