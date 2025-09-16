-- drmon installation script
--
local version = "1.0.5"
local repoBaseUrl = "https://raw.githubusercontent.com/TuShaggy/cc/main/"

local filesToDownload = {
  "startup.lua",
  "README.md",
  "cc_tweaked_api.md"
}

-- Function to download a file
local function download(file)
  print("Downloading " .. file .. "...")
  local url = repoBaseUrl .. file
  local response = http.get(url)
  if response then
    local content = response.readAll()
    response.close()
    local f = fs.open(file, "w")
    if f then
      f.write(content)
      f.close()
      print(file .. " downloaded successfully.")
    else
      print("Error: Could not write to " .. file)
    end
  else
    print("Error: Could not download " .. file)
  end
end

-- Download all files
for _, file in ipairs(filesToDownload) do
  download(file)
end

-- Set the downloaded startup script to run on boot
if fs.exists("startup.lua") then
    shell.run("cp startup.lua /startup")
end

-- Create version file
local versionFile = fs.open("version.txt", "w")
if versionFile then
  versionFile.write(version)
  versionFile.close()
end

print("DRMon version " .. version .. " installation complete!")
print("Please reboot the computer by pressing Ctrl+R.")