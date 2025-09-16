-- f.lua — librería de UI y helpers (versión moderna con return f)

local f = {}

-- Limpia la pantalla del monitor
function f.clear(mon)
  mon.monitor.setBackgroundColor(colors.black)
  mon.monitor.clear()
end

-- Dibuja texto en (x,y), limpiando la zona antes de escribir
function f.draw_text(mon, x, y, text, text_color, bg_color)
  mon.monitor.setCursorPos(x, y)
  mon.monitor.setBackgroundColor(bg_color)
  mon.monitor.setTextColor(text_color)
  mon.monitor.write(string.rep(" ", 15)) -- limpia hasta 15 caracteres
  mon.monitor.setCursorPos(x, y)
  mon.monitor.write(text)
end

-- Dibuja texto alineado a izquierda y derecha en la misma línea
function f.draw_text_lr(mon, x, y, margin, leftText, rightText, leftColor, rightColor, bgColor)
  mon.monitor.setBackgroundColor(bgColor)

  -- Texto a la izquierda
  mon.monitor.setCursorPos(x, y)
  mon.monitor.setTextColor(leftColor)
  mon.monitor.write(leftText)

  -- Texto a la derecha
  local rightStart = mon.X - #tostring(rightText) - margin
  mon.monitor.setCursorPos(rightStart, y)
  mon.monitor.setTextColor(rightColor)
  -- limpiar la zona antes de escribir
  mon.monitor.write(string.rep(" ", #tostring(rightText)))
  mon.monitor.setCursorPos(rightStart, y)
  mon.monitor.write(rightText)
end

-- Dibuja una línea de fondo (rellena con espacios)
function f.draw_line(mon, x, y, length, color)
  mon.monitor.setCursorPos(x, y)
  mon.monitor.setBackgroundColor(color)
  mon.monitor.write(string.rep(" ", length))
end

-- Barra de progreso
function f.progress_bar(mon, x, y, length, value, max, bar_color, bg_color)
  local filled = math.floor((value / max) * length)
  f.draw_line(mon, x, y, length, bg_color)
  if filled > 0 then
    f.draw_line(mon, x, y, filled, bar_color)
  end
end

-- Formatea números con comas: 1000000 -> 1,000,000
function f.format_int(number)
  local n = math.floor(number)
  local s = tostring(n)
  local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
  return formatted
end

-- Busca y envuelve un periférico por tipo
function f.periphSearch(periphType)
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == periphType then
      return peripheral.wrap(name)
    end
  end
  return nil
end

return f
