local snake = {
  {
    col=12,
    row= 16
  }
}
local direction = 1 -- 1 = top, 2 = right, 3 = down, 4 = left
local speed = 0

local food = {
}

local startScreenActive = true

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    else
      print(formatting .. v)
    end
  end
end

local function gameOver()

  local data = {}
  
  speed = 0
  snake = {{
    col=12,
    row= 16
  }}
  food = {}

  local row, col
  for row = 1,32 do
    for col = 1,24 do
      data["snakeLayer.Table.color."..row.."."..col] = 0x000000
      data["snakeLayer.Table.alpha."..row.."."..col] = 0
    end
  end
    
  gre.set_data(data)

  gre.animation_trigger("fadeInMenu")

end

local function generateFood()
  
  local col = math.random(24)
  local row = math.random(32)
  
  print(col,row)
  
  table.insert(food,1,{
    col=col,
    row=row
  })

end

local function paintFood() 

  local data ={}
  for k,v in pairs(food) do
  tprint(v)
    data["snakeLayer.Table.alpha."..v.row.."."..v.col] = 255
  end
  gre.set_data(data)

end

local function render ()

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
  local ateFood = false
    
  for k,v in pairs(food) do
    if (v.col == newHead.col and v.row == newHead.row) then
        
      ateFood = true
      food[k] = nil
      break
        
    end
  end
  
  if (not ateFood) then
    
    -- Remove snake tail
    snake[#snake] = nil
      
  end

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

    end
    
    -- Insert new snake head at pos 1
    table.insert(snake,1,newHead)
    
    -- Paint snake head
    data["snakeLayer.Table.color."..newHead.row.."."..newHead.col] = 0xFFFFFF
    data["snakeLayer.Table.alpha."..newHead.row.."."..newHead.col] = 0
    gre.set_data(data)
    
  end

end


function CBOnKeyDown (mapargs)

  -- Extract variables
  local key = mapargs.context_event_data.key

  -- Guards
  if (key == nil) then return end

  if (speed == 0) then
  
    generateFood()
    paintFood()
    speed = 1
  
  end
  
  if (startScreenActive) then
  
    gre.animation_stop("blink")
    gre.animation_trigger("fadeOutMenu")
  
  end
  
  -- Set direction
  if(key == 37 and direction ~= 2) then
    direction = 4
  elseif (key == 38 and direction ~= 3) then
    direction = 1
  elseif (key == 39 and direction ~= 4) then
    direction = 2
  elseif (key == 40 and direction ~= 1) then
    direction = 3
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

gre.timer_set_interval(render,125);
