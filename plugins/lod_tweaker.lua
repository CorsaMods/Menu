local plugin = {
	name = "LOD Tweaker",
	version = "1.1",
	author = "Kyoshin"
}

function plugin.init()
	local RunService     = game:GetService("RunService")
	local Players        = game:GetService("Players")
	local RenderSettings = settings():GetService("RenderSettings")
	local UIS            = game:GetService("UserInputService")
	local plr            = Players.LocalPlayer

	-- ============================================================
	-- STREAMING PROBE  (safe — StreamingMinRadius throws if disabled)
	-- ============================================================
	local streamingActive = workspace.StreamingEnabled

	local origMinRadius, origTargetRadius
	if streamingActive then
		local okMin,    vMin    = pcall(function() return workspace.StreamingMinRadius    end)
		local okTarget, vTarget = pcall(function() return workspace.StreamingTargetRadius end)
		origMinRadius    = okMin    and vMin    or 128
		origTargetRadius = okTarget and vTarget or 512
	end

	-- ============================================================
	-- CONFIG
	-- ============================================================
	local CFG = {
		RADIUS_MIN     = 32,
		RADIUS_MAX     = 1024,
		DEFAULT_MIN    = 128,
		DEFAULT_TARGET = 512,

		-- MeshPartDetailLevel: 0=lowest (AUTO), 4=highest (ULTRA)
		DETAIL_LEVELS = {
			[0] = Enum.NormalId.Top,
			[1] = Enum.NormalId.Bottom,
			[2] = Enum.NormalId.Front,
			[3] = Enum.NormalId.Back,
			[4] = Enum.NormalId.Right,
		},
		DETAIL_LABELS  = { [0]="AUTO", [1]="LOW", [2]="MED", [3]="HIGH", [4]="ULTRA" },
		DEFAULT_DETAIL = 2,
	}

	-- ============================================================
	-- ORIGINALS
	-- ============================================================
	local originals = {
		MeshPartDetailLevel = RenderSettings.MeshPartDetailLevel,
		minRadius           = origMinRadius,
		targetRadius        = origTargetRadius,
	}

	-- ============================================================
	-- STATE
	-- ============================================================
	local State = {
		minRadius    = origMinRadius    or CFG.DEFAULT_MIN,
		targetRadius = origTargetRadius or CFG.DEFAULT_TARGET,
		detailLevel  = CFG.DEFAULT_DETAIL,
		dragging     = nil,
		connections  = {},
	}

	-- ============================================================
	-- APPLY
	-- ============================================================
	local function applyAll()
		if State.targetRadius < State.minRadius then
			State.targetRadius = State.minRadius
		end
		if streamingActive then
			pcall(function() workspace.StreamingMinRadius    = State.minRadius    end)
			pcall(function() workspace.StreamingTargetRadius = State.targetRadius end)
		end
		pcall(function()
			RenderSettings.MeshPartDetailLevel = CFG.DETAIL_LEVELS[State.detailLevel]
		end)
	end

	applyAll()

	-- ============================================================
	-- GUI
	-- ============================================================
	local PANEL_H = streamingActive and 190 or 130

	local gui = Instance.new("ScreenGui")
	gui.Name = "LODTweakerGUI"
	gui.ResetOnSpawn = false
	gui.Parent = plr.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, PANEL_H)
	frame.Position = UDim2.new(1, -212, 1, -260)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	frame.BackgroundTransparency = 0.30
	frame.BorderSizePixel = 1
	frame.BorderColor3 = Color3.fromRGB(50, 50, 50)
	frame.Parent = gui

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
	titleLabel.Text = "LOD TWEAKER"
	titleLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	titleLabel.Font = Enum.Font.Code
	titleLabel.TextSize = 10
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 6, 0, 6)
	dot.Position = UDim2.new(1, -14, 0.5, -3)
	dot.BackgroundColor3 = streamingActive
		and Color3.fromRGB(80, 200, 80)
		or  Color3.fromRGB(180, 60, 60)
	dot.BorderSizePixel = 0
	dot.Parent = titleBar

	if not streamingActive then
		local noStreamLbl = Instance.new("TextLabel")
		noStreamLbl.Size = UDim2.new(1, -16, 0, 12)
		noStreamLbl.Position = UDim2.new(0, 8, 0, 24)
		noStreamLbl.BackgroundTransparency = 1
		noStreamLbl.Text = "streaming off — radius n/a"
		noStreamLbl.TextColor3 = Color3.fromRGB(90, 90, 90)
		noStreamLbl.Font = Enum.Font.Code
		noStreamLbl.TextSize = 9
		noStreamLbl.TextXAlignment = Enum.TextXAlignment.Left
		noStreamLbl.Parent = frame
	end

	-- ============================================================
	-- SLIDER BUILDER  (for streaming radius sliders)
	-- ============================================================
	local function buildSlider(labelText, yOffset)
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
		thumb.BorderSizePixel = 0
		thumb.Parent = track

		return { track = track, fill = fill, thumb = thumb, valueLabel = valLbl }
	end

	-- ============================================================
	-- MESH DETAIL CONTROLS  (always shown)
	-- ============================================================
	local detailYBase = streamingActive and 130 or 38

	local detailLbl = Instance.new("TextLabel")
	detailLbl.Size = UDim2.new(1, -16, 0, 14)
	detailLbl.Position = UDim2.new(0, 8, 0, detailYBase)
	detailLbl.BackgroundTransparency = 1
	detailLbl.Text = "MESH DETAIL"
	detailLbl.TextColor3 = Color3.fromRGB(120, 120, 120)
	detailLbl.Font = Enum.Font.Code
	detailLbl.TextSize = 10
	detailLbl.TextXAlignment = Enum.TextXAlignment.Left
	detailLbl.Parent = frame

	local detailValLbl = Instance.new("TextLabel")
	detailValLbl.Size = UDim2.new(0, 60, 0, 14)
	detailValLbl.Position = UDim2.new(1, -68, 0, detailYBase)
	detailValLbl.BackgroundTransparency = 1
	detailValLbl.Text = CFG.DETAIL_LABELS[State.detailLevel]
	detailValLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	detailValLbl.Font = Enum.Font.Code
	detailValLbl.TextSize = 10
	detailValLbl.TextXAlignment = Enum.TextXAlignment.Right
	detailValLbl.Parent = frame

	local function makeStepBtn(text, xOffset)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 28, 0, 18)
		btn.Position = UDim2.new(0, xOffset, 0, detailYBase + 18)
		btn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
		btn.BackgroundTransparency = 0.3
		btn.BorderSizePixel = 1
		btn.BorderColor3 = Color3.fromRGB(55, 55, 55)
		btn.Text = text
		btn.TextColor3 = Color3.fromRGB(160, 160, 160)
		btn.Font = Enum.Font.Code
		btn.TextSize = 11
		btn.AutoButtonColor = false
		btn.Parent = frame
		return btn
	end

	local detailDown = makeStepBtn("◀", 8)
	local detailUp   = makeStepBtn("▶", 40)

	local pipTrack = Instance.new("Frame")
	pipTrack.Size = UDim2.new(1, -88, 0, 6)
	pipTrack.Position = UDim2.new(0, 76, 0, detailYBase + 24)
	pipTrack.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	pipTrack.BorderSizePixel = 0
	pipTrack.Parent = frame

	local pips = {}
	for i = 0, 4 do
		local pip = Instance.new("Frame")
		pip.Size = UDim2.new(0, 10, 1, 0)
		pip.Position = UDim2.new(i / 4, i == 0 and 0 or -5, 0, 0)
		pip.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		pip.BorderSizePixel = 0
		pip.Parent = pipTrack
		pips[i] = pip
	end

	local function refreshDetailUI()
		detailValLbl.Text = CFG.DETAIL_LABELS[State.detailLevel]
		for i = 0, 4 do
			pips[i].BackgroundColor3 = i <= State.detailLevel
				and Color3.fromRGB(80 + State.detailLevel * 24, 180 - State.detailLevel * 20, 80)
				or  Color3.fromRGB(50, 50, 50)
		end
		detailDown.TextColor3 = State.detailLevel > 0 and Color3.fromRGB(160,160,160) or Color3.fromRGB(55,55,55)
		detailUp.TextColor3   = State.detailLevel < 4 and Color3.fromRGB(160,160,160) or Color3.fromRGB(55,55,55)
	end

	detailDown.MouseButton1Click:Connect(function()
		if State.detailLevel > 0 then
			State.detailLevel -= 1
			applyAll(); refreshDetailUI()
		end
	end)
	detailUp.MouseButton1Click:Connect(function()
		if State.detailLevel < 4 then
			State.detailLevel += 1
			applyAll(); refreshDetailUI()
		end
	end)

	refreshDetailUI()

	-- ============================================================
	-- STREAMING SLIDERS  (only when streaming is active)
	-- ============================================================
	if streamingActive then
		local minSlider    = buildSlider("MIN RADIUS",    28)
		local targetSlider = buildSlider("TARGET RADIUS", 80)

		local function lerp(a, b, t) return a + (b - a) * t end
		local function invLerp(a, b, v) return math.clamp((v-a)/(b-a), 0, 1) end
		local function fillColor(pct)
			return Color3.fromRGB(math.floor(lerp(80,200,pct)), math.floor(lerp(200,80,pct)), 80)
		end

		local function refreshRadiusUI()
			local minPct    = invLerp(CFG.RADIUS_MIN, CFG.RADIUS_MAX, State.minRadius)
			local targetPct = invLerp(CFG.RADIUS_MIN, CFG.RADIUS_MAX, State.targetRadius)
			minSlider.fill.Size             = UDim2.new(minPct, 0, 1, 0)
			minSlider.thumb.Position        = UDim2.new(minPct, 0, 0.5, 0)
			minSlider.valueLabel.Text       = tostring(math.floor(State.minRadius))
			minSlider.fill.BackgroundColor3 = fillColor(minPct)
			targetSlider.fill.Size             = UDim2.new(targetPct, 0, 1, 0)
			targetSlider.thumb.Position        = UDim2.new(targetPct, 0, 0.5, 0)
			targetSlider.valueLabel.Text       = tostring(math.floor(State.targetRadius))
			targetSlider.fill.BackgroundColor3 = fillColor(targetPct)
		end

		refreshRadiusUI()

		local function getTrackPct(track, mouseX)
			return math.clamp((mouseX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		end

		local function onDrag(input)
			if State.dragging == "min" then
				State.minRadius = math.floor(lerp(CFG.RADIUS_MIN, CFG.RADIUS_MAX, getTrackPct(minSlider.track, input.Position.X)))
				if State.targetRadius < State.minRadius then State.targetRadius = State.minRadius end
				applyAll(); refreshRadiusUI()
			elseif State.dragging == "target" then
				State.targetRadius = math.floor(lerp(CFG.RADIUS_MIN, CFG.RADIUS_MAX, getTrackPct(targetSlider.track, input.Position.X)))
				if State.targetRadius < State.minRadius then State.minRadius = State.targetRadius end
				applyAll(); refreshRadiusUI()
			end
		end

		minSlider.track.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then State.dragging = "min"; onDrag(i) end
		end)
		targetSlider.track.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then State.dragging = "target"; onDrag(i) end
		end)
		State.connections.drag    = UIS.InputChanged:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseMovement then onDrag(i) end
		end)
		State.connections.release = UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then State.dragging = nil end
		end)
	end

	-- ============================================================
	-- RESET BUTTON
	-- ============================================================
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

	resetBtn.MouseButton1Click:Connect(function()
		State.minRadius   = CFG.DEFAULT_MIN
		State.targetRadius = CFG.DEFAULT_TARGET
		State.detailLevel  = CFG.DEFAULT_DETAIL
		applyAll(); refreshDetailUI()
	end)
	resetBtn.MouseEnter:Connect(function() resetBtn.TextColor3 = Color3.fromRGB(200,200,200) end)
	resetBtn.MouseLeave:Connect(function() resetBtn.TextColor3 = Color3.fromRGB(120,120,120) end)

	print("[ModMenu] LOD Tweaker loaded | Streaming: " .. tostring(streamingActive))

	plugin._gui       = gui
	plugin._state     = State
	plugin._originals = originals
end

function plugin.destroy()
	if plugin._state and plugin._state.connections then
		for _, conn in pairs(plugin._state.connections) do
			if conn and typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
		end
		plugin._state.connections = {}
	end

	local orig = plugin._originals
	if orig then
		local RS = settings():GetService("RenderSettings")
		pcall(function() RS.MeshPartDetailLevel          = orig.MeshPartDetailLevel end)
		pcall(function() workspace.StreamingMinRadius    = orig.minRadius           end)
		pcall(function() workspace.StreamingTargetRadius = orig.targetRadius        end)
		plugin._originals = nil
	end

	if plugin._gui and plugin._gui.Parent then plugin._gui:Destroy() end
	plugin._gui   = nil
	plugin._state = nil

	print("[ModMenu] LOD Tweaker unloaded")
end

return plugin
