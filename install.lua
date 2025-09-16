-- Instalador CC-Draconic (Auto Update)
-- Descarga todo el repo de GitHub automáticamente
-- Repo: https://github.com/TuShaggy/cc

local owner = "TuShaggy"
local repo = "cc"
local branch = "main"

local apiURL = "https://api.github.com/repos/"..owner.."/"..repo.."/contents"
local rawURL = "https://raw.githubusercontent.com/"..owner.."/"..repo.."/"..branch.."/"

-- Función recursiva para listar archivos del repo
local function fetchFiles(path, fileList)
  local url = apiURL
  if path ~= "" then url = url.."/"..path end
  local res = http.get(url)
  if not res then
    print("Error al acceder a "..url)
    return
  end
  local data = textutils.unserialiseJSON(res.readAll())
  res.close()

  for _, item in ipairs(data) do
    if item.type == "file" then
      table.insert(fileList, item.path)
    elseif item.type == "dir" then
      fetchFiles(item.path, fileList)
    end
  end
end

-- 🔹 obtener lista de archivos del repo
local files = {}
fetchFiles("", files)

-- 🔹 borrar antiguos archivos (menos este instalador)
print("Borrando archivos antiguos...")
for _, f in ipairs(files) do
  if fs.exists(f) and not f:find("install.lua") then
    fs.delete(f)
  end
end
if fs.exists("lib") == false then fs.makeDir("lib") end

-- 🔹 descargar todos los archivos
for _, f in ipairs(files) do
  if not f:find("install.lua") then
    print("Descargando "..f.." ...")
    local h = http.get(rawURL..f)
    if h then
      local content = h.readAll()
      h.close()
      local dir = f:match("(.+)/[^/]+$")
      if dir and not fs.exists(dir) then fs.makeDir(dir) end
      local fh = fs.open(f, "w")
      fh.write(content)
      fh.close()
      print(" -> OK")
    else
      print(" -> ERROR: "..f)
    end
  end
end

print("Instalación completada. Reinicia con 'reboot'.")
