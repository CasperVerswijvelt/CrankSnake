local snake = {
  }
local direction = 0 -- 1 = top, 2 = right, 3 = down, 4 = left
local lastDirection = 0
local isPlaying = false

local allowGoTroughWalls = false
local removeTail = true

local hue = 0
local saturation = 1

local food = nil

local function hslToRgb(h, s, l)
  local r, g, b

  if s == 0 then
    r, g, b = l, l, l -- achromatic
  else
    local function hue2rgb(p, q, t)
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

  food = nil
  hue = 0
  saturation = 1
  direction = 0
  lastDirection = 0
  isPlaying = false

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

  if (not isPlaying) then return end

  local data = {}

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

  if (allowGoTroughWalls) then
    newHead.col = math.fmod(newHead.col + 23, 24) + 1
    newHead.row  = math.fmod(newHead.row + 31, 32) + 1
  end

  -- Food check
  local ateFood = food ~= nil and food.col == newHead.col and food.row == newHead.row

  -- Self collision
  local hitSelf = false

  local snakeLength = #snake
  for k,v in pairs(snake) do
    if newHead.col == v.col and newHead.row == v.row then

      -- The last element of the snake will only count as a selfhit
      --  if food was eaten, since we only update the snake after
      --  it is sure that the game isn't over
      if (k == snakeLength and ateFood) then
      else
        hitSelf = true
      end
      break

    end
  end

  -- Wall collision
  local hitWall = newHead.col > 24 or newHead.col < 1 or newHead.row > 32 or newHead.row < 1

  if (hitSelf or hitWall) then

    gameOver()

  else

    if (ateFood) then

      generateFood()
      paintFood()

    else

      -- Remove snake tail
      if (removeTail) then
        data["snakeLayer.Table.color."..snake[#snake].row.."."..snake[#snake].col] = 0x000000
        snake[#snake] = nil
      end

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
  end

end

local function startGame ()
  generateFood()
  paintFood()
  direction = 3
  isPlaying = true

  snake = {{
    col=12,
    row= 16
  }}

  gre.set_value("snakeLayer.Table.color."..snake[1].row.."."..snake[1].col, 0xFFFFFF)
  gre.animation_stop("blink")
  gre.animation_trigger("fadeOutMenu")
end

function CBOnKeyDown (mapargs)

  -- Extract variables
  local key = mapargs.context_event_data.key

  -- Guards
  if (key == nil) then return end

  if (not isPlaying) then

    startGame()

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
  elseif (key == 112) then
    allowGoTroughWalls = not allowGoTroughWalls
  elseif (key == 113) then
    removeTail = not removeTail
  end

end

function CBRender (mapargs)
  render()
end

-- Use this timer if you cannot recieve 'render'
--  events from a c backend
gre.timer_set_interval(CBRender,125)
