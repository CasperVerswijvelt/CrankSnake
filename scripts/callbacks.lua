local snake = {
  {
    col=12,
    row= 16
  }
}
local direction = 1 -- 1 = top, 2 = right, 3 = down, 4 = left
local speed = 0
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

  table.insert(snake,1,newHead)

  snake[#snake] = nil

  data["snakeLayer.Table.color."..newHead.row.."."..newHead.col] = 0xFFFFFF

  if(newHead.col > 24 or newHead.col < 1 or newHead.row > 32 or newHead.row < 1) then
    speed = 0
    snake = {{
      col=12,
      row= 16
    }}

    local row, col
    for row = 1,32 do

      for col = 1,24 do

        data["snakeLayer.Table.color."..row.."."..col] = 0x000000


      end

    end
    gre.set_data(data)
    render()
  else
    gre.set_data(data)
  end



end



function CBOnKeyDown (mapargs)

  speed = 1
  direction = (direction + 1) % 5 

  -- Extract variables
  local key = mapargs.context_event_data.code
  tprint(mapargs)
  -- Guards
  if (key == nil) then return end

  if(key == 37) then
    direction = 1
  elseif (key == 38) then
    direction = 2
  elseif (key == 39) then
    direction = 3
  elseif (key == 40) then
    direction = 4
  end

end

gre.timer_set_interval(render,250);
