local HttpService = game:GetService("HttpService")
local BASE = "https://raw.githubusercontent.com/CorsaMods/Menu/main/"

local function fetch(path)
	return loadstring(game:HttpGet(BASE .. path))()
end

-- Loading screen
local ui = fetch("ui/loading.lua")
_G.ModMenuLoading = ui
ui.show("Loading mod menu...")

-- Absolute safety net: no matter what happens below, dismiss after 12s
task.delay(12, function()
	if _G.ModMenuLoading then
		_G.ModMenuLoading.dismiss()
		_G.ModMenuLoading = nil
	end
end)

-- Load core
local ok, err = pcall(fetch, "loader.lua")
if not ok then
	warn("[ModMenu] loader.lua failed: " .. tostring(err))
	ui.error("Failed to load: " .. tostring(err))
	-- still dismiss after showing the error for 3s
	task.delay(3, function()
		if _G.ModMenuLoading then
			_G.ModMenuLoading.dismiss()
			_G.ModMenuLoading = nil
		end
	end)
end
