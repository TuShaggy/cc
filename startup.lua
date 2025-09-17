--[[
    Draconic Reactor Control by frostice482
    Version 1.0
--]]

-- Config --
local chargeThreshold = 95 -- percent
local stopThreshold = 25 -- percent
local tempThreshold = 8000 -- degrees C
local fieldThreshold = 10 -- percent
-- End Config --

local mon = peripheral.find("monitor")
local reactor = peripheral.find("draconic_reactor")

if not mon then
    error("No monitor found!")
end
if not reactor then
    error("No reactor found!")
end

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
        draw()
        sleep(1)
    end
end

main()