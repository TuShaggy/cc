-- modifiable variables
local targetStrength = 50
local maxTemperature = 8000
local safeTemperature = 3000
local lowestFieldPercent = 15
local activateOnCharged = 1

os.loadAPI("lib/f.lua")
local ui = require("lib.ui") -- Correct the path to ui.lua

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
local monX, monY = mon.getSize()

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
f.clear(mon) -- Clear screen after fluxgate selection
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

local function toggleAutoInputGate()
  if autoInputGate == 1 then
    autoInputGate = 0
  else
    autoInputGate = 1
  end
  save_config()
end

-- UI elements
local elements = {
  ui.label(2, 2, "Reactor Status:"),
  ui.label(2, 4, "Generation:"),
  ui.label(2, 6, "Temperature:"),
  ui.label(2, 7, "Output Gate:"),
  ui.label(2, 9, "Input Gate:"),
  ui.label(2, 11, "Energy Saturation:"),
  ui.label(2, 14, "Field Strength:"),
  ui.label(2, 17, "Fuel:"),
  ui.label(2, 19, "Action:"),
  ui.button(ui.center(6), 10, 4, 2, "AU/MA", toggleAutoInputGate),
}

function buttons()
  while true do
    local event, side, xPos, yPos = os.pullEvent("monitor_touch")
    ui.handleClick(xPos, yPos, elements)
  end
end

local previousValues = {}
previousValues.lastCriticalUpdate = 0 -- Initialize lastCriticalUpdate
local lastUpdate = 0
local updateInterval = 0.3         -- Only update every 0.3 seconds (less critical info)
local criticalUpdateInterval = 0.1 -- Update every 0.1 seconds (temp, in/out)

function update()
  while true do
    local currentTime = os.time()

    local ri = reactor.getReactorInfo()
    if not ri then
      error("reactor has an invalid setup")
    end

    local status = string.upper(ri.status)
    local generationRate = f.format_int(ri.generationRate) .. " rf/t"
    local temperature = f.format_int(ri.temperature) .. "C"
    local outputGate = f.format_int(fluxgate.getSignalLowFlow()) .. " rf/t"
    local inputGate = f.format_int(inputfluxgate.getSignalLowFlow()) .. " rf/t"
    local satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000)*.01
    local fieldPercent = math.ceil(ri.fieldStrength / ri.maxFieldStrength * 10000)*.01
    local fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 10000)*.01
    local actionText = action

    -- Temperature (CRITICAL)
    if currentTime - previousValues.lastCriticalUpdate >= criticalUpdateInterval or previousValues.temperature ~= temperature then
      f.clear_area(mon, 1, 6, monX, 6)
      local tempColor = colors.red
      if ri.temperature <= 5000 then tempColor = colors.green end
      if ri.temperature >= 5000 and ri.temperature <= 6500 then tempColor = colors.orange end
      f.draw_text_lr(mon, 2, 6, 1, "Temperature", temperature, colors.white, tempColor, colors.black)
      previousValues.temperature = temperature
    end

    -- Output Gate (CRITICAL)
    if currentTime - previousValues.lastCriticalUpdate >= criticalUpdateInterval or previousValues.outputGate ~= outputGate then
      f.clear_area(mon, 1, 7, monX, 7)
      f.draw_text_lr(mon, 2, 7, 1, "Output Gate", outputGate, colors.white, colors.blue, colors.black)
      previousValues.outputGate = outputGate
    end

    -- Input Gate (CRITICAL)
    if currentTime - previousValues.lastCriticalUpdate >= criticalUpdateInterval or  previousValues.inputGate ~= inputGate then
      f.clear_area(mon, 1, 9, monX, 9)
      f.draw_text_lr(mon, 2, 9, 1, "Input Gate", inputGate, colors.white, colors.blue, colors.black)
      previousValues.inputGate = inputGate
      previousValues.lastCriticalUpdate = currentTime
    end

    if currentTime - lastUpdate >= updateInterval then
      lastUpdate = currentTime

      -- Reactor Status
      if previousValues.status ~= status then
        f.clear_area(mon, 1, 2, monX, 2)
        local statusColor = colors.red
        if ri.status == "online" or ri.status == "charged" then
          statusColor = colors.green
        elseif ri.status == "offline" then
          statusColor = colors.gray
        elseif ri.status == "charging" then
          statusColor = colors.orange
        end
        f.draw_text_lr(mon, 2, 2, 1, "Reactor Status", status, colors.white, statusColor, colors.black)
        previousValues.status = status
      end

      -- Generation Rate
      if previousValues.generationRate ~= generationRate then
        f.clear_area(mon, 1, 4, monX, 4)
        f.draw_text_lr(mon, 2, 4, 1, "Generation", generationRate, colors.white, colors.lime, colors.black)
        previousValues.generationRate = generationRate
      end

      -- Energy Saturation
      local satPercentText = satPercent .. "%"
      if previousValues.satPercentText ~= satPercentText then
        f.clear_area(mon, 1, 11, monX, 12)
        f.draw_text_lr(mon, 2, 11, 1, "Energy Saturation", satPercentText, colors.white, colors.white, colors.black)
        f.progress_bar(mon, 2, 12, monX-2, satPercent, 100, colors.blue, colors.gray)
        previousValues.satPercentText = satPercentText
      end

      -- Field Strength
      local fieldPercentText = fieldPercent .. "%"
      if previousValues.fieldPercentText ~= fieldPercentText then
        f.clear_area(mon, 1, 14, monX, 15)
        local fieldColor = colors.red
        if fieldPercent >= 50 then fieldColor = colors.green end
        if fieldPercent < 50 and fieldPercent > 30 then fieldColor = colors.orange end

        local fieldStrengthLabel = "Field Strength"
        if autoInputGate == 1 then
          fieldStrengthLabel = "Field Strength T:" .. targetStrength
        end

        f.draw_text_lr(mon, 2, 14, 1, "Field Strength", fieldPercentText, colors.white, fieldColor, colors.black)
        f.progress_bar(mon, 2, 15, monX-2, fieldPercent, 100, fieldColor, colors.gray)
        previousValues.fieldPercentText = fieldPercentText
      end

      -- Fuel
      local fuelPercentText = fuelPercent .. "%"
      if previousValues.fuelPercentText ~= fuelPercentText then
        f.clear_area(mon, 1, 17, monX, 18)
        local fuelColor = colors.red
        if fuelPercent >= 70 then fuelColor = colors.green end
        if fuelPercent < 70 and fuelPercent > 30 then fuelColor = colors.orange end

        f.draw_text_lr(mon, 2, 17, 1, "Fuel ", fuelPercentText, colors.white, fuelColor, colors.black)
        f.progress_bar(mon, 2, 18, monX-2, fuelPercent, 100, fuelColor, colors.gray)
        previousValues.fuelPercentText = fuelPercentText
      end

      -- Action
      if previousValues.actionText ~= actionText then
        f.clear_area(mon, 1, 19, monX, 19)
        f.draw_text_lr(mon, 2, 19, 1, "Action ", actionText, colors.gray, colors.gray, colors.black)
        previousValues.actionText = actionText
      end
    end

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

    -- Draw UI elements
    for _, element in ipairs(elements) do
      ui.draw(element, mon)
    end

    sleep(0.1)
  end
end

parallel.waitForAny(buttons, update)