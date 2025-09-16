-- drmon installation script
--
local version = "0.39"

local function installFromFileSystem(baseDir)
  local files = {
    "startup.lua",
    "lib/f.lua",
    "lib/ui.lua",
    "# Code Citations.md"
  }

  for _, path in ipairs(files) do
    local fullPath = baseDir .. "/" .. path
    print("Installing " .. path .. " from local file system")
    local f = fs.open(fullPath, "r")
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
      print("Error: Could not open " .. fullPath .. " for reading")
    end
  end
end

print("Enter the base directory where the files are located (e.g., D:/GITHUB/cc):")
local baseDir = read()

print("Loading from local file system: " .. baseDir)
installFromFileSystem(baseDir)
local versionFile = fs.open("version.txt", "w")
if versionFile then
  versionFile.writeLine(version)
  versionFile.close()
else
  print("Error: Could not open version.txt for writing")
end

print("DRMon version " .. version .. " installation complete!")