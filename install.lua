-- drmon installation script
--

local baseURL = "https://raw.githubusercontent.com/TuShaggy/cc/main/"

local files = {
  "startup.lua",
  "lib/f.lua",
  "lib/ui.lua",
  "# Code Citations.md"
}

local function downloadFile(path)
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

for _, path in ipairs(files) do
  downloadFile(path)
end

print("Installation complete!")