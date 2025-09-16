-- f.lua — librería de UI y helpers

local f = {}

function f.clear(mon)
  mon.monitor.setBackgroundColor(colors.black)
  mon.monitor.clear()
end

function f.draw_text(mon, x, y, text, text_color, bg_color)
  mon.monitor.setCursorPos(x, y)
  mon.monitor.setBackgroundColor(bg_color)
  mon.monitor.setTextColor(text_color)
  -- limpiar zona amplia (15 espacios) para evitar “fantasmas”
  mon.monitor.write(string.rep(" ", 15))
  mon.monitor.setCursorPos(x, y)
  mon.monitor.write(text)
end

function f.draw_text_lr(mon, x, y, margin, leftText, rightText, leftColor, rightColor, bgColor)
  mon.monitor.setBackgroundColor(bgColor)
  mon.monitor.setCursorPos(x, y)
  mon.monitor.setTextColor(leftColor)
  mon.monitor.write(leftText)
  local rightStart = mon.X - #tostring(rightText) - margin
  mon.monitor.setCursorPos(rightStart, y)
  mon.monitor.setTextColor(rightColor)
  -- limpiar antes de escribir
  mon.monitor.write(string.rep(" ", #tostring(rightText)))
  mon.monitor.setCursorPos(rightStart, y)
  mon.monitor.write(rightText)
end

function f.draw_line(mon, x, y, length, color)
  mon.monitor.setCursorPos(x, y)
  mon.monitor.setBackgroundColor(color)
  mon.monitor.write(string.rep(" ", length))
end

function f.progress_bar(mon, x, y, length, value, max, bar_color, bg_color)
  local filled = math.floor((value / max) * length)
  f.draw_line(mon, x, y, length, bg_color)
  if filled > 0 then
    f.draw_line(mon, x, y, filled, bar_color)
  end
end

function f.format_int(number)
  local n = math.floor(number)
  local s = tostring(n)
  local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
  return formatted
end

function f.periphSearch(periphType)
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == periphType then
      return peripheral.wrap(name)
    end
  end
  return nil
end

return f
