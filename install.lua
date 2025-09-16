-- drmon installation script
--
local version = "0.37"

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

local function installFromGithub()
    local baseURL = "https://raw.githubusercontent.com/TuShaggy/cc/main/"
    local files = {
      "startup.lua",
      "lib/f.lua",
      "lib/ui.lua",
      "# Code Citations.md"
    }
  
    for _, path in ipairs(files) do
      local url = baseURL .. path
      print("Downloading " .. path .. " from " .. url)
      local file = http.get(url)
      if file then
        local content = file.readAll()
        local f = fs.open(path, "w")
        if f then
          f.write(content)
          f.close()
        else
          print("Error: Could not open " .. path .. " for writing")
        end
        file.close()
      else
        print("Error: Could not download " .. path)
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
      local versionFile = fs.open("version.txt", "w")
      if versionFile then
        versionFile.writeLine(version)
        versionFile.close()
        print("Update complete!")
      else
        print("Error: Could not open version.txt for writing")
      end
    else
      print("Version " .. version .. " is already installed")
    end
  else
    print("Error: Could not open version.txt for reading")
  end
else
  print("First install, loading from GitHub")
  installFromGithub()
  local versionFile = fs.open("version.txt", "w")
  if versionFile then
    versionFile.writeLine(version)
    versionFile.close()
  else
    print("Error: Could not open version.txt for writing")
  end
end

print("DRMon version " .. version .. " installation complete!")