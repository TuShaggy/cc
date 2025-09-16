-- startup.lua — HUD draconic con botones en cajas y AU/MA mejorado

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
-- 🔹 DETECCIÓN PERIFÉRICOS
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

if not monitor then error("No valid monitor was found") end
if not fluxgate then error("No valid flow_gate (output)") end
if not reactor then error("No valid reactor") end
if not inputfluxgate then error("No valid flow_gate (input)") end

monX, monY = monitor.getSize()
mon = { monitor = monitor, X = monX, Y = monY }

-- ========================
-- 🔹 CONFIG SAVE/LOAD
-- ========================
local function save_config()
  local sw = fs.open("config.txt", "w")
  sw.writeLine(version)
  sw.writeLine(autoInputGate)
  sw.writeLine(curInputGate)
  sw.close()
end

local function load_config()
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
-- 🔹 DIBUJO DE BOTONES
-- ========================
local function drawButton(x, y, w, label)
  f.draw_line(mon, x, y, w, colors.gray)
  f.draw_text(mon, x + math.floor((w - #label)/2), y, label, colors.white, colors.gray)
end

local function drawButtons(y)
  drawButton(2,  y, 3,  "<")
  drawButton(6,  y, 3, "<<")
  drawButton(10, y, 3, "<<<")
  drawButton(17, y, 3, ">>>")
  drawButton(21, y, 3, ">>")
  drawButton(25, y, 3, ">")
end

local function drawToggle(x, y, label, active)
  local bg = active and colors.green or colors.gray
  f.draw_line(mon, x, y, 3, bg)
  f.draw_text(mon, x+1, y, label, colors.white, bg)
end

-- ========================
-- 🔹 BOTONES (EVENTOS)
-- ========================
local function buttons()
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

-- ========================
-- 🔹 UI ESTÁTICA
-- ========================
local function drawStaticUI()
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

-- ========================
-- 🔹 LOOP DE ACTUALIZACIÓN
-- ========================
local function update()
  drawStaticUI()
  while true do
    ri = reactor.getReactorInfo()
    if not ri then error("reactor has an invalid setup") end

    -- Status
    local statusColor = colors.red
    if ri.status == "online" or ri.status == "charged" then
      statusColor = colors.green
    elseif ri.status == "offline" then
      statusColor = colors.gray
    elseif ri.status == "charging" then
      statusColor = colors.orange
    end
    f.draw_text_lr(mon, 2, 2, 1, "Reactor Status", string.upper(ri.status), colors.white, statusColor, colors.black)

    -- Generation
    f.draw_text_lr(mon, 2, 4, 1, "Generation", f.format_int(ri.generationRate).." rf/t", colors.white, colors.lime, colors.black)

    -- Temperature
    local tempColor = colors.red
    if ri.temperature <= 5000 then tempColor = colors.green end
    if ri.temperature > 5000 and ri.temperature <= 6500 then tempColor = colors.orange end
    f.draw_text_lr(mon, 2, 6, 1, "Temperature", f.format_int(ri.temperature).."C", colors.white, tempColor, colors.black)

    -- Output Gate
    f.draw_text_lr(mon, 2, 7, 1, "Output Gate", f.format_int(fluxgate.getSignalLowFlow()).." rf/t", colors.white, colors.blue, colors.black)
    drawButtons(8)

    -- Input Gate
    f.draw_text_lr(mon, 2, 9, 1, "Input Gate", f.format_int(inputfluxgate.getSignalLowFlow()).." rf/t", colors.white, colors.blue, colors.black)
    -- limpiar toda la fila antes de redibujar
f.draw_line(mon, 2, 10, mon.X-2, colors.black)

if autoInputGate == 1 then
  -- solo toggle en verde
  drawToggle(14, 10, "AU", true)
else
  -- toggle en gris + botones manuales
  drawToggle(14, 10, "MA", false)
  drawButtons(10)
end

  

    -- Energy Saturation
    local satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000) * .01
    f.draw_text_lr(mon, 2, 11, 1, "Energy Saturation", satPercent.." %", colors.white, colors.white, colors.black)
    f.progress_bar(mon, 2, 12, mon.X-2, satPercent, 100, colors.blue, colors.gray)

    -- Field Strength
    local fieldPercent = math.ceil(ri.fieldStrength / ri.maxFieldStrength * 10000) * .01
    local fieldColor = colors.red
    if fieldPercent >= 50 then fieldColor = colors.green end
    if fieldPercent < 50 and fieldPercent > 30 then fieldColor = colors.orange end
    if autoInputGate == 1 then
      f.draw_text_lr(mon, 2, 14, 1, "Field Strength T:"..targetStrength, fieldPercent.." %", colors.white, fieldColor, colors.black)
    else
      f.draw_text_lr(mon, 2, 14, 1, "Field Strength", fieldPercent.." %", colors.white, fieldColor, colors.black)
    end
    f.progress_bar(mon, 2, 15, mon.X-2, fieldPercent, 100, fieldColor, colors.gray)

    -- Fuel
    local fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 10000) * .01
    local fuelColor = colors.red
    if fuelPercent >= 70 then fuelColor = colors.green end
    if fuelPercent < 70 and fuelPercent > 30 then fuelColor = colors.orange end
    f.draw_text_lr(mon, 2, 17, 1, "Fuel", fuelPercent.." %", colors.white, fuelColor, colors.black)
    f.progress_bar(mon, 2, 18, mon.X-2, fuelPercent, 100, fuelColor, colors.gray)

    -- Action
    f.draw_text_lr(mon, 2, 19, 1, "Action", action, colors.gray, colors.gray, colors.black)

    -- Reactor logic
    if emergencyCharge == true then reactor.chargeReactor() end
    if ri.status == "charging" then
      inputfluxgate.setSignalLowFlow(900000)
      emergencyCharge = false
    end
    if emergencyTemp == true and ri.status == "stopping" and ri.temperature < safeTemperature then
      reactor.activateReactor()
      emergencyTemp = false
    end
    if ri.status == "charged" and activateOnCharged == 1 then
      reactor.activateReactor()
    end
    if ri.status == "online" then
      if autoInputGate == 1 then
        local fluxval = ri.fieldDrainRate / (1 - (targetStrength/100))
        inputfluxgate.setSignalLowFlow(fluxval)
      else
        inputfluxgate.setSignalLowFlow(curInputGate)
      end
    end

    -- Safeguards
    if fuelPercent <= 10 then
      reactor.stopReactor()
      action = "Fuel below 10%, refuel"
    end
    if fieldPercent <= lowestFieldPercent and ri.status == "online" then
      action = "Field Str < "..lowestFieldPercent.."%"
      reactor.stopReactor()
      reactor.chargeReactor()
      emergencyCharge = true
    end
    if ri.temperature > maxTemperature then
      reactor.stopReactor()
      action = "Temp > "..maxTemperature
      emergencyTemp = true
    end

    sleep(0.1)
  end
end

-- ========================
-- 🔹 MAIN
-- ========================
parallel.waitForAny(buttons, update)
