

-- peripheral identification
--
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
  -- reverse the int-string and append a comma to all blocks of 3 digits
  int = int:reverse():gsub("(%d%d%d)", "%1,")

  -- reverse the int-string back remove an optional comma and put the
  -- optional minus and fractional part back
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
  mon.setBackgroundColor(bg_color)
  mon.setTextColor(text_color)
  mon.setCursorPos(mon.X-string.len(tostring(text))-offset,y)
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
  draw_line(mon, x, y, length, bg_color) --backgoround bar
  local barSize = math.floor((minVal/maxVal) * length)
  draw_line(mon, x, y, barSize, bar_color) --progress so far
end


function clear(mon)
  if not mon then return end
  local m = mon.monitor or mon
  if m and m.setBackgroundColor and m.clear and m.setCursorPos then
    m.setBackgroundColor(colors.black)
    m.clear()
    m.setCursorPos(1,1)
  end
end
