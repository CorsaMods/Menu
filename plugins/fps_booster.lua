local plugin = {
	name = "FPS Booster",
	version = "1.0",
	author = "you"
}

function plugin.init()
	local RunService       = game:GetService("RunService")
	local Players          = game:GetService("Players")
	local Lighting         = game:GetService("Lighting")
	local RenderSettings   = settings():GetService("RenderSettings")
	local ContentProvider  = game:GetService("ContentProvider")

	local plr      = Players.LocalPlayer
	local camera   = workspace.CurrentCamera

	-- ============================================================
	-- STORE ORIGINALS so destroy() can restore them
	-- ============================================================
	local originals = {
		-- Lighting
		GlobalShadows        = Lighting.GlobalShadows,
		FogEnd               = Lighting.FogEnd,
		FogStart             = Lighting.FogStart,

		-- RenderSettings
		QualityLevel         = RenderSettings.QualityLevel,
		MeshPartDetailLevel  = RenderSettings.MeshPartDetailLevel,
		EnableFRM            = RenderSettings.EnableFRM,

		-- Camera
		FieldOfView          = camera.FieldOfView,
	}

	-- store all PostEffects/SkyBoxes we disable so we can re-enable them
	local disabledEffects = {}

	-- ============================================================
	-- APPLY BOOSTS
	-- ============================================================

	-- Lighting tweaks
	Lighting.GlobalShadows = false
	Lighting.FogEnd        = 10000
	Lighting.FogStart      = 10000

	-- Disable all post-processing effects (bloom, blur, color correction etc.)
	for _, effect in ipairs(Lighting:GetChildren()) do
		if effect:IsA("PostEffect") or effect:IsA("Sky") then
			if effect.Enabled ~= nil then
				table.insert(disabledEffects, { obj = effect, wasEnabled = effect.Enabled })
				effect.Enabled = false
			end
		end
	end

	-- Also disable any BlurEffects specifically named ModMenuBlur (loading screen safety)
	for _, effect in ipairs(Lighting:GetChildren()) do
		if effect:IsA("BlurEffect") and effect.Name == "ModMenuBlur" then
			effect.Enabled = false
		end
	end

	-- RenderSettings
	RenderSettings.QualityLevel        = Enum.QualityLevel.Level01
	RenderSettings.MeshPartDetailLevel = Enum.NormalId.Top  -- lowest LOD
	RenderSettings.EnableFRM           = true               -- dynamic framerate management

	-- Reduce shadow/particle detail on workspace
	workspace.StreamingEnabled = workspace.StreamingEnabled  -- don't touch, just read
	pcall(function()
		workspace.Terrain.WaterWaveSize     = 0
		workspace.Terrain.WaterWaveSpeed    = 0
		workspace.Terrain.WaterReflectance  = 0
		workspace.Terrain.WaterTransparency = 1
	end)

	-- Disable unnecessary LocalScript-driven particles/effects in character
	local function cleanCharacter(char)
		if not char then return end
		for _, obj in ipairs(char:GetDescendants()) do
			if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke")
				or obj:IsA("Fire") or obj:IsA("Sparkles") then
				obj.Enabled = false
				table.insert(disabledEffects, { obj = obj, wasEnabled = true })
			end
		end
	end

	cleanCharacter(plr.Character)
	local charConn = plr.CharacterAdded:Connect(function(char)
		task.wait(0.5)
		cleanCharacter(char)
	end)

	-- ============================================================
	-- GUI
	-- ============================================================
	local gui = Instance.new("ScreenGui")
	gui.Name = "FPSBoosterGUI"
	gui.ResetOnSpawn = false
	gui.Parent = plr.PlayerGui

	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0, 120, 0, 22)
	badge.Position = UDim2.new(1, -128, 0, 8)
	badge.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	badge.BackgroundTransparency = 0.3
	badge.BorderSizePixel = 0
	badge.Parent = gui

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 4)
	badgeCorner.Parent = badge

	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color = Color3.fromRGB(160, 20, 20)
	badgeStroke.Thickness = 1
	badgeStroke.Transparency = 0.5
	badgeStroke.Parent = badge

	local fpsLabel = Instance.new("TextLabel")
	fpsLabel.Size = UDim2.new(1, -8, 1, 0)
	fpsLabel.Position = UDim2.new(0, 8, 0, 0)
	fpsLabel.BackgroundTransparency = 1
	fpsLabel.Text = "FPS: --  PING: --"
	fpsLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
	fpsLabel.TextSize = 10
	fpsLabel.Font = Enum.Font.Code
	fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
	fpsLabel.Parent = badge

	-- ============================================================
	-- FPS + PING COUNTER
	-- ============================================================
	local frameCount = 0
	local elapsed    = 0
	local currentFPS = 0

	local statsConn = RunService.Heartbeat:Connect(function(dt)
		frameCount = frameCount + 1
		elapsed    = elapsed + dt

		if elapsed >= 0.5 then
			currentFPS = math.floor(frameCount / elapsed)
			frameCount = 0
			elapsed    = 0

			local ping = math.floor(Players:GetNetworkPing() * 1000)
			local fpsColor = currentFPS >= 50
				and Color3.fromRGB(100, 210, 100)
				or currentFPS >= 30
				and Color3.fromRGB(210, 180, 60)
				or Color3.fromRGB(210, 80, 80)

			fpsLabel.TextColor3 = fpsColor
			fpsLabel.Text = "FPS: " .. currentFPS .. "  PING: " .. ping .. "ms"
		end
	end)

	print("[ModMenu] FPS Booster loaded")

	-- ============================================================
	-- EXPOSE REFS
	-- ============================================================
	plugin._gui            = gui
	plugin._statsConn      = statsConn
	plugin._charConn       = charConn
	plugin._originals      = originals
	plugin._disabledEffects = disabledEffects
end

function plugin.destroy()
	-- Disconnect RunService loops
	if plugin._statsConn then
		plugin._statsConn:Disconnect()
		plugin._statsConn = nil
	end
	if plugin._charConn then
		plugin._charConn:Disconnect()
		plugin._charConn = nil
	end

	-- Re-enable particles/effects we disabled
	if plugin._disabledEffects then
		for _, entry in ipairs(plugin._disabledEffects) do
			if entry.obj and entry.obj.Parent then
				pcall(function()
					entry.obj.Enabled = entry.wasEnabled
				end)
			end
		end
		plugin._disabledEffects = nil
	end

	-- Restore Lighting
	local orig = plugin._originals
	if orig then
		local Lighting       = game:GetService("Lighting")
		local RenderSettings = settings():GetService("RenderSettings")
		local camera         = workspace.CurrentCamera

		pcall(function() Lighting.GlobalShadows       = orig.GlobalShadows       end)
		pcall(function() Lighting.FogEnd              = orig.FogEnd              end)
		pcall(function() Lighting.FogStart            = orig.FogStart            end)
		pcall(function() RenderSettings.QualityLevel  = orig.QualityLevel        end)
		pcall(function() RenderSettings.EnableFRM     = orig.EnableFRM           end)
		pcall(function() camera.FieldOfView           = orig.FieldOfView         end)

		plugin._originals = nil
	end

	-- Destroy GUI
	if plugin._gui and plugin._gui.Parent then
		plugin._gui:Destroy()
	end
	plugin._gui = nil

	print("[ModMenu] FPS Booster unloaded")
end

return plugin
