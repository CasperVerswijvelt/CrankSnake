local snake = {
  {
    col=12,
    row= 16
  }
}
local direction = 0 -- 1 = top, 2 = right, 3 = down, 4 = left
local lastDirection = 0
local speed = 0
local timeoutTimer

local hue = 0
local saturation = 1

local food = nil

local startScreenActive = true

--function tprint (tbl, indent)
--  if not indent then indent = 0 end
--  for k, v in pairs(tbl) do
--    formatting = string.rep("  ", indent) .. k .. ": "
--    if type(v) == "table" then
--      print(formatting)
--      tprint(tostring(v), indent+1)
--    else
--      print(formatting .. tostring(v))
--    end
--  end
--end

--[[


 * Converts an HSL color value to RGB. Conversion formula


 * adapted from http://en.wikipedia.org/wiki/HSL_color_space.


 * Assumes h, s, and l are contained in the set [0, 1] and


 * returns r, g, and b in the set [0, 255].


 *


 * @param   Number  h       The hue


 * @param   Number  s       The saturation


 * @param   Number  l       The lightness


 * @return  Array           The RGB representation


]]
local function hslToRgb(h, s, l)
  local r, g, b

  if s == 0 then
    r, g, b = l, l, l -- achromatic
  else
    function hue2rgb(p, q, t)
      if t < 0   then t = t + 1 end
      if t > 1   then t = t - 1 end
      if t < 1/6 then return p + (q - p) * 6 * t end
      if t < 1/2 then return q end
      if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
      return p
    end

    local q
    if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
    local p = 2 * l - q

    r = hue2rgb(p, q, h + 1/3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1/3)
  end

  return r * 255, g * 255, b * 255
end

local function gameOver()

  local data = {}

  for k,v in pairs(snake) do
    data["snakeLayer.Table.color."..tostring(v.row).."."..tostring(v.col)] = 0x000000
  end
  data["snakeLayer.food.grd_hidden"] = true
  data["snakeLayer.score.grd_hidden"] = true
  data["snakeLayer.title.topScore"] = tostring(#snake)

  gre.set_data(data)
  
  snake = {{
    col=12,
    row= 16
  }}
  food = nil
  hue = 0
  saturation = 1
  direction = 0
  lastDirection = 0
  speed = 0

  gre.animation_trigger("fadeInMenu")

end

local function generateFood()

  local col =  math.random(24)
  local row = math.random(32)

  food = {
    col=col,
    row=row
  }

end

local function paintFood()

  if (food == nil) then return end

  local data ={}
  data["snakeLayer.food.grd_hidden"] = false
  data["snakeLayer.food.grd_x"] = (food.col - 1) * 10
  data["snakeLayer.food.grd_y"] = (food.row - 1) * 10
  gre.set_data(data)

end

local function render ()
  collectgarbage()

  if (speed == 0) then return end

  local data = {}

  -- Paint snake tail black
  data["snakeLayer.Table.color."..snake[#snake].row.."."..snake[#snake].col] = 0x000000

  local newHead = {
    col=snake[1].col,
    row=snake[1].row
  }

  if(direction == 1) then
    newHead.row = newHead.row - 1
  elseif (direction == 2) then
    newHead.col = newHead.col + 1
  elseif (direction == 3) then
    newHead.row = newHead.row + 1
  elseif (direction == 4) then
    newHead.col = newHead.col - 1
  end

  -- Food check
  local ateFood = food ~= nil and food.col == newHead.col and food.row == newHead.row


  -- Self collision
  local hitSelf = false
  for k,v in pairs(snake) do
    if newHead.col == v.col and newHead.row == v.row then

      hitSelf = true
      break

    end
  end

  -- Wall collision
  local hitWall = newHead.col > 24 or newHead.col < 1 or newHead.row > 32 or newHead.row < 1

  if(hitSelf or hitWall) then

    gameOver()

  else

    if (ateFood) then

      generateFood()
      paintFood()

    else 
    
      -- Remove snake tail
      snake[#snake] = nil
    
    end

    -- Insert new snake head at pos 1
    table.insert(snake,1,newHead)

    -- Paint snake head
    local r, g, b = hslToRgb(hue/255,1, saturation)
    data["snakeLayer.Table.color."..newHead.row.."."..newHead.col] = gre.rgb(r,g,b)
    data["snakeLayer.Table.alpha."..newHead.row.."."..newHead.col] = 0
    data["snakeLayer.score.text"] = tostring(#snake)
    data["snakeLayer.score.grd_hidden"] = false
    
    gre.set_data(data)

    hue = (hue + 5) % 256
    saturation = math.max(saturation-0.03, 0.5)

    lastDirection = direction

--    gre.timer_clear_timeout(timeoutTimer)
--    timeoutTimer = gre.timer_set_timeout(render,125)
--    
--    print('set timeout')
  end

end


function CBOnKeyDown (mapargs)

  -- Extract variables
  local key = mapargs.context_event_data.key

  -- Guards
  if (key == nil) then return end

  local shouldStartGame = false

  if (speed == 0) then

    generateFood()
    paintFood()
    speed = 1
    direction = 3
    shouldStartGame = true

  end

  if (startScreenActive) then

    gre.animation_stop("blink")
    gre.animation_trigger("fadeOutMenu")

  end

  -- Set direction
  if (key == 37 and lastDirection ~= 2) then
    direction = 4
  elseif (key == 38 and lastDirection ~= 3) then
    direction = 1
  elseif (key == 39 and lastDirection ~= 4) then
    direction = 2
  elseif (key == 40 and lastDirection ~= 1) then
    direction = 3
  end

  if (shouldStartGame) then

    render()

  end


end

function CBOnAppInit (mapargs)

  gre.animation_trigger("blink")

end

function CBOnBlinkComplete (mapargs)

  if (startScreenActive) then
    gre.animation_trigger("blink")
  end

end

function CBOnSecond (mapargs)
render()
end