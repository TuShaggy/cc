-- peripheral identification
function periphSearch(type)
   local names = peripheral.getNames()
   local i, name
   for i, name in pairs(names) do
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

--display text text on monitor, "mon" peripheral
function draw_text(mon, x, y, text, text_color, bg_color)
  mon.setBackgroundColor(bg_color)
  mon.setTextColor(text_color)
  mon.setCursorPos(x,y)
  mon.write(text)
end

function draw_text_right(mon, offset, y, text, text_color, bg_color)
  local monX = mon.getSize and select(1, mon.getSize()) or 39 -- fallback to 39 if getSize fails
  mon.setBackgroundColor(bg_color)
  mon.setTextColor(text_color)
  mon.setCursorPos(monX-string.len(tostring(text))-offset, y)
  mon.write(text)
end

function draw_text_lr(mon, x, y, offset, text1, text2, text1_color, text2_color, bg_color)
    draw_text(mon, x, y, text1, text1_color, bg_color)
    draw_text_right(mon, offset, y, text2, text2_color, bg_color)
end

--draw line on computer terminal
function draw_line(mon, x, y, length, color)
    if length < 0 then
      length = 0
    end
    mon.setBackgroundColor(color)
    mon.setCursorPos(x,y)
    mon.write(string.rep(" ", length))
end

--create progress bar
--draws two overlapping lines
--background line of bg_color
--main line of bar_color as a percentage of minVal/maxVal
function progress_bar(mon, x, y, length, minVal, maxVal, bar_color, bg_color)
  draw_line(mon, x, y, length, bg_color) --background bar
  local barSize = math.floor((minVal/maxVal) * length)
  draw_line(mon, x, y, barSize, bar_color) --progress so far
end

function clear(mon)
  if not mon then return end
  if mon.setBackgroundColor and mon.clear and mon.setCursorPos then
    mon.setBackgroundColor(colors.black)
    mon.clear()
    mon.setCursorPos(1,1)
  end
end