local ui = {}

-- Double buffering
local buffer1 = {}
local buffer2 = {}
local currentBuffer = buffer1

local function swapBuffers()
  if currentBuffer == buffer1 then
    currentBuffer = buffer2
  else
    currentBuffer = buffer1
  end
end

function ui.clearBuffer(buffer)
  for y = 1, monY do
    buffer[y] = string.rep(" ", monX)
  end
end

function ui.flushBuffer(mon)
  for y = 1, monY do
    mon.setCursorPos(1, y)
    mon.write(currentBuffer[y])
  end
end

-- UI element creation functions
function ui.button(x, y, width, height, text, callback)
  return {
    type = "button",
    x = x,
    y = y,
    width = width,
    height = height,
    text = text,
    callback = callback,
  }
end

function ui.label(x, y, text)
  return {
    type = "label",
    x = x,
    y = y,
    text = text,
  }
end

-- UI rendering functions
function ui.draw(element, mon)
  if element.type == "button" then
    mon.setBackgroundColor(colors.gray)
    mon.setTextColor(colors.white)
    for y = element.y, element.y + element.height - 1 do
      mon.setCursorPos(element.x, y)
      mon.write(string.rep(" ", element.width))
    end
    mon.setCursorPos(element.x + 1, element.y + 1)
    mon.write(element.text)
  elseif element.type == "label" then
    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.white)
    mon.setCursorPos(element.x, element.y)
    mon.write(element.text)
  end
end

-- Event handling
function ui.handleClick(x, y, elements)
  for _, element in ipairs(elements) do
    if element.type == "button" and x >= element.x and x < element.x + element.width and y >= element.y and y < element.y + element.height then
      element.callback()
      return true
    end
  end
  return false
end

-- Layout functions
function ui.center(x)
  return math.floor(monX / 2 - x / 2)
end

return ui
