-- startup.lua — HUD draconic con AU/MA arreglado y f.lua como módulo

-- ========================
-- 🔹 VARIABLES MODIFICABLES
-- ========================
local targetStrength = 50
local maxTemperature = 8000
local safeTemperature = 3000
local lowestFieldPercent = 15
local activateOnCharged = 1

-- ========================
-- 🔹 LIBRERÍA f.lua
-- ========================
-- asegúrate de tener f.lua en /lib/f.lua
local f = dofile("lib/f.lua")

local version = "0.27"
local autoInputGate = 1
local curInputGate = 222000

-- ========================
-- 🔹 VARIABLES GLOBALES
-- ========================
local mon, monitor, monX, monY
local reactor, fluxgate, inputfluxgate
local ri
local action = "None since reboot"
local emergencyCharge = false
local emergencyTemp = false

-- ========================
-- 🔹 DETECCIÓN AUTOMÁTICA
-- ========================
monitor = f.periphSearch("monitor")
reactor = f.periphSearch("draconic_reactor")

-- buscar flow_gates
local gates = {}
for _, name in pairs(peripheral.getNames()) do
  if peripheral.getType(name) == "flow_gate" then
    table.insert(gates, name)
  end
end

if #gates < 2 then
  error("Necesitas al menos 2 flow_gate conectados")
end

-- elegir gates
local function chooseGate(mon, gates, mensaje)
  f.clear(mon)
  f.draw_text(mon, 2, 2, mensaje, colors.white, colors.black)
  for i, g in ipairs(gates) do
    f.draw_text(mon, 2, 3+i, i..". "..g, colors.yellow, colors.black)
  end
  while true do
    local e, side, x, y = os.pullEvent("monitor_touch")
    local choice = y - 3
    if choice >= 1 and choice <= #gates then
      return gates[choice]
    end
  end
end

if not fs.exists("config_gates.txt") then
  local monX, monY = monitor.getSize()
  mon = { monitor = monitor, X = monX, Y = monY }

  local inputGateSide = chooseGate(mon, gates, "Selecciona el gate de ENTRADA")
  local remaining = {}
  for _, g in ipairs(gates) do
    if g ~= inputGateSide then table.insert(remaining, g) end
  end
  local outputGateSide = chooseGate(mon, remaining, "Selecciona el gate de SALIDA")

  local fconfig = fs.open("config_gates.txt", "w")
  fconfig.writeLine(inputGateSide)
  fconfig.writeLine(outputGateSide)
  fconfig.close()
end

local fconfig = fs.open("config_gates.txt", "r")
local inputGateSide = fconfig.readLine()
local outputGateSide = fconfig.readLine()
fconfig.close()

inputfluxgate = peripheral.wrap(inputGateSide)
fluxgate      = peripheral.wrap(outputGateSide)

if monitor == nil then error("No valid monitor was found") end
if fluxgate == nil then error("No valid flow_gate (output)") end
if reactor == nil then error("No valid reactor") end
if inputfluxgate == nil then error("No valid flow_gate (input)") end

monX, monY = monitor.getSize()
mon = { monitor = monitor, X = monX, Y = monY }

-- ========================
-- 🔹 CONFIG SAVE/LOAD
-- ========================
function save_config()
  local sw = fs.open("config.txt", "w")
  sw.writeLine(version)
  sw.writeLine(autoInputGate)
  sw.writeLine(curInputGate)
  sw.close()
end

function load_config()
  local sr = fs.open("config.txt", "r")
  version = sr.readLine()
  autoInputGate = tonumber(sr.readLine())
  curInputGate = tonumber(sr.readLine())
  sr.close()
end

if not fs.exists("config.txt") then
  save_config()
else
  load_config()
end

-- ========================
-- 🔹 BOTONES
-- ========================
function buttons()
  while true do
    local event, side, xPos, yPos = os.pullEvent("monitor_touch")

    -- output gate
    if yPos == 8 then
      local cFlow = fluxgate.getSignalLowFlow()
      if xPos >= 2 and xPos <= 4 then
        cFlow = cFlow-1000
      elseif xPos >= 6 and xPos <= 9 then
        cFlow = cFlow-10000
      elseif xPos >= 10 and xPos <= 12 then
        cFlow = cFlow-100000
      elseif xPos >= 17 and xPos <= 19 then
        cFlow = cFlow+100000
      elseif xPos >= 21 and xPos <= 23 then
        cFlow = cFlow+10000
      elseif xPos >= 25 and xPos <= 27 then
        cFlow = cFlow+1000
      end
      fluxgate.setSignalLowFlow(cFlow)
    end

    -- input gate
    if yPos == 10 and autoInputGate == 0 and xPos ~= 14 and xPos ~= 15 then
      if xPos >= 2 and xPos <= 4 then
        curInputGate = curInputGate-1000
      elseif xPos >= 6 and xPos <= 9 then
        curInputGate = curInputGate-10000
      elseif xPos >= 10 and xPos <= 12 then
        curInputGate = curInputGate-100000
      elseif xPos >= 17 and xPos <= 19 then
        curInputGate = curInputGate+100000
      elseif xPos >= 21 and xPos <= 23 then
        curInputGate = curInputGate+10000
      elseif xPos >= 25 and xPos <= 27 then
        curInputGate = curInputGate+1000
      end
      inputfluxgate.setSignalLowFlow(curInputGate)
      save_config()
    end

    -- toggle AU/MA
    if yPos == 10 and (xPos == 14 or xPos == 15) then
      autoInputGate = (autoInputGate == 1) and 0 or 1
      save_config()
    end
  end
end

function drawButtons(y)
  f.draw_text(mon, 2, y, " < ", colors.white, colors.gray)
  f.draw_text(mon, 6, y, " <<", colors.white, colors.gray)
  f.draw_text(mon, 10, y, "<<<", colors.white, colors.gray)
  f.draw_text(mon, 17, y, ">>>", colors.white, colors.gray)
  f.draw_text(mon, 21, y, ">> ", colors.white, colors.gray)
  f.draw_text(mon, 25, y, " > ", colors.white, colors.gray)
end

-- ========================
-- 🔹 LOOP DE ACTUALIZACIÓN
-- ========================
function drawStaticUI()
  f.clear(mon)
  f.draw_text(mon, 2, 2, "Reactor Status", colors.white, colors.black)
  f.draw_text(mon, 2, 4, "Generation", colors.white, colors.black)
  f.draw_text(mon, 2, 6, "Temperature", colors.white, colors.black)
  f.draw_text(mon, 2, 7, "Output Gate", colors.white, colors.black)
  f.draw_text(mon, 2, 9, "Input Gate", colors.white, colors.black)
  f.draw_text(mon, 2, 11, "Energy Saturation", colors.white, colors.black)
  f.draw_text(mon, 2, 14, "Field Strength", colors.white, colors.black)
  f.draw_text(mon, 2, 17, "Fuel", colors.white, colors.black)
  f.draw_text(mon, 2, 19, "Action", colors.white, colors.black)
end

function update()
  drawStaticUI()
  while true do
    ri = reactor.getReactorInfo()
    if not ri then error("reactor has an invalid setup") end

    -- (todo el render igual que ya tenías arriba …)

    -- input gate AU/MA
    f.draw_text_lr(mon, 2, 9, 1, "Input Gate", f.format_int(inputfluxgate.getSignalLowFlow()).." rf/t", colors.white, colors.blue, colors.black)
    if autoInputGate == 1 then
      -- limpiar toda la línea antes de pintar AU
      f.draw_line(mon, 2, 10, mon.X-2, colors.black)
      f.draw_text(mon, 14, 10, "AU", colors.white, colors.gray)
    else
      f.draw_text(mon, 14, 10, "MA", colors.white, colors.gray)
      drawButtons(10)
    end

    -- (resto de tu lógica reactor/seguridad igual)

    sleep(0.1)
  end
end

parallel.waitForAny(buttons, update)
