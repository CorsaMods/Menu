local plugin = {
	name = "Exhaust Sound",
	version = "1.0",
	author = "Kyoshin"
}

function plugin.init()
	local Players    = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local plr        = Players.LocalPlayer
	local pname      = plr.Name

	-- ============================================================
	-- CONFIG
	-- ============================================================
	local CFG = {
		POLL_RATE   = 0.01,   -- how often to check if exhaust sound changed
		REMOTE_PATH = {      -- path to FireServer remote
			"PlayerGui",
			"A-Chassis Interface",
			"Radio",
			"Remotes",
			"PlayMusic",
		},
	}

	-- ============================================================
	-- STATE
	-- ============================================================
	local State = {
		loopActive      = true,
		lastSoundId     = nil,   -- last sound ID we fired to the server
		connections     = {},
	}

	-- ============================================================
	-- PATH HELPERS
	-- ============================================================
	local function getRemote()
		local root = plr
		for _, step in ipairs(CFG.REMOTE_PATH) do
			if not root then return nil end
			root = root:FindFirstChild(step)
		end
		return root  -- RemoteEvent "PlayMusic"
	end

	local function getExhaustFolder()
		local storage = game.Workspace:FindFirstChild("AVehicleStorage")
		if not storage then return nil end
		local car = storage:FindFirstChild(pname)
		if not car then return nil end
		local body = car:FindFirstChild("Body")
		if not body then return nil end
		return body:FindFirstChild("Exhaust")
	end

	-- Returns the first playing Sound inside the Exhaust folder, or nil
	local function getPlayingSound(exhaustFolder)
		if not exhaustFolder then return nil end
		for _, obj in ipairs(exhaustFolder:GetDescendants()) do
			if obj:IsA("Sound") and obj.Playing and obj.SoundId ~= "" then
				return obj
			end
		end
		return nil
	end

	-- ============================================================
	-- FIRE REMOTE
	-- ============================================================
	local function firePlayMusic(soundId)
		local remote = getRemote()
		if not remote then
			warn("[ModMenu] Exhaust Sound: PlayMusic remote not found")
			return false
		end
		remote:FireServer(soundId)
		return true
	end

	-- ============================================================
	-- POLL LOOP
	-- ============================================================
	task.spawn(function()
		while State.loopActive do
			local exhaust = getExhaustFolder()
			local sound   = getPlayingSound(exhaust)

			if sound then
				local id = sound.SoundId
				if id ~= State.lastSoundId then
					-- New or changed sound — fire it through the radio remote
					local fired = firePlayMusic(id)
					if fired then
						State.lastSoundId = id
						State.status      = "playing"
						State.statusText  = sound.Name
					end
				end
				State.exhaustFound = true
				State.soundFound   = true
			else
				State.soundFound = false
				if exhaust then
					State.exhaustFound = true
					State.status       = "idle"
					State.statusText   = "no sound playing"
				else
					State.exhaustFound = false
					State.status       = "missing"
					State.statusText   = "exhaust not found"
				end
			end

			if updateUI then updateUI() end
			task.wait(CFG.POLL_RATE)
		end
	end)

	-- ============================================================
	-- GUI
	-- ============================================================
	local gui = Instance.new("ScreenGui")
	gui.Name = "ExhaustSoundGUI"
	gui.ResetOnSpawn = false
	gui.Parent = plr.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 88)
	frame.Position = UDim2.new(1, -212, 1, -420)   -- stacks above other panels
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
	titleLabel.Size = UDim2.new(1, -20, 1, 0)
	titleLabel.Position = UDim2.new(0, 8, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "EXHAUST SOUND"
	titleLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	titleLabel.Font = Enum.Font.Code
	titleLabel.TextSize = 10
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 6, 0, 6)
	dot.Position = UDim2.new(1, -14, 0.5, -3)
	dot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	dot.BorderSizePixel = 0
	dot.Parent = titleBar

	-- Status row
	local statusLbl = Instance.new("TextLabel")
	statusLbl.Size = UDim2.new(1, -16, 0, 14)
	statusLbl.Position = UDim2.new(0, 8, 0, 28)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "searching..."
	statusLbl.TextColor3 = Color3.fromRGB(90, 90, 90)
	statusLbl.Font = Enum.Font.Code
	statusLbl.TextSize = 10
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.Parent = frame

	-- Sound name row
	local soundLbl = Instance.new("TextLabel")
	soundLbl.Size = UDim2.new(1, -16, 0, 12)
	soundLbl.Position = UDim2.new(0, 8, 0, 46)
	soundLbl.BackgroundTransparency = 1
	soundLbl.Text = ""
	soundLbl.TextColor3 = Color3.fromRGB(70, 70, 70)
	soundLbl.Font = Enum.Font.Code
	soundLbl.TextSize = 9
	soundLbl.TextXAlignment = Enum.TextXAlignment.Left
	soundLbl.TextTruncate = Enum.TextTruncate.AtEnd
	soundLbl.Parent = frame

	-- Last fired ID row
	local firedLbl = Instance.new("TextLabel")
	firedLbl.Size = UDim2.new(1, -16, 0, 12)
	firedLbl.Position = UDim2.new(0, 8, 0, 62)
	firedLbl.BackgroundTransparency = 1
	firedLbl.Text = "last fired: —"
	firedLbl.TextColor3 = Color3.fromRGB(55, 55, 55)
	firedLbl.Font = Enum.Font.Code
	firedLbl.TextSize = 8
	firedLbl.TextXAlignment = Enum.TextXAlignment.Left
	firedLbl.TextTruncate = Enum.TextTruncate.AtEnd
	firedLbl.Parent = frame

	-- Manual retrigger button
	local retriggerBtn = Instance.new("TextButton")
	retriggerBtn.Size = UDim2.new(1, -16, 0, 18)
	retriggerBtn.Position = UDim2.new(0, 8, 1, -24)
	retriggerBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	retriggerBtn.BackgroundTransparency = 0.3
	retriggerBtn.BorderSizePixel = 1
	retriggerBtn.BorderColor3 = Color3.fromRGB(55, 55, 55)
	retriggerBtn.Text = "RETRIGGER"
	retriggerBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	retriggerBtn.Font = Enum.Font.Code
	retriggerBtn.TextSize = 10
	retriggerBtn.AutoButtonColor = false
	retriggerBtn.Parent = frame

	retriggerBtn.MouseButton1Click:Connect(function()
		if State.lastSoundId then
			firePlayMusic(State.lastSoundId)
			retriggerBtn.TextColor3 = Color3.fromRGB(80, 200, 80)
			task.delay(0.4, function()
				retriggerBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
			end)
		end
	end)
	retriggerBtn.MouseEnter:Connect(function()
		retriggerBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	end)
	retriggerBtn.MouseLeave:Connect(function()
		retriggerBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	end)

	-- ============================================================
	-- UI UPDATER  (upvalue assigned after GUI is built)
	-- ============================================================
	updateUI = function()
		local status = State.status or "missing"

		if status == "playing" then
			dot.BackgroundColor3  = Color3.fromRGB(80, 200, 80)
			statusLbl.Text        = "routing exhaust audio"
			statusLbl.TextColor3  = Color3.fromRGB(100, 180, 100)
			soundLbl.Text         = "sound: " .. (State.statusText or "")
			soundLbl.TextColor3   = Color3.fromRGB(100, 160, 100)
		elseif status == "idle" then
			dot.BackgroundColor3  = Color3.fromRGB(90, 90, 90)
			statusLbl.Text        = "idle — no sound playing"
			statusLbl.TextColor3  = Color3.fromRGB(90, 90, 90)
			soundLbl.Text         = ""
		elseif status == "missing" then
			dot.BackgroundColor3  = Color3.fromRGB(180, 60, 60)
			statusLbl.Text        = "exhaust not found"
			statusLbl.TextColor3  = Color3.fromRGB(160, 70, 70)
			soundLbl.Text         = ""
		end

		if State.lastSoundId then
			firedLbl.Text = "last fired: " .. State.lastSoundId
		end
	end

	print("[ModMenu] Exhaust Sound loaded")

	plugin._gui      = gui
	plugin._state    = State
end

function plugin.destroy()
	-- Stop poll loop
	if plugin._state then
		plugin._state.loopActive = false
		plugin._state = nil
	end

	-- Destroy GUI
	if plugin._gui and plugin._gui.Parent then
		plugin._gui:Destroy()
	end
	plugin._gui = nil

	print("[ModMenu] Exhaust Sound unloaded")
end

return plugin
