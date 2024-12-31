-- pokemonCard.lua
local pokemonCard = {
  -- Default geometry
  cardWidth    = 120,
  cardHeight   = 140,
  cornerRadius = 4,
  cardPadding  = 10,

  -- Positions and drawing props
  cardX        = 0,
  cardY        = 0,
  innerRectX   = 0,
  innerRectY   = 0,
  innerRectW   = 0,
  innerRectH   = 0,

  -- Pokémon reference (set externally)
  selectedPokemon = nil,
  cardColor       = colors.white,
  displayName     = nil,
  displayType     = nil
}

local function getPokemonColor(pokemonType)
  if     pokemonType == "fire"     then return colors.darkRed
  elseif pokemonType == "water"    then return colors.skyBlue
  elseif pokemonType == "grass"    then return colors.darkGreen
  elseif pokemonType == "electric" then return colors.yellow
  elseif pokemonType == "dragon"   then return colors.dragon
  elseif pokemonType == "steel"    then return colors.steelBlue
  elseif pokemonType == "ice"      then return colors.iceBlue
  elseif pokemonType == "ghost"    then return colors.purple
  elseif pokemonType == "normal"   then return colors.skin
  elseif pokemonType == "rock"     then return colors.ground
  elseif pokemonType == "psychic"  then return colors.pink
  else                                  return colors.white
  end
end

-- Called once in main screen to set up positions
function pokemonCard:init(canvasWidth, canvasHeight)
  -- Position the card relative to the canvas
  self.cardX = canvasWidth * 0.75 - self.cardWidth  / 2
  self.cardY = canvasHeight * 0.5 - self.cardHeight / 2

  -- Inner rectangle
  self.innerRectX = self.cardX + self.cardPadding
  self.innerRectY = self.cardY + self.cardPadding
  self.innerRectW = self.cardWidth  - self.cardPadding * 2
  self.innerRectH = (self.cardHeight * 0.7) - self.cardPadding * 2

  -- Where to draw Pokémon
  self.pokemonX = math.floor(self.cardX + self.cardWidth  / 2)
  self.pokemonY = math.floor(self.cardY + self.cardHeight * 0.35)

  -- Text positions
  local nameYBase  = self.cardY + self.cardPadding
                   + (self.cardHeight * 0.7)
                   - font:getHeight() * 1.2

  self.nameX = math.floor(self.cardX + self.cardPadding)
  self.nameY = math.floor(nameYBase)
  self.typeY = math.floor(self.nameY + font:getHeight() * 1.4)
end

-- Called by external code whenever the selected Pokémon changes
function pokemonCard:setPokemon(pokemon)
  self.selectedPokemon = pokemon

  if pokemon then
    self.cardColor   = getPokemonColor(pokemon.type)
    self.displayName = "Name: " .. toCapitalCase(pokemon.name)
    self.displayType = "Type: " .. toCapitalCase(pokemon.type)
  else
    self.cardColor   = colors.white
    self.displayName = nil
    self.displayType = nil
  end
end

function pokemonCard:draw()
  if not self.selectedPokemon then return end

  love.graphics.setColor(self.cardColor)
  love.graphics.rectangle("fill", self.cardX, self.cardY,
                          self.cardWidth, self.cardHeight,
                          self.cornerRadius)

  love.graphics.setColor(colorWithAlpha("black", 0.5))
  love.graphics.rectangle("fill", self.innerRectX, self.innerRectY,
                          self.innerRectW, self.innerRectH)

  -- Draw Pokémon in center region
  love.graphics.setColor(colors.white)
  love.graphics.setScissor(self.innerRectX, self.innerRectY,
                           self.innerRectW, self.innerRectH)
  
  love.graphics.draw(
    self.selectedPokemon.image,
    self.pokemonX,
    self.pokemonY,
    0, 1, 1,
    math.floor(self.selectedPokemon.imageWidth / 2),
    math.floor(self.selectedPokemon.imageHeight / 2)
  )
  love.graphics.setScissor()

  -- Draw text
  prettyPrint(self.displayName, self.nameX, self.nameY, {
    cell   = true,
    color  = colors.almostWhite,
    bgColor= colors.dark
  })
  prettyPrint(self.displayType, self.nameX, self.typeY, {
    cell   = true,
    color  = colors.almostWhite,
    bgColor= colors.dark
  })
end

return pokemonCard
