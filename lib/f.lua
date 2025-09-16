-- peripheral identification
function periphSearch(type)
   local names = peripheral.getNames()
   for _, name in ipairs(names) do
      if peripheral.getType(name) == type then
         return peripheral.wrap(name)
      end
   end
   return nil
end

-- formatting

function format_int(number)
    if number == nil then number = 0 end
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1,")
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

-- monitor related

function draw_text(mon, x, y, text, text_color, bg_color)
  if not mon then return end
  mon.setBackgroundColor(bg_color)
  mon.setTextColor(text_color)
  mon.setCursorPos(x,y)
  mon.write(text)
end

function draw_text_right(mon, offset, y, text, text_color, bg_color)
  if not mon then return end
  local monX = mon.getSize and select(1, mon.getSize()) or 39
  mon.setBackgroundColor(bg_color)
  mon.setTextColor(text_color)
  mon.setCursorPos(monX-string.len(tostring(text))-offset, y)
  mon.write(text)
end

function draw_text_lr(mon, x, y, offset, text1, text2, text1_color, text2_color, bg_color)
    draw_text(mon, x, y, text1, text1_color, bg_color)
    draw_text_right(mon, offset, y, text2, text2_color, bg_color)
end

function draw_line(mon, x, y, length, color)
    if not mon then return end
    if length < 0 then
      length = 0
    end
    mon.setBackgroundColor(color)
    mon.setCursorPos(x,y)
    mon.write(string.rep(" ", length))
end

function progress_bar(mon, x, y, length, minVal, maxVal, bar_color, bg_color)
  if not mon then return end
  draw_line(mon, x, y, length, bg_color)
  local barSize = math.floor((minVal/maxVal) * length)
  draw_line(mon, x, y, barSize, bar_color)
end

function clear(mon)
  if not mon then return end
  mon.setBackgroundColor(colors.black)
  mon.clear()
  mon.setCursorPos(1,1)
end

function clear_area(mon, x1, y1, x2, y2)
  if not mon then return end
  mon.setBackgroundColor(colors.black)
  for y = y1, y2 do
    mon.setCursorPos(x1, y)
    mon.write(string.rep(" ", x2 - x1 + 1))
  end
end