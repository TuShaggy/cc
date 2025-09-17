--[[
    Draconic Reactor Control by frostice482
    Version 1.0
    Modified to support multiple peripherals and fluxgates.
--]]

-- Config --
local chargeThreshold = 95 -- percent
local stopThreshold = 25 -- percent
local tempThreshold = 8000 -- degrees C
local fieldThreshold = 10 -- percent
local chargeRate = 900000 -- rf/t for charging
-- End Config --

-- Detect peripherals
local mon, reactor
for _, name in ipairs(peripheral.getNames()) do
  local pType = peripheral.getType(name)
  if not mon and pType == "monitor" then
    mon = peripheral.wrap(name)
  elseif not reactor and pType == "draconic_reactor" then
    reactor = peripheral.wrap(name)
  end
end

if not mon then error("No monitor found!") end
if not reactor then error("No reactor found!") end

-- Detect fluxgates
local fluxgateNames = {}
for _, name in ipairs(peripheral.getNames()) do
  if peripheral.getType(name) == "flow_gate" then
    table.insert(fluxgateNames, name)
  end
end

if #fluxgateNames < 2 then error("At least two fluxgates are required") end

local function selectFluxgates()
  mon.clear()
  mon.setCursorPos(1, 2)
  mon.write("Select INPUT Fluxgate")
  for i, name in ipairs(fluxgateNames) do
    mon.setCursorPos(2, 4 + i)
    mon.write(i .. ". " .. name)
  end

  local selectedInput = nil
  while not selectedInput do
    local event, side, xPos, yPos = os.pullEvent("monitor_touch")
    for i, name in ipairs(fluxgateNames) do
      if yPos == 4 + i then
        selectedInput = i
        mon.setCursorPos(25, 4 + i)
        mon.write("<- INPUT")
        sleep(0.5)
      end
    end
  end

  mon.clear()
  mon.setCursorPos(1, 2)
  mon.write("Select OUTPUT Fluxgate")
  for i, name in ipairs(fluxgateNames) do
    mon.setCursorPos(2, 4 + i)
    mon.write(i .. ". " .. name)
    if i == selectedInput then
      mon.setCursorPos(25, 4 + i)
      mon.write("<- INPUT")
    end
  end

  local selectedOutput = nil
  while not selectedOutput do
    local event, side, xPos, yPos = os.pullEvent("monitor_touch")
    for i, name in ipairs(fluxgateNames) do
      if yPos == 4 + i and i ~= selectedInput then
        selectedOutput = i
        mon.setCursorPos(25, 4 + i)
        mon.write("<- OUTPUT")
        sleep(0.5)
      end
    end
  end

  return selectedInput, selectedOutput
end

local inputIdx, outputIdx = selectFluxgates()
local inputGate = peripheral.wrap(fluxgateNames[inputIdx])
local outputGate = peripheral.wrap(fluxgateNames[outputIdx])

if not inputGate then error("Invalid input fluxgate selected") end
if not outputGate then error("Invalid output fluxgate selected") end

local function draw()
    mon.clear()
    mon.setCursorPos(1, 1)
    local reactorInfo = reactor.getReactorInfo()
    local status = reactorInfo.status
    local temp = reactorInfo.temperature
    local field = reactorInfo.fieldStrength
    local maxField = reactorInfo.maxFieldStrength
    local energy = reactorInfo.energySaturation
    local maxEnergy = reactorInfo.maxEnergySaturation
    local fieldPercent = (field / maxField) * 100
    local energyPercent = (energy / maxEnergy) * 100

    mon.write("Draconic Reactor Control\n")
    mon.write("Status: " .. status .. "\n")
    mon.write("Temp: " .. string.format("%.0f", temp) .. " C\n")
    mon.write("Field: " .. string.format("%.2f", fieldPercent) .. "%\n")
    mon.write("Energy: " .. string.format("%.2f", energyPercent) .. "%\n")
end

local function main()
    while true do
        local reactorInfo = reactor.getReactorInfo()
        local status = reactorInfo.status
        local temp = reactorInfo.temperature
        local field = reactorInfo.fieldStrength
        local maxField = reactorInfo.maxFieldStrength
        local energy = reactorInfo.energySaturation
        local maxEnergy = reactorInfo.maxEnergySaturation
        local fieldPercent = (field / maxField) * 100
        local energyPercent = (energy / maxEnergy) * 100

        if status == "offline" and energyPercent < stopThreshold then
            reactor.charge()
        elseif status == "offline" and energyPercent >= chargeThreshold then
            reactor.activate()
        elseif status == "online" and energyPercent >= chargeThreshold then
            reactor.stop()
        elseif status == "online" and temp >= tempThreshold then
            reactor.stop()
        elseif status == "online" and fieldPercent <= fieldThreshold then
            reactor.stop()
        end

        -- Fluxgate control logic
        if status == "charging" then
            inputGate.setSignalLowFlow(chargeRate)
            outputGate.setSignalLowFlow(0)
        elseif status == "online" then
            inputGate.setSignalLowFlow(0)
            outputGate.setSignalLowFlow(reactorInfo.generationRate * 1.1) -- Open output gate
        else -- offline, stopping, etc.
            inputGate.setSignalLowFlow(0)
            outputGate.setSignalLowFlow(0)
        end

        draw()
        sleep(1)
    end
end

main()