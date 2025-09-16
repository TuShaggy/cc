-- drmon installation script
--
local version = "0.42"

local function installFromFileSystem()
  local files = {
    "startup.lua",
    "lib/f.lua",
    "lib/ui.lua",
    "# Code Citations.md"
  }

  for _, path in ipairs(files) do
    print("Installing " .. path .. " from local file system")
    local f = fs.open(path, "r")
    if f then
      local content = f.readAll()
      f.close()

      local outFile = fs.open(path, "w")
      if outFile then
        outFile.write(content)
        outFile.close()
      else
        print("Error: Could not open " .. path .. " for writing")
      end
    else
      print("Error: Could not open " .. path .. " for reading")
    end
  end
end

print("Loading from local file system")
installFromFileSystem()
local versionFile = fs.open("version.txt", "w")
if versionFile then
  versionFile.writeLine(version)
  versionFile.close()
else
  print("Error: Could not open version.txt for writing")
end

print("DRMon version " .. version .. " installation complete!")