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
  shell.run("wget", url, path)
end

for _, path in ipairs(files) do
  downloadFile(path)
end

print("Installation complete!")