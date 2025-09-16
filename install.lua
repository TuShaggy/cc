-- drmon installation script
--
local version = "1.0.3"

-- Create lib directory if it doesn't exist
if not fs.exists("lib") then
  fs.makeDir("lib")
end

-- Files to copy
local filesToCopy = {"startup.lua", "README.md", "cc_tweaked_api.md"}

for _, file in ipairs(filesToCopy) do
  print("Installing " .. file .. " from local file system")
  if fs.exists(file) then
    fs.copy(file, "/" .. file)
  else
    print("Error: " .. file .. " not found in the current directory.")
  end
end


-- Create version file
local versionFile = fs.open("version.txt", "w")
if versionFile then
  versionFile.write(version)
  versionFile.close()
end

print("DRMon version " .. version .. " installation complete!")
print("Please reboot the computer by pressing Ctrl+R.")