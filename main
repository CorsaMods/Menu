local HttpService = game:GetService("HttpService")

local BASE = "https://raw.githubusercontent.com/CorsaMods/Menu/main/"

local function fetch(path)
    return loadstring(game:HttpGet(BASE .. path))()
end

-- Loading screen
local ui = fetch("ui/loading.lua")
ui.show("Loading mod menu...")

-- Load core
local ok, err = pcall(fetch, "loader.lua")
if not ok then
    ui.error("Failed to load: " .. tostring(err))
end
