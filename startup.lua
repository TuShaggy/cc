-- modifiable variables
local targetStrength = 50
local maxTemperature = 8000
local safeTemperature = 3000
local lowestFieldPercent = 15
local activateOnCharged = 1

os.loadAPI("lib/f.lua")

local version = "0.25"
local autoInputGate = 1
local curInputGate = 222000

-- Detectar periféricos automáticamente
local monitor, reactor, speaker
for _, name in ipairs(peripheral.getNames()) do
  local pType = peripheral.getType(name)
  local p = peripheral.wrap(name)
  if not monitor and pType == "monitor" then
    monitor = p
  elseif not reactor and pType == "draconic_reactor" then
    reactor = p
  elseif not speaker and pType == "speaker" then
    speaker = p
  end
end

-- Detectar fluxgates
local fluxgateNames = {}
for _, name in ipairs(peripheral.getNames()) do
  if peripheral.getType(name) == "flow_gate" then
    table.insert(fluxgateNames, name)
  end
end

if not monitor then
  error("No valid monitor was found")
end
if not reactor then
  error("No valid draconic reactor was found")
end
if #fluxgateNames < 2 then
  error("Se necesitan al menos dos fluxgate conectados")
end

local mon = monitor

local action = "None since reboot"
local emergencyCharge = false
local emergencyTemp = false

local function selectFluxgates()
  f.clear(mon)
  f.draw_text(mon, 2, 2, "Selecciona Fluxgate de ENTRADA", colors.white, colors.black)
  for i, name in ipairs(fluxgateNames) do
    f.draw_text(mon, 2, 4 + i, i .. ". " .. name, colors.white, colors.gray)
  end

  local selectedInput = nil
  while not selectedInput do
    local event, side, xPos, yPos = os.pullEvent("monitor_touch")
    for i, name in ipairs(fluxgateNames) do
      if yPos == 4 + i then
        selectedInput = i
        f.draw_text(mon, 25, 4 + i, "<- ENTRADA", colors.green, colors.black)
        sleep(0.5)
      end
    end
  end

  f.clear(mon)
  f.draw_text(mon, 2, 2, "Selecciona Fluxgate de SALIDA", colors.white, colors.black)
  for i, name in ipairs(fluxgateNames) do
    f.draw_text(mon, 2, 4 + i, i .. ". " .. name, colors.white, colors.gray)
    if i == selectedInput then
      f.draw_text(mon, 25, 4 + i, "<- ENTRADA", colors.green, colors.black)
    end
  end

  local selectedOutput = nil
  while not selectedOutput do
    local event, side, xPos, yPos = os.pullEvent("monitor_touch")
    for i, name in ipairs(fluxgateNames) do
      if yPos == 4 + i and i ~= selectedInput then
        selectedOutput = i
        f.draw_text(mon, 25, 4 + i, "<- SALIDA", colors.blue, colors.black)
        sleep(0.5)
      end
    end
  end

  return selectedInput, selectedOutput
end

local inputIdx, outputIdx = selectFluxgates()
local inputfluxgate = peripheral.wrap(fluxgateNames[inputIdx])
local fluxgate = peripheral.wrap(fluxgateNames[outputIdx])

if not fluxgate then
  error("No valid fluxgate was found")
end
if not inputfluxgate then
  error("No valid flux gate was found")
end

function save_config()
  local sw = fs.open("config.txt", "w")
  if sw then
    sw.writeLine(version)
    sw.writeLine(autoInputGate)
    sw.writeLine(curInputGate)
    sw.close()
  else
    print("Error: Could not open config.txt for writing")
  end
end

function load_config()
  local sr = fs.open("config.txt", "r")
  if sr then
    version = sr.readLine()
    autoInputGate = tonumber(sr.readLine())
    curInputGate = tonumber(sr.readLine())
    sr.close()
  else
    print("Error: Could not open config.txt for reading")
  end
end

if not fs.exists("config.txt") then
  save_config()
else
  load_config()
end

function buttons()
  while true do
    local event, side, xPos, yPos = os.pullEvent("monitor_touch")

    -- output gate controls
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

    -- input gate controls
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

    -- input gate toggle
    if yPos == 10 and ( xPos == 14 or xPos == 15) then
      if autoInputGate == 1 then
        autoInputGate = 0
      else
        autoInputGate = 1
      end
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

function update()
  while true do
    f.clear(mon) -- limpiar pantalla correctamente

    mon.setCursorPos(1,1) -- instead of f.clear(mon)
   local ri = reactor.getReactorInfo()
if not ri then
  error("reactor has an invalid setup")
end

for k, v in pairs (ri) do
  print(k.. ": ".. tostring(v)) -- Convertir a cadena
end
    print("Output Gate: ", fluxgate.getSignalLowFlow())
    print("Input Gate: ", inputfluxgate.getSignalLowFlow())

    local statusColor = colors.red
    if ri.status == "online" or ri.status == "charged" then
      statusColor = colors.green
    elseif ri.status == "offline" then
      statusColor = colors.gray
    elseif ri.status == "charging" then
      statusColor = colors.orange
    end

    f.draw_text_lr(mon, 2, 2, 1, "Reactor Status", string.upper(ri.status), colors.white, statusColor, colors.black)
    f.draw_text_lr(mon, 2, 4, 1, "Generation", f.format_int(ri.generationRate) .. " rf/t", colors.white, colors.lime, colors.black)

    local tempColor = colors.red
    if ri.temperature <= 5000 then tempColor = colors.green end
    if ri.temperature >= 5000 and ri.temperature <= 6500 then tempColor = colors.orange end
    f.draw_text_lr(mon, 2, 6, 1, "Temperature", f.format_int(ri.temperature) .. "C", colors.white, tempColor, colors.black)

    f.draw_text_lr(mon, 2, 7, 1, "Output Gate", f.format_int(fluxgate.getSignalLowFlow()) .. " rf/t", colors.white, colors.blue, colors.black)
    drawButtons(8)
    f.draw_text_lr(mon, 2, 9, 1, "Input Gate", f.format_int(inputfluxgate.getSignalLowFlow()) .. " rf/t", colors.white, colors.blue, colors.black)

    if autoInputGate == 1 then
      f.draw_text(mon, 14, 10, "AU", colors.white, colors.gray)
    else
      f.draw_text(mon, 14, 10, "MA", colors.white, colors.gray)
      drawButtons(10)
    end

    local monX = mon.getSize and select(1, mon.getSize()) or 39

    local satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000)*.01
    f.draw_text_lr(mon, 2, 11, 1, "Energy Saturation", satPercent .. "%", colors.white, colors.white, colors.black)
    f.progress_bar(mon, 2, 12, monX-2, satPercent, 100, colors.blue, colors.gray)

    local fieldPercent = math.ceil(ri.fieldStrength / ri.maxFieldStrength * 10000)*.01
    local fieldColor = colors.red
    if fieldPercent >= 50 then fieldColor = colors.green end
    if fieldPercent < 50 and fieldPercent > 30 then fieldColor = colors.orange end

    if autoInputGate == 1 then 
      f.draw_text_lr(mon, 2, 14, 1, "Field Strength T:" .. targetStrength, fieldPercent .. "%", colors.white, fieldColor, colors.black)
    else
      f.draw_text_lr(mon, 2, 14, 1, "Field Strength", fieldPercent .. "%", colors.white, fieldColor, colors.black)
    end
    f.progress_bar(mon, 2, 15, monX-2, fieldPercent, 100, fieldColor, colors.gray)

    local fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 10000)*.01
    local fuelColor = colors.red
    if fuelPercent >= 70 then fuelColor = colors.green end
    if fuelPercent < 70 and fuelPercent > 30 then fuelColor = colors.orange end

    f.draw_text_lr(mon, 2, 17, 1, "Fuel ", fuelPercent .. "%", colors.white, fuelColor, colors.black)
    f.progress_bar(mon, 2, 18, monX-2, fuelPercent, 100, fuelColor, colors.gray)

    f.draw_text_lr(mon, 2, 19, 1, "Action ", action, colors.gray, colors.gray, colors.black)

    -- actual reactor interaction
    if emergencyCharge == true then
      reactor.chargeReactor()
    end
    
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
        fluxval = ri.fieldDrainRate / (1 - (targetStrength/100) )
        print("Target Gate: ".. fluxval)
        inputfluxgate.setSignalLowFlow(fluxval)
      else
        inputfluxgate.setSignalLowFlow(curInputGate)
      end
    end

    if fuelPercent <= 10 then
      reactor.stopReactor()
      action = "Fuel below 10%, refuel"
      if speaker then speaker.playSound("minecraft:block.note_block.bass", 3, 1) end
    end

    if fieldPercent <= lowestFieldPercent and ri.status == "online" then
      action = "Field Str < " ..lowestFieldPercent.."%"
      reactor.stopReactor()
      reactor.chargeReactor()
      emergencyCharge = true
      if speaker then speaker.playSound("minecraft:block.note_block.bass", 3, 1) end
    end

    if ri.temperature > maxTemperature then
      reactor.stopReactor()
      action = "Temp > " .. maxTemperature
      emergencyTemp = true
      if speaker then speaker.playSound("minecraft:block.note_block.bass", 3, 1) end
    end

    sleep(0.2) -- menos parpadeo, pero sigue siendo responsivo
  end
end

parallel.waitForAny(buttons, update)