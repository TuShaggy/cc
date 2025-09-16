-- drmon installation script
--
local version = "0.29"

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
      print("Attempting to download from GitHub...")
      local baseURL = "https://raw.githubusercontent.com/TuShaggy/cc/main/"
      local url = baseURL .. path
      local webFile = http.get(url)
      if webFile then
        local content = webFile.readAll()
        webFile.close()
        local outFile = fs.open(path, "w")
        if outFile then
          outFile.write(content)
          outFile.close()
        else
          print("Error: Could not open " .. path .. " for writing")
        end
      else
        print("Error: Could not download " .. path .. " from GitHub")
      end
    end
  end
end

if fs.exists("version.txt") then
  print("Loading from local file system")
  installFromFileSystem()
  local versionFile = fs.open("version.txt", "r")
  if versionFile then
    local installedVersion = versionFile.readLine()
    versionFile.close()

    if installedVersion ~= version then
      print("Version mismatch: Installed version is " .. installedVersion .. ", expected version is " .. version)
      print("Updating to latest version...")
      installFromFileSystem()
      versionFile = fs.open("version.txt", "w")
      versionFile.writeLine(version)
      versionFile.close()
      print("Update complete!")
    else
      print("Version " .. version .. " is already installed")
    end
  else
    print("Error: Could not open version.txt for reading")
  end
else
  print("First install, loading from local file system")
  installFromFileSystem()
  local versionFile = fs.open("version.txt", "w")
  versionFile.writeLine(version)
  versionFile.close()
end

print("DRMon version " .. version .. " installation complete!")