-- drmon installation script
--
local version = "1.0.1"

-- Create lib directory if it doesn't exist
if not fs.exists("lib") then
  fs.makeDir("lib")
end

-- Copy startup.lua
print("Installing startup.lua from local file system")
if fs.exists("startup.lua") then
  fs.copy("startup.lua", "/startup.lua")
else
  print("Error: startup.lua not found in the current directory.")
end

-- Create version file
local versionFile = fs.open("version.txt", "w")
if versionFile then
  versionFile.write(version)
  versionFile.close()
end

print("DRMon version " .. version .. " installation complete!")
print("Please reboot the computer by pressing Ctrl+R.")