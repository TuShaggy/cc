-- modifiable variables
local targetStrength = 50
local maxTemperature = 8000
local safeTemperature = 3000
local lowestFieldPercent = 15
local activateOnCharged = 1

-- please leave things untouched from here on
os.loadAPI("lib/f")

local version = "0.26"
local autoInputGate = 1
local curInputGate = 222000

-- monitor 
local mon, monitor, monX, monY

-- peripherals
local reactor
local fluxgate
local inputfluxgate

-- reactor information
local ri

-- last performed action
local action = "None since reboot"
local emergencyCharge = false
local emergencyTemp = false

-- ========================
-- 🔹 DETECCIÓN AUTOMÁTICA
-- ========================
monitor = f.periphSearch("monitor")
reactor = f.periphSearch("draconic_reactor")

-- buscar flow_gates (ATM10 cambia el nombre)
local gates = {}
for _, name in pairs(peripheral.getNames()) do
  if peripheral.getType(name) == "flow_gate" then
    table.insert(gates, name)
  end
end

if #gates < 2 then
  error("Necesitas al menos 2 flow_gate conectados")
end

-- función para elegir en pantalla
local function chooseGate(mon, gates, mensaje)
  f.clear(mon)
  f.draw_text(mon, 2, 2, mensaje, colors.white, colors.black)
  for i, g in ipairs(gates) do
    f.draw_text(mon, 2, 3+i, i..". "..g, colors.yellow, colors.black)
  end

  while true do
    local e, side, x, y = os
