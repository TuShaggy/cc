-- drmon installation script
--

local repoURL = "https://api.github.com/repos/TuShaggy/cc/contents"
local baseURL = "https://raw.githubusercontent.com/TuShaggy/cc/main/"

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

local function installFromGithub()
  local json = http.get(repoURL)
  if json then
    local content = textutils.jsonDecode(json.readAll())
    json.close()

    for _, file in ipairs(content) do
      if file.type == "file" then
        downloadFile(file.path)
      elseif file.type == "dir" then
        fs.makeDir(file.path)
      end
    end
  else
    print("Error: Could not connect to GitHub API")
  end
end

installFromGithub()
print("Installation complete!")