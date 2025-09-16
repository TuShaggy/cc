--[[
  DRMon - Draconic Reactor Monitor
  Version 1.0.0
  Based on original work by acidjazz, HollowWaka, and others.
]]

--#region Helper Functions (from f.lua and ui.lua)

local f = {}
local ui = {}

-- formatting
function f.format_int(number)
    if number == nil then number = 0 end
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1,")
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

-- monitor related
function f.draw_text(mon, x, y, text, text_color, bg_color)
  if not mon then return end
  mon.setBackgroundColor(bg_color)
  mon.setTextColor(text_color)
  mon.setCursorPos(x,y)
  mon.write(text)
end

function f.draw_text_right(mon, offset, y, text, text_color, bg_color)
  if not mon then return end
  local monX_size = mon.getSize()
  mon.setBackgroundColor(bg_color)
  mon.setTextColor(text_color)
  mon.setCursorPos(monX_size-string.len(tostring(text))-offset, y)
  mon.write(text)
end

function f.draw_text_lr(mon, x, y, offset, text1, text2, text1_color, text2_color, bg_color)
    f.draw_text(mon, x, y, text1, text1_color, bg_color)
    f.draw_text_right(mon, offset, y, text2, text2_color, bg_color)
end

function f.progress_bar(mon, x, y, length, minVal, maxVal, bar_color, bg_color)
  if not mon then return end
  mon.setBackgroundColor(bg_color)
  mon.setCursorPos(x,y)
  mon.write(string.rep(" ", length))
  local barSize = math.floor((minVal/maxVal) * length)
  mon.setBackgroundColor(bar_color)
  mon.setCursorPos(x,y)
  mon.write(string.rep(" ", barSize))
end

function f.clear(mon)
  if not mon then return end
  mon.setBackgroundColor(colors.black)
  mon.clear()
  mon.setCursorPos(1,1)
end

function f.clear_area(mon, x1, y1, x2, y2)
  if not mon then return end
  mon.setBackgroundColor(colors.black)
  for y = y1, y2 do
    mon.setCursorPos(x1, y)
    mon.write(string.rep(" ", x2 - x1 + 1))
  end
end

-- UI element creation functions
function ui.button(x, y, width, height, text, callback)
  return { type = "button", x = x, y = y, width = width, height = height, text = text, callback = callback }
end

function ui.label(x, y, text)
  return { type = "label", x = x, y = y, text = text }
end

-- UI rendering functions
function ui.draw(element, mon)
  if element.type == "button" then
    f.draw_text(mon, element.x, element.y, string.rep(" ", element.width), colors.white, colors.gray)
    f.draw_text(mon, element.x + 1, element.y + math.floor(element.height/2), element.text, colors.white, colors.gray)
  elseif element.type == "label" then
    f.draw_text(mon, element.x, element.y, element.text, colors.white, colors.black)
  end
end

-- Event handling
function ui.handleClick(x, y, elements)
  for _, element in ipairs(elements) do
    if element.type == "button" and x >= element.x and x < element.x + element.width and y >= element.y and y < element.y + element.height then
      if element.callback then element.callback() end
      return true
    end
  end
  return false
end

-- Layout functions
function ui.center(mon_width, element_width)
  return math.floor(mon_width / 2 - element_width / 2)
end

--#endregion

--#region Main Script

-- modifiable variables
local targetStrength = 50
local maxTemperature = 8000
local safeTemperature = 3000
local lowestFieldPercent = 15
local activateOnCharged = 1

-- program variables
local version = "1.0.0"
local autoInputGate = 1
local curInputGate = 222000

-- Detect peripherals
local monitor, reactor, speaker
for _, name in ipairs(peripheral.getNames()) do
  local pType = peripheral.getType(name)
  if not monitor and pType == "monitor" then
    monitor = peripheral.wrap(name)
  elseif not reactor and pType == "draconic_reactor" then
    reactor = peripheral.wrap(name)
  elseif not speaker and pType == "speaker" then
    speaker = peripheral.wrap(name)
  end
end

-- Detect fluxgates
local fluxgateNames = {}
for _, name in ipairs(peripheral.getNames()) do
  if peripheral.getType(name) == "flow_gate" then
    table.insert(fluxgateNames, name)
  end
end

if not monitor then error("No valid monitor was found") end
if not reactor then error("No valid draconic reactor was found") end
if #fluxgateNames < 2 then error("At least two fluxgates are required") end

local mon = monitor
local monX, monY = mon.getSize()

local action = "None since reboot"
local emergencyCharge = false
local emergencyTemp = false

local function selectFluxgates()
  f.clear(mon)
  f.draw_text(mon, 2, 2, "Select INPUT Fluxgate", colors.white, colors.black)
  for i, name in ipairs(fluxgateNames) do
    f.draw_text(mon, 2, 4 + i, i .. ". " .. name, colors.white, colors.gray)
  end

  local selectedInput = nil
  while not selectedInput do
    local event, side, xPos, yPos = os.pullEvent("monitor_touch")
    for i, name in ipairs(fluxgateNames) do
      if yPos == 4 + i then
        selectedInput = i
        f.draw_text(mon, 25, 4 + i, "<- INPUT", colors.green, colors.black)
        sleep(0.5)
      end
    end
  end

  f.clear(mon)
  f.draw_text(mon, 2, 2, "Select OUTPUT Fluxgate", colors.white, colors.black)
  for i, name in ipairs(fluxgateNames) do
    f.draw_text(mon, 2, 4 + i, i .. ". " .. name, colors.white, colors.gray)
    if i == selectedInput then
      f.draw_text(mon, 25, 4 + i, "<- INPUT", colors.green, colors.black)
    end
  end

  local selectedOutput = nil
  while not selectedOutput do
    local event, side, xPos, yPos = os.pullEvent("monitor_touch")
    for i, name in ipairs(fluxgateNames) do
      if yPos == 4 + i and i ~= selectedInput then
        selectedOutput = i
        f.draw_text(mon, 25, 4 + i, "<- OUTPUT", colors.blue, colors.black)
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

if not fluxgate then error("No valid output fluxgate was found") end
if not inputfluxgate then error("No valid input fluxgate was found") end

function save_config()
  local sw = fs.open("config.txt", "w")
  if sw then
    sw.writeLine(version)
    sw.writeLine(autoInputGate)
    sw.writeLine(curInputGate)
    sw.close()
  end
end

function load_config()
  if fs.exists("config.txt") then
    local sr = fs.open("config.txt", "r")
    if sr then
      local file_version = sr.readLine() -- version is for future use
      autoInputGate = tonumber(sr.readLine())
      curInputGate = tonumber(sr.readLine())
      sr.close()
    end
  else
    save_config()
  end
end

load_config()

local function toggleAutoInputGate()
  if autoInputGate == 1 then autoInputGate = 0 else autoInputGate = 1 end
  save_config()
end

local function increaseInputGate()
  if autoInputGate == 0 then -- Only allow changes in manual mode
    curInputGate = curInputGate + 1000
    save_config()
  end
end

local function decreaseInputGate()
  if autoInputGate == 0 then -- Only allow changes in manual mode
    curInputGate = curInputGate - 1000
    if curInputGate < 0 then curInputGate = 0 end -- Prevent negative values
    save_config()
  end
end

-- UI elements
local elements = {
  ui.button(ui.center(monX, 6), 10, 6, 1, "AU/MA", toggleAutoInputGate),
  ui.button(ui.center(monX, 6) - 4, 10, 3, 1, "-", decreaseInputGate),
  ui.button(ui.center(monX, 6) + 7, 10, 3, 1, "+", increaseInputGate),
}

function buttons()
  while true do
    local event, side, xPos, yPos = os.pullEvent("monitor_touch")
    ui.handleClick(xPos, yPos, elements)
  end
end

local previousValues = {}
local lastUpdate = 0
local criticalUpdateInterval = 0.1
local normalUpdateInterval = 0.3

function update()
  local lastCriticalUpdate = 0
  local fuelPercent, fieldPercent, satPercent -- Declare variables at a higher scope

  while true do
    local currentTime = os.time()
    local ri = reactor.getReactorInfo()
    if not ri then error("Reactor has an invalid setup") end

    -- Critical updates (every 0.1s)
    if currentTime - lastCriticalUpdate >= criticalUpdateInterval then
      local temperature = f.format_int(ri.temperature) .. "C"
      if previousValues.temperature ~= temperature then
        local tempColor = colors.red
        if ri.temperature <= 5000 then tempColor = colors.green
        elseif ri.temperature <= 6500 then tempColor = colors.orange end
        f.clear_area(mon, 1, 6, monX, 6)
        f.draw_text_lr(mon, 2, 6, 1, "Temperature", temperature, colors.white, tempColor, colors.black)
        previousValues.temperature = temperature
      end
      lastCriticalUpdate = currentTime
    end

    -- Normal updates (every 0.3s)
    if currentTime - lastUpdate >= normalUpdateInterval then
      local status = string.upper(ri.status)
      if previousValues.status ~= status then
        local statusColor = colors.red
        if ri.status == "online" or ri.status == "charged" then statusColor = colors.green
        elseif ri.status == "offline" then statusColor = colors.gray
        elseif ri.status == "charging" then statusColor = colors.orange end
        f.clear_area(mon, 1, 2, monX, 2)
        f.draw_text_lr(mon, 2, 2, 1, "Reactor Status", status, colors.white, statusColor, colors.black)
        previousValues.status = status
      end

      local generationRate = f.format_int(ri.generationRate) .. " rf/t"
      if previousValues.generationRate ~= generationRate then
        f.clear_area(mon, 1, 4, monX, 4)
        f.draw_text_lr(mon, 2, 4, 1, "Generation", generationRate, colors.white, colors.lime, colors.black)
        previousValues.generationRate = generationRate
      end

      -- Display manual gate setting when in manual mode
      if autoInputGate == 0 then
        local manualGateText = "Manual Gate: " .. f.format_int(curInputGate)
        if previousValues.manualGateText ~= manualGateText then
          f.clear_area(mon, 1, 9, monX, 9)
          f.draw_text(mon, 2, 9, manualGateText, colors.white, colors.black)
          previousValues.manualGateText = manualGateText
        end
      else
        -- Clear manual gate text if switching back to auto
        if previousValues.manualGateText then
          f.clear_area(mon, 1, 9, monX, 9)
          previousValues.manualGateText = nil
        end
      end

      satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000) * 0.01
      local satPercentText = satPercent .. "%"
      if previousValues.satPercentText ~= satPercentText then
        f.clear_area(mon, 1, 11, monX, 12)
        f.draw_text_lr(mon, 2, 11, 1, "Energy Saturation", satPercentText, colors.white, colors.white, colors.black)
        f.progress_bar(mon, 2, 12, monX - 2, satPercent, 100, colors.blue, colors.gray)
        previousValues.satPercentText = satPercentText
      end

      fieldPercent = math.ceil(ri.fieldStrength / ri.maxFieldStrength * 10000) * 0.01
      local fieldPercentText = fieldPercent .. "%"
      if previousValues.fieldPercentText ~= fieldPercentText then
        local fieldColor = colors.red
        if fieldPercent >= 50 then fieldColor = colors.green
        elseif fieldPercent > 30 then fieldColor = colors.orange end
        local fieldLabel = autoInputGate == 1 and "Field Strength T:" .. targetStrength or "Field Strength"
        f.clear_area(mon, 1, 14, monX, 15)
        f.draw_text_lr(mon, 2, 14, 1, fieldLabel, fieldPercentText, colors.white, fieldColor, colors.black)
        f.progress_bar(mon, 2, 15, monX - 2, fieldPercent, 100, fieldColor, colors.gray)
        previousValues.fieldPercentText = fieldPercentText
      end

      fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 10000) * 0.01
      local fuelPercentText = fuelPercent .. "%"
      if previousValues.fuelPercentText ~= fuelPercentText then
        local fuelColor = colors.red
        if fuelPercent >= 70 then fuelColor = colors.green
        elseif fuelPercent > 30 then fuelColor = colors.orange end
        f.clear_area(mon, 1, 17, monX, 18)
        f.draw_text_lr(mon, 2, 17, 1, "Fuel", fuelPercentText, colors.white, fuelColor, colors.black)
        f.progress_bar(mon, 2, 18, monX - 2, fuelPercent, 100, fuelColor, colors.gray)
        previousValues.fuelPercentText = fuelPercentText
      end

      if previousValues.actionText ~= action then
        f.clear_area(mon, 1, 19, monX, 19)
        f.draw_text_lr(mon, 2, 19, 1, "Action:", action, colors.gray, colors.gray, colors.black)
        previousValues.actionText = action
      end

      -- Draw static UI elements
      for _, element in ipairs(elements) do ui.draw(element, mon) end
      lastUpdate = currentTime
    end

    -- Reactor control logic
    if emergencyCharge then reactor.chargeReactor() end
    if ri.status == "charging" then
      inputfluxgate.setSignalLowFlow(900000)
      emergencyCharge = false
    end
    if emergencyTemp and ri.status == "stopping" and ri.temperature < safeTemperature then
      reactor.activateReactor()
      emergencyTemp = false
    end
    if ri.status == "charged" and activateOnCharged == 1 then
      reactor.activateReactor()
    end
    if ri.status == "online" then
      if autoInputGate == 1 then
        -- Auto-mode for input gate (field strength)
        local fluxval = ri.fieldDrainRate / (1 - (targetStrength / 100))
        inputfluxgate.setSignalLowFlow(fluxval)

        -- Auto-mode for output gate (energy saturation)
        if satPercent > 80 then
          fluxgate.setSignalLowFlow(ri.generationRate * 1.1) -- Increase output if saturation is high
        elseif satPercent < 70 then
          fluxgate.setSignalLowFlow(ri.generationRate * 0.9) -- Decrease output if saturation is low
        else
          fluxgate.setSignalLowFlow(ri.generationRate) -- Stabilize output
        end
      else
        -- Manual mode
        inputfluxgate.setSignalLowFlow(curInputGate)
        -- In manual mode, output gate is not controlled by this script
      end
    end
    if fuelPercent and fuelPercent <= 10 then
      reactor.stopReactor()
      action = "Fuel low, refuel"
      if speaker then speaker.playSound("minecraft:block.note_block.bass", 3, 1) end
    end
    if fieldPercent and fieldPercent <= lowestFieldPercent and ri.status == "online" then
      action = "Field < " .. lowestFieldPercent .. "%"
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

    sleep(0.1)
  end
end

parallel.waitForAny(buttons, update)

--#endregion