local HttpService = game:GetService("HttpService")
local BASE = "https://raw.githubusercontent.com/CorsaMods/Menu/main/"

local function fetch(path)
	return loadstring(game:HttpGet(BASE .. path))()
end

-- Loading screen
local ui = fetch("ui/loading.lua")
_G.ModMenuLoading = ui
ui.show("Loading mod menu...")

-- Fetch manifest
local ok, raw = pcall(function()
	return game:HttpGet(BASE .. "manifest.json")
end)
if not ok then
	ui.error("Failed to fetch manifest")
	return
end

local manifest = HttpService:JSONDecode(raw)
if not manifest or not manifest.builtin then
	ui.error("Invalid manifest")
	return
end

-- Pre-fetch and cache all built-in plugins (no init calls)
local LoadedPlugins = {}
_G.ModMenuPlugins = LoadedPlugins

for _, plugin in ipairs(manifest.builtin) do
	ui.show("Loading " .. plugin.name .. "...")
	local pluginOk, result = pcall(function()
		return loadstring(game:HttpGet(BASE .. "plugins/" .. plugin.file))()
	end)
	if pluginOk and type(result) == "table" then
		LoadedPlugins[plugin.name] = result
		print("Cached: " .. plugin.name)
	else
		warn("Failed to cache: " .. plugin.name)
	end
end

-- Dismiss loading screen and launch menu
ui.dismiss()
fetch("ui/menu.lua")
