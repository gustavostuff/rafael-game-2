local soundManager = {}

function soundManager:init()
  love.audio.setVolume(1)
  self.bgMusic = love.audio.newSource('bg-music.ogg', 'stream')
  self.bgMusic:setVolume(0.5)
  self.bgMusic:setLooping(true)
  self.bgMusic:play()
  self.scoreSound = love.audio.newSource('sounds/score.wav', 'static')
  self.paddleBounceSound = love.audio.newSource('sounds/pokeball_bounce.wav', 'static')
end

local function playOnce(source)
  if source then
    source:stop()
    source:play()
  end
end

function soundManager:playScore()
  playOnce(self.scoreSound)
end

function soundManager:playPaddleBounce()
  playOnce(self.paddleBounceSound)
end

return soundManager
