-- pokemonCard.lua

local pokemonCard = {}
pokemonCard.__index = pokemonCard

function pokemonCard.new(x, y)
  local o = {
    cardWidth       = 180,
    cardHeight      = 60,
    cornerRadius    = 0,
    cardPadding     = 3,
    innerRectX      = 0,
    innerRectY      = 0,
    innerRectW      = 0,
    innerRectH      = 0,
    selectedPokemon = nil,
    cardColor       = colors.white,
    displayName     = nil,
    displayType     = nil
  }

  o.cardX       = x
  o.cardY       = y
  o.innerRectX  = o.cardX + o.cardPadding
  o.innerRectY  = o.cardY + o.cardPadding
  o.innerRectW  = math.floor(o.cardWidth / 2 - o.cardPadding * 2)
  o.innerRectH  = o.cardHeight - o.cardPadding * 2
  o.pokemonX    = math.floor(o.cardX + o.cardPadding + o.innerRectW / 2)
  o.pokemonY    = math.floor(o.cardY + o.cardPadding + o.innerRectH / 2)
  local yBase   = o.cardY + o.cardPadding 
                + o.cardHeight * 0.7 
                - font:getHeight() * 1.2
  o.nameX       = math.floor(o.cardX + o.innerRectW + o.cardPadding * 2)
  o.nameY       = math.floor(o.cardY + o.cardPadding)
  o.typeY       = math.floor(o.nameY + font:getHeight() * 1.4)
  
  return setmetatable(o, pokemonCard)
end

function pokemonCard:setPokemon(p)
  self.selectedPokemon = p
  if p then
    local function getPokemonColor(t)
      if     t == "fire"     then return colors.darkRed
      elseif t == "water"    then return colors.skyBlue
      elseif t == "grass"    then return colors.darkGreen
      elseif t == "electric" then return colors.yellow
      elseif t == "dragon"   then return colors.dragon
      elseif t == "steel"    then return colors.steelBlue
      elseif t == "ice"      then return colors.iceBlue
      elseif t == "ghost"    then return colors.purple
      elseif t == "psychic"  then return colors.pink
      else                        return colors.white
      end
    end
    self.cardColor   = getPokemonColor(p.type)
    self.displayName = "Name: " .. toCapitalCase(p.name)
    self.displayType = "Type: " .. toCapitalCase(p.type)
  else
    self.cardColor   = colors.white
    self.displayName = nil
    self.displayType = nil
  end
end

function pokemonCard:draw()
  if not self.selectedPokemon then return end
  love.graphics.setColor(self.cardColor)
  love.graphics.rectangle("fill", self.cardX, self.cardY, self.cardWidth, self.cardHeight, self.cornerRadius)
  love.graphics.setColor(colorWithAlpha("black", 0.5))
  love.graphics.rectangle("fill", self.innerRectX, self.innerRectY, self.innerRectW, self.innerRectH)
  love.graphics.setColor(colors.white)
  love.graphics.setScissor(self.innerRectX, self.innerRectY, self.innerRectW, self.innerRectH)
  love.graphics.draw(
    self.selectedPokemon.image,
    self.pokemonX,
    self.pokemonY,
    0,
    1,
    1,
    math.floor(self.selectedPokemon.imageWidth / 2),
    math.floor(self.selectedPokemon.imageHeight / 2)
  )
  love.graphics.setScissor()
  prettyPrint(
    self.displayName,
    self.nameX,
    self.nameY,
    { cell = true, color = colors.almostWhite, bgColor = colors.dark }
  )
  prettyPrint(
    self.displayType,
    self.nameX,
    self.typeY,
    { cell = true, color = colors.almostWhite, bgColor = colors.dark }
  )
end

return pokemonCard
