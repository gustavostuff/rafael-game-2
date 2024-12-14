return {
  escape = 'escape',
  up = 'up',
  down = 'down',
  left = 'left',
  right = 'right',
  space = 'space',
  enter = 'return',
  tab = 'tab',
  n = 'n',
  a = 'a',
  w = 'w',
  s = 's',
  d = 'd',
  l = 'l',
  r = 'r',
  g = 'g',
  f1 = 'f1',
  f12 = 'f12',
  one = '1',
  two = '2',
  three = '3',

  ctrlDown = function ()
    return love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')
  end,
  shiftDown = function ()
    return love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')
  end,
  isEnterKey = function (key)
    return key == 'return' or key == 'kpenter' or key == 'enter'
  end,
  spaceDown = function ()
    return love.keyboard.isDown('space')
  end,
  anyDown = function (keys)
    for _, k in ipairs(keys) do
      if love.keyboard.isDown(k) then
        return true
      end
    end
    return false
  end,
  isAnyOf = function(key, keys)
    for _, k in ipairs(keys) do
      if key == k then
        return true
      end
    end
    return false
  end,
}
