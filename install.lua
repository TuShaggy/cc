-- drmon installation script
--
--

local libURL = "https://raw.githubusercontent.com/TuShaggy/cc/refs/heads/main/lib/f.lua"
local startupURL = "https://raw.githubusercontent.com/TuShaggy/cc/refs/heads/main/startup.lua"
local lib, startup
local libFile, startupFile

fs.makeDir("lib")

lib = http.get(libURL)
if lib then
  libFile = lib.readAll()
  local file1 = fs.open("lib/f.lua", "w")
  if file1 then
    file1.write(libFile)
    file1.close()
  else
    print("Error: Could not open lib/f.lua for writing")
  end
  lib.close()
else
  print("Error: Could not download lib/f.lua")
end

startup = http.get(startupURL)
if startup then
  startupFile = startup.readAll()
  local file2 = fs.open("startup", "w")
  if file2 then
    file2.write(startupFile)
    file2.close()
  else
    print("Error: Could not open startup for writing")
  end
  startup.close()
else
  print("Error: Could not download startup")
end