local plugin = {
	name = "LOD Tweaker",
	version = "1.0",
	author = "Kyoshin"
}

function plugin.init()
	local RunService = game:GetService("RunService")
	local Players    = game:GetService("Players")
	local plr        = Players.LocalPlayer

	-- ============================================================
	-- CONFIG / DEFAULTS
	-- ============================================================
	local CFG = {
		MIN_RADIUS_MIN  = 32,
		MIN_RADIUS_MAX  = 512,
		TARGET_MIN      = 32,
		TARGET_MAX      = 1024,
		DEFAULT_MIN     = 128,
		DEFAULT_TARGET  = 512,
	}

	-- ============================================================
	-- CAPTURE ORIGINALS
	-- ============================================================
	local originals = {
		StreamingMinRadius    = workspace.StreamingMinRadius,
		StreamingTargetRadius = workspace.StreamingTargetRadius,
		StreamingEnabled      = workspace.StreamingEnabled,
	}

	-- If streaming is off this plugin still works — it just tweaks
	-- the radius values so they're ready if streaming gets enabled,
	-- and we note it in the UI.
	local streamingActive = workspace.StreamingEnabled

	-- ============================================================
	-- STATE
	-- ============================================================
	local State = {
		minRadius    = streamingActive and workspace.StreamingMinRadius    or CFG.DEFAULT_MIN,
		targetRadius = streamingActive and workspace.StreamingTargetRadius or CFG.DEFAULT_TARGET,
		dragging     = nil,   -- "min" | "target" | nil
		connections  = {},
	}

	-- ============================================================
	-- APPLY
	-- ============================================================
	local function applyRadii()
		-- clamp target >= min always
		if State.targetRadius < State.minRadius then
			State.targetRadius = State.minRadius
		end
		pcall(function()
			workspace.StreamingMinRadius    = State.minRadius
			workspace.StreamingTargetRadius = State.targetRadius
		end)
	end

	applyRadii()

	-- ============================================================
	-- GUI CONSTRUCTION
	-- ============================================================
	local gui = Instance.new("ScreenGui")
	gui.Name = "LODTweakerGUI"
	gui.ResetOnSpawn = false
	gui.Parent = plr.PlayerGui

	-- Main frame — anchored bottom-right, above typical taskbars
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 148)
	frame.Position = UDim2.new(1, -212, 1, -260)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	frame.BackgroundTransparency = 0.30
	frame.BorderSizePixel = 1
	frame.BorderColor3 = Color3.fromRGB(50, 50, 50)
	frame.Parent = gui

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 22)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	titleBar.BackgroundTransparency = 0.2
	titleBar.BorderSizePixel = 0
	titleBar.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -8, 1, 0)
	titleLabel.Position = UDim2.new(0, 8, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "LOD TWEAKER"
	titleLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	titleLabel.Font = Enum.Font.Code
	titleLabel.TextSize = 10
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Streaming status dot
	local statusDot = Instance.new("Frame")
	statusDot.Size = UDim2.new(0, 6, 0, 6)
	statusDot.Position = UDim2.new(1, -14, 0.5, -3)
	statusDot.BackgroundColor3 = streamingActive
		and Color3.fromRGB(80, 200, 80)
		or  Color3.fromRGB(180, 60, 60)
	statusDot.BackgroundTransparency = 0
	statusDot.BorderSizePixel = 0
	statusDot.Parent = titleBar

	-- ============================================================
	-- SLIDER BUILDER
	-- ============================================================
	--[[
		Creates a labelled slider at yOffset inside `frame`.
		Returns { track, fill, thumb, valueLabel }
	]]
	local function buildSlider(labelText, yOffset)
		local rowH = 46

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -16, 0, 14)
		lbl.Position = UDim2.new(0, 8, 0, yOffset)
		lbl.BackgroundTransparency = 1
		lbl.Text = labelText
		lbl.TextColor3 = Color3.fromRGB(120, 120, 120)
		lbl.Font = Enum.Font.Code
		lbl.TextSize = 10
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = frame

		local valLbl = Instance.new("TextLabel")
		valLbl.Size = UDim2.new(0, 60, 0, 14)
		valLbl.Position = UDim2.new(1, -68, 0, yOffset)
		valLbl.BackgroundTransparency = 1
		valLbl.Text = "---"
		valLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
		valLbl.Font = Enum.Font.Code
		valLbl.TextSize = 10
		valLbl.TextXAlignment = Enum.TextXAlignment.Right
		valLbl.Parent = frame

		local track = Instance.new("Frame")
		track.Size = UDim2.new(1, -16, 0, 6)
		track.Position = UDim2.new(0, 8, 0, yOffset + 18)
		track.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		track.BackgroundTransparency = 0
		track.BorderSizePixel = 0
		track.Parent = frame

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(0.5, 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
		fill.BackgroundTransparency = 0.3
		fill.BorderSizePixel = 0
		fill.Parent = track

		local thumb = Instance.new("Frame")
		thumb.Size = UDim2.new(0, 10, 0, 14)
		thumb.AnchorPoint = Vector2.new(0.5, 0.5)
		thumb.Position = UDim2.new(0.5, 0, 0.5, 0)
		thumb.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
		thumb.BackgroundTransparency = 0
		thumb.BorderSizePixel = 0
		thumb.Parent = track

		return { track = track, fill = fill, thumb = thumb, valueLabel = valLbl }
	end

	local minSlider    = buildSlider("MIN RADIUS",    28)
	local targetSlider = buildSlider("TARGET RADIUS", 80)

	-- Reset button
	local resetBtn = Instance.new("TextButton")
	resetBtn.Size = UDim2.new(1, -16, 0, 22)
	resetBtn.Position = UDim2.new(0, 8, 1, -30)
	resetBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	resetBtn.BackgroundTransparency = 0.3
	resetBtn.BorderSizePixel = 1
	resetBtn.BorderColor3 = Color3.fromRGB(55, 55, 55)
	resetBtn.Text = "RESET TO DEFAULTS"
	resetBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	resetBtn.Font = Enum.Font.Code
	resetBtn.TextSize = 10
	resetBtn.AutoButtonColor = false
	resetBtn.Parent = frame

	-- ============================================================
	-- SLIDER LOGIC
	-- ============================================================
	local function lerp(a, b, t) return a + (b - a) * t end
	local function invLerp(a, b, v) return math.clamp((v - a) / (b - a), 0, 1) end

	local function updateSliderVisual(sliderObj, pct)
		sliderObj.fill.Size = UDim2.new(pct, 0, 1, 0)
		sliderObj.thumb.Position = UDim2.new(pct, 0, 0.5, 0)
	end

	local function refreshUI()
		local minPct    = invLerp(CFG.MIN_RADIUS_MIN,  CFG.MIN_RADIUS_MAX,  State.minRadius)
		local targetPct = invLerp(CFG.TARGET_MIN,       CFG.TARGET_MAX,      State.targetRadius)

		updateSliderVisual(minSlider,    minPct)
		updateSliderVisual(targetSlider, targetPct)

		minSlider.valueLabel.Text    = tostring(math.floor(State.minRadius))
		targetSlider.valueLabel.Text = tostring(math.floor(State.targetRadius))

		-- colour fill based on how high the value is
		local function fillColor(pct)
			local r = math.floor(lerp(80,  200, pct))
			local g = math.floor(lerp(200, 80,  pct))
			return Color3.fromRGB(r, g, 80)
		end
		minSlider.fill.BackgroundColor3    = fillColor(minPct)
		targetSlider.fill.BackgroundColor3 = fillColor(targetPct)
	end

	refreshUI()

	-- Mouse drag handling
	local UIS = game:GetService("UserInputService")

	local function getTrackPct(track, mouseX)
		local absPos  = track.AbsolutePosition.X
		local absSize = track.AbsoluteSize.X
		return math.clamp((mouseX - absPos) / absSize, 0, 1)
	end

	local function onDrag(input)
		if State.dragging == "min" then
			local pct = getTrackPct(minSlider.track, input.Position.X)
			State.minRadius = math.floor(lerp(CFG.MIN_RADIUS_MIN, CFG.MIN_RADIUS_MAX, pct))
			if State.targetRadius < State.minRadius then
				State.targetRadius = State.minRadius
			end
			applyRadii()
			refreshUI()
		elseif State.dragging == "target" then
			local pct = getTrackPct(targetSlider.track, input.Position.X)
			State.targetRadius = math.floor(lerp(CFG.TARGET_MIN, CFG.TARGET_MAX, pct))
			if State.targetRadius < State.minRadius then
				State.minRadius = State.targetRadius
			end
			applyRadii()
			refreshUI()
		end
	end

	-- Connect track click + drag for both sliders
	local function hookSlider(sliderObj, key)
		sliderObj.track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				State.dragging = key
				onDrag(input)
			end
		end)
	end

	hookSlider(minSlider,    "min")
	hookSlider(targetSlider, "target")

	local dragConn = UIS.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			onDrag(input)
		end
	end)

	local releaseConn = UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			State.dragging = nil
		end
	end)

	State.connections.drag    = dragConn
	State.connections.release = releaseConn

	-- Reset button
	resetBtn.MouseButton1Click:Connect(function()
		State.minRadius    = CFG.DEFAULT_MIN
		State.targetRadius = CFG.DEFAULT_TARGET
		applyRadii()
		refreshUI()
	end)

	resetBtn.MouseEnter:Connect(function()
		resetBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	end)
	resetBtn.MouseLeave:Connect(function()
		resetBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	end)

	print("[ModMenu] LOD Tweaker loaded | Streaming: " .. tostring(streamingActive))

	-- ============================================================
	-- EXPOSE REFS
	-- ============================================================
	plugin._gui       = gui
	plugin._state     = State
	plugin._originals = originals
end

function plugin.destroy()
	-- Disconnect input connections
	if plugin._state and plugin._state.connections then
		for _, conn in pairs(plugin._state.connections) do
			if conn and typeof(conn) == "RBXScriptConnection" then
				conn:Disconnect()
			end
		end
		plugin._state.connections = {}
	end

	-- Restore original streaming radii
	local orig = plugin._originals
	if orig then
		pcall(function()
			workspace.StreamingMinRadius    = orig.StreamingMinRadius
			workspace.StreamingTargetRadius = orig.StreamingTargetRadius
		end)
		plugin._originals = nil
	end

	-- Destroy GUI
	if plugin._gui and plugin._gui.Parent then
		plugin._gui:Destroy()
	end
	plugin._gui   = nil
	plugin._state = nil

	print("[ModMenu] LOD Tweaker unloaded")
end

return plugin
