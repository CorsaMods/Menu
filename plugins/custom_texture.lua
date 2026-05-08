local plugin = {
	name = "Custom Textures",
	version = "1.0",
	author = "Kyoshin"
}

function plugin.init()
	local RunService = game:GetService("RunService")
	local Players    = game:GetService("Players")
	local plr        = Players.LocalPlayer
	local pname      = plr.Name
	local workspace  = game.Workspace

	-- ============================================================
	-- CONFIG
	-- ============================================================
	local CFG = {
		TEXTURE_ID    = "rbxassetid://121289954112924",
		OFFSET_U      = 3,
		OFFSET_V      = 3,
		STUDS_U       = 6,
		STUDS_V       = 6,
		FACE          = Enum.NormalId.Top,
		TEXTURE_NAME  = "AutoTexture",
		POLL_RATE     = 0.1,   -- seconds between path checks
	}

	-- ============================================================
	-- STATE
	-- ============================================================
	local State = {
		applied     = false,   -- true once texture is confirmed on the part
		partFound   = false,   -- true once path resolved at least once
		connections = {},
	}

	-- ============================================================
	-- PATH RESOLVER
	-- ============================================================
	local function getPath()
		local AVehicleStorage = workspace:FindFirstChild("AVehicleStorage")
		if not AVehicleStorage then return nil end
		local playerFolder = AVehicleStorage:FindFirstChild(pname)
		if not playerFolder then return nil end
		local Misc = playerFolder:FindFirstChild("Misc")
		if not Misc then return nil end
		local HD = Misc:FindFirstChild("HD")
		if not HD then return nil end
		return HD:FindFirstChild("PAINT")
	end

	-- ============================================================
	-- TEXTURE APPLICATION
	-- ============================================================
	local function applyTexture(part)
		-- Remove any stale copy first (handles texture ID changes mid-session)
		local existing = part:FindFirstChild(CFG.TEXTURE_NAME)
		if existing then
			if existing.Texture == CFG.TEXTURE_ID then
				return false  -- already correct, nothing to do
			end
			existing:Destroy()
		end

		local texture          = Instance.new("Texture")
		texture.Name           = CFG.TEXTURE_NAME
		texture.Texture        = CFG.TEXTURE_ID
		texture.OffsetStudsU   = CFG.OFFSET_U
		texture.OffsetStudsV   = CFG.OFFSET_V
		texture.StudsPerTileU  = CFG.STUDS_U
		texture.StudsPerTileV  = CFG.STUDS_V
		texture.Face           = CFG.FACE
		texture.Parent         = part
		return true
	end

	-- ============================================================
	-- POLL LOOP  (replaces the raw while/true)
	-- updateStatusUI is declared as a local upvalue here and assigned
	-- after the GUI is built below — Lua resolves upvalues at call
	-- time, so this is safe as long as the first task.wait fires after
	-- the GUI block runs (it will, since task.spawn yields immediately).
	-- ============================================================
	local updateStatusUI  -- forward declaration

	local loopActive = true
	task.spawn(function()
		while loopActive do
			local part = getPath()
			if part then
				State.partFound = true
				-- applyTexture returns true when it wrote, false when already correct
				State.applied = not applyTexture(part)
			else
				State.partFound = false
				State.applied   = false
			end
			if updateStatusUI then updateStatusUI() end
			task.wait(CFG.POLL_RATE)
		end
	end)

	-- Store the kill flag so destroy() can stop the loop
	State._killLoop = function() loopActive = false end

	-- ============================================================
	-- GUI
	-- ============================================================
	local gui = Instance.new("ScreenGui")
	gui.Name = "ApplyTextureGUI"
	gui.ResetOnSpawn = false
	gui.Parent = plr.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 180, 0, 64)
	frame.Position = UDim2.new(1, -192, 1, -340)   -- sits above LOD Tweaker
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	frame.BackgroundTransparency = 0.30
	frame.BorderSizePixel = 1
	frame.BorderColor3 = Color3.fromRGB(50, 50, 50)
	frame.Parent = gui

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 22)
	titleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	titleBar.BackgroundTransparency = 0.2
	titleBar.BorderSizePixel = 0
	titleBar.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -8, 1, 0)
	titleLabel.Position = UDim2.new(0, 8, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "APPLY TEXTURE"
	titleLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	titleLabel.Font = Enum.Font.Code
	titleLabel.TextSize = 10
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Status dot
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 6, 0, 6)
	dot.Position = UDim2.new(1, -14, 0.5, -3)
	dot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	dot.BorderSizePixel = 0
	dot.Parent = titleBar

	-- Status line
	local statusLbl = Instance.new("TextLabel")
	statusLbl.Size = UDim2.new(1, -16, 0, 14)
	statusLbl.Position = UDim2.new(0, 8, 0, 26)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "searching for PAINT..."
	statusLbl.TextColor3 = Color3.fromRGB(90, 90, 90)
	statusLbl.Font = Enum.Font.Code
	statusLbl.TextSize = 10
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.Parent = frame

	-- Part path display
	local pathLbl = Instance.new("TextLabel")
	pathLbl.Size = UDim2.new(1, -16, 0, 12)
	pathLbl.Position = UDim2.new(0, 8, 0, 44)
	pathLbl.BackgroundTransparency = 1
	pathLbl.Text = "AVehicleStorage › " .. pname .. " › Misc › HD › PAINT"
	pathLbl.TextColor3 = Color3.fromRGB(55, 55, 55)
	pathLbl.Font = Enum.Font.Code
	pathLbl.TextSize = 8
	pathLbl.TextXAlignment = Enum.TextXAlignment.Left
	pathLbl.TextTruncate = Enum.TextTruncate.AtEnd
	pathLbl.Parent = frame

	-- ============================================================
	-- STATUS UI UPDATER  (assigned here, referenced as upvalue in loop)
	-- ============================================================
	updateStatusUI = function()
		if not State.partFound then
			dot.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
			statusLbl.Text       = "searching for PAINT..."
			statusLbl.TextColor3 = Color3.fromRGB(90, 90, 90)
		elseif State.applied then
			dot.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
			statusLbl.Text       = "texture active"
			statusLbl.TextColor3 = Color3.fromRGB(100, 180, 100)
		else
			dot.BackgroundColor3 = Color3.fromRGB(200, 160, 50)
			statusLbl.Text       = "applying..."
			statusLbl.TextColor3 = Color3.fromRGB(200, 160, 50)
		end
	end

	print("[ModMenu] Apply Texture loaded")

	plugin._gui      = gui
	plugin._state    = State
	plugin._killLoop = State._killLoop
end

function plugin.destroy()
	-- Stop the poll loop
	if plugin._killLoop then
		plugin._killLoop()
		plugin._killLoop = nil
	end

	-- Remove the texture from the part if it's still there
	if plugin._state then
		-- best-effort cleanup: find the part and strip the texture
		local plr = game:GetService("Players").LocalPlayer
		local ws   = game.Workspace
		local AVehicleStorage = ws:FindFirstChild("AVehicleStorage")
		if AVehicleStorage then
			local playerFolder = AVehicleStorage:FindFirstChild(plr.Name)
			if playerFolder then
				local ok, part = pcall(function()
					return playerFolder:FindFirstChild("Misc")
						:FindFirstChild("HD")
						:FindFirstChild("PAINT")
				end)
				if ok and part then
					local tex = part:FindFirstChild("AutoTexture")
					if tex then tex:Destroy() end
				end
			end
		end
		plugin._state = nil
	end

	-- Destroy GUI
	if plugin._gui and plugin._gui.Parent then
		plugin._gui:Destroy()
	end
	plugin._gui = nil

	print("[ModMenu] Apply Texture unloaded")
end

return plugin
