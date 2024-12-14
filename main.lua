local selectionScreen = require 'selection-screen'

function love.load()
  selectionScreen:load("pokemon/")
end

function love.update(dt)

end

function love.draw()
  selectionScreen:draw()
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end
