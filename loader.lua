local HttpService = game:GetService("HttpService")
local BASE = "https://raw.githubusercontent.com/CorsaMods/Menu/main/"

-- Fetch plugin manifest
local raw = game:HttpGet(BASE .. "manifest.json")
local manifest = game:GetService("HttpService"):JSONDecode(raw)

local LoadedPlugins = {}

local function loadPlugin(url, name)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if ok and type(result) == "table" and result.init then
        LoadedPlugins[name] = result
        result.init()
    else
        warn("[ModMenu] Failed to load plugin: " .. name)
    end
end

-- Load built-in plugins
for _, plugin in ipairs(manifest.builtin) do
    loadPlugin(BASE .. "plugins/" .. plugin.file, plugin.name)
end

-- Load menu UI
loadstring(game:HttpGet(BASE .. "ui/menu.lua"))()
