-- custom plugin loader logic
local function loadCustomPlugin(url)
    if not url or url == "" then return end
    
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if ok and type(result) == "table" then
        if result.init then result.init() end
        print("Custom plugin loaded: " .. (result.name or "Unknown"))
    else
        warn("Custom plugin failed or returned invalid format")
    end
end
