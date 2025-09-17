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

--#endregion

--#region Main Script

-- modifiable variables
local targetStrength = 50
local maxTemperature = 8000
local safeTemperature = 3000
local lowestFieldPercent = 15
local activateOnCharged = 1

-- program variables
local version = "1.4.0"

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

local previousValues = {}
local criticalUpdateInterval = 0.1
local normalUpdateInterval = 0.3

-- Global variables for display
local g_ri, g_satPercent, g_fieldPercent, g_fuelPercent = {}, 0, 0, 0
local g_inputFlux, g_outputFlux = 0, 0

function drawScreen()
  -- Simplified debug screen
  while true do
    mon.clear()
    mon.setCursorPos(1, 1)
    term.redirect(mon)

    print("--- DRMon Debug ---")
    if g_ri and g_ri.status then
      print("Action: " .. tostring(action))
      print("Status: " .. tostring(g_ri.status))
      print("Temp: " .. tostring(g_ri.temperature))
      print("Saturation: " .. string.format("%.2f", g_satPercent) .. "%")
      print("Field: " .. string.format("%.2f", g_fieldPercent) .. "%")
      print("Fuel: " .. string.format("%.2f", g_fuelPercent) .. "%")
      print("Input Flux: " .. f.format_int(g_inputFlux))
      print("Output Flux: " .. f.format_int(g_outputFlux))
      print("Emergency Charge: " .. tostring(emergencyCharge))
    else
      print("Waiting for reactor data...")
    end

    term.restore()
    sleep(0.5) -- Update debug screen twice per second
  end
end

function controlReactor()
  local targetSaturation = 75 -- Target for energy saturation
  local Kp = 2 -- Proportional gain for output control

  while true do
    g_ri = reactor.getReactorInfo()

    if g_ri then
      -- Calculate current stats
      g_satPercent = (g_ri.energySaturation / g_ri.maxEnergySaturation) * 100
      g_fieldPercent = (g_ri.fieldStrength / g_ri.maxFieldStrength) * 100
      g_fuelPercent = 100 - (g_ri.fuelConversion / g_ri.maxFuelConversion) * 100

      -- Default flux values to safe state (off)
      g_inputFlux = 0
      g_outputFlux = 0

      -- Determine action based on priority
      if g_ri.temperature > maxTemperature then
        action = "EMERGENCY: Temp High"
        reactor.stopReactor()
        emergencyTemp = true
        if speaker then speaker.playSound("minecraft:block.note_block.bass", 3, 1) end
      elseif g_fuelPercent <= 10 then
        action = "EMERGENCY: Fuel Low"
        reactor.stopReactor()
        if speaker then speaker.playSound("minecraft:block.note_block.bass", 3, 1) end
      elseif g_fieldPercent <= lowestFieldPercent and g_ri.status == "online" then
        action = "EMERGENCY: Field Low"
        reactor.stopReactor()
        emergencyCharge = true
        if speaker then speaker.playSound("minecraft:block.note_block.bass", 3, 1) end
      elseif g_ri.status == "online" then
        action = "Running"
        emergencyCharge = false
        emergencyTemp = false
        -- Input gate control
        g_inputFlux = g_ri.fieldDrainRate / (1 - (targetStrength / 100))
        -- Output gate control
        local error = g_satPercent - targetSaturation
        local outputFactor = 1 + (Kp * error / 100)
        g_outputFlux = g_ri.generationRate * outputFactor
        g_outputFlux = math.max(0, g_outputFlux)
      elseif g_ri.status == "charging" then
        action = "Charging"
        g_inputFlux = 900000
        emergencyCharge = false
      elseif g_ri.status == "charged" and activateOnCharged == 1 then
        action = "Activating"
        reactor.activateReactor()
      elseif (g_ri.status == "offline" or g_ri.status == "stopping") and (g_ri.energySaturation < g_ri.maxEnergySaturation or emergencyCharge) then
        action = "Requesting Charge"
        reactor.chargeReactor()
      else
        action = "Idle"
      end

      -- Apply calculated flux values
      inputfluxgate.setSignalLowFlow(g_inputFlux)
      fluxgate.setSignalLowFlow(g_outputFlux)
    else
      action = "Reactor connection lost!"
      g_inputFlux, g_outputFlux = 0, 0
      inputfluxgate.setSignalLowFlow(0)
      fluxgate.setSignalLowFlow(0)
      sleep(1) -- Wait before retrying
    end
    sleep(0.1)
  end
end

-- Initial data fetch to prevent blank screen
g_ri = reactor.getReactorInfo()
if not g_ri then g_ri = {
  status = "offline", temperature = 0, generationRate = 0,
  energySaturation = 0, maxEnergySaturation = 1,
  fieldStrength = 0, maxFieldStrength = 1,
  fuelConversion = 0, maxFuelConversion = 1
} end

parallel.waitForAll(drawScreen, controlReactor)

--#endregion