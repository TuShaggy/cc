-- Instalador CC-Draconic (Full Update)
-- Repo: https://github.com/TuShaggy/cc

local repo = "https://raw.githubusercontent.com/TuShaggy/cc/main/"
local files = {
  "lib/f.lua",
  "startup.lua",
}

-- 🔹 borrar antiguos archivos
print("Borrando archivos antiguos...")
if fs.exists("lib") then fs.delete("lib") end
if fs.exists("startup.lua") then fs.delete("startup.lua") end
-- NOTA: no borramos install.lua para no autodestruirnos

-- 🔹 crear directorios necesarios
fs.makeDir("lib")

-- 🔹 descargar todos los archivos de la lista
for _, file in ipairs(files) do
  local url = repo .. file
  local localPath = file
  print("Descargando " .. file .. " ...")
  local h = http.get(url)
  if h then
    local content = h.readAll()
    h.close()
    local f = fs.open(localPath, "w")
    f.write(content)
    f.close()
    print(" -> OK")
  else
    print(" -> ERROR al descargar: " .. url)
  end
end

print("Instalación completada. Reinicia con 'reboot'.")
