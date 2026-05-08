local plugin = {
    name = "Air Suspension",
    version = "1.0",
    author = "you"
}

function plugin.init()
    -- // BAGS SYSTEM v3
-- // Captures original ride height at runtime, slam + return to OEM

local RunService = game:GetService("RunService")
local plr = game.Players.LocalPlayer
local pname = plr.Name
local workspace = game.Workspace
-- ============================================================
-- CONFIG
-- ============================================================
local CFG = {
	HEIGHT_LOWERED = 0.5,

	PSI_MAX        = 120,
	PSI_MIN        = 0,

	WEIGHT_TRANSFER_FRONT = 0.10,
	WEIGHT_TRANSFER_REAR  = 0.06,

	SETTLE_AMOUNT    = 0.02,   -- reduced settle intensity for smoother landing
	SETTLE_DAMPING   = 8.0,
	SETTLE_FREQUENCY = 8,

	DELAY = {
		DROP    = { FL = 0.00, FR = 0.05, RL = 0.40, RR = 0.45 },
		RETURN  = { FL = 0.28, FR = 0.30, RL = 0.00, RR = 0.00 },
	},

	DURATION = {
		DROP    = { FL = 3.20, FR = 3.20, RL = 3.60, RR = 3.65 },  -- was ~1.0s, now 3s+
		RETURN  = { FL = 0.90, FR = 0.90, RL = 1.00, RR = 1.02 },
	},

	COMPRESSOR_SPOOL = 0.12,
}
-- ============================================================
-- STATE
-- ============================================================
local State = {
	isSlammed     = false,
	transitioning = false,
	psi           = { FL = 120, FR = 120, RL = 120, RR = 120 },
	connections   = {},
}

local DEFAULT_LENGTHS = {}
local defaultsCaptured = false
local cornerThreads = {}

-- ============================================================
-- HELPERS
-- ============================================================
local function getWheels()
	local storage = workspace:FindFirstChild("AVehicleStorage")
	if not storage then return nil end
	local Car = storage:FindFirstChild(pname)
	if not Car then return nil end
	local Wheels = Car:FindFirstChild("Wheels")
	if not Wheels then return nil end
	return {
		FL = Wheels:FindFirstChild("FL"),
		FR = Wheels:FindFirstChild("FR"),
		RL = Wheels:FindFirstChild("RL"),
		RR = Wheels:FindFirstChild("RR"),
	}
end

local function getSpring(folder)
	if not folder then return nil end
	return folder:FindFirstChildOfClass("SpringConstraint")
end

local function getAllSprings()
	local w = getWheels()
	if not w then return nil end
	return {
		FL = getSpring(w.FL),
		FR = getSpring(w.FR),
		RL = getSpring(w.RL),
		RR = getSpring(w.RR),
	}
end

-- ============================================================
-- CAPTURE DEFAULTS
-- Retries every 0.5s until the car exists and springs are valid
-- ============================================================
local function captureDefaults()
	local springs = getAllSprings()
	if not springs then
		task.delay(0.5, captureDefaults)
		return
	end
	local any = false
	for _, corner in ipairs({"FL","FR","RL","RR"}) do
		local s = springs[corner]
		if s and s.FreeLength > 0 then
			DEFAULT_LENGTHS[corner] = s.FreeLength
			any = true
		end
	end
	if not any then
		task.delay(0.5, captureDefaults)
		return
	end
	defaultsCaptured = true
end

captureDefaults()

-- ============================================================
-- EASING
-- ============================================================
local Ease = {}

-- Air bleed: smooth cubic ease-in (slow start, gradual acceleration)
-- Previously used math.pow(2, -9*t) which caused a violent initial drop
function Ease.bleed(t)
	return t * t * t   -- cubic ease-in: starts slow, builds momentum naturally
end

-- Compressor fill: smooth s-curve
function Ease.fill(t)
	return t * t * (3 - 2 * t)
end

-- Damped oscillation settle at end of travel
function Ease.settle(t, amount, damping, freq)
	return amount * math.exp(-damping * t) * math.cos(freq * t * math.pi * 2)
end

-- ============================================================
-- PSI -> SPRING LENGTH
-- Maps 0-120 PSI to lowered height -> captured OEM height
-- ============================================================
local function psiToLength(corner, psi)
	local top = DEFAULT_LENGTHS[corner] or 2.5
	local t = math.clamp(psi / CFG.PSI_MAX, 0, 1)
	return CFG.HEIGHT_LOWERED + (top - CFG.HEIGHT_LOWERED) * t
end

-- ============================================================
-- PSI DRIVER LOOP
-- Runs every heartbeat, pushes spring lengths from PSI values
-- ============================================================
local function startPSILoop()
	if State.connections.psiLoop then
		State.connections.psiLoop:Disconnect()
	end
	State.connections.psiLoop = RunService.Heartbeat:Connect(function(dt)
		if not defaultsCaptured then return end
		local springs = getAllSprings()
		if not springs then return end
		for _, corner in ipairs({"FL","FR","RL","RR"}) do
			local s = springs[corner]
			if s then
				local targetLen = psiToLength(corner, State.psi[corner])
				s.FreeLength = s.FreeLength + (targetLen - s.FreeLength) * math.min(dt * 18, 1)
			end
		end
	end)
end

-- ============================================================
-- PER-CORNER ANIMATION
-- Each corner owns a token; cancels itself if token changes
-- ============================================================
local function animateCorner(corner, targetPSI, duration, startDelay, weightBias, isDropping)
	if cornerThreads[corner] then
		cornerThreads[corner] = false
	end
	local token = {}
	cornerThreads[corner] = token

	task.spawn(function()
		if startDelay > 0 then task.wait(startDelay) end
		if cornerThreads[corner] ~= token then return end

		-- Compressor spool on return
		if not isDropping then
			task.wait(CFG.COMPRESSOR_SPOOL)
		end
		if cornerThreads[corner] ~= token then return end

		local startPSI = State.psi[corner]
		local elapsed  = 0
		local settled  = false

		local bias = (weightBias or 0)
		local biasedTarget = isDropping
			and (targetPSI - bias * CFG.PSI_MAX)
			or  targetPSI

		biasedTarget = math.clamp(biasedTarget, CFG.PSI_MIN, CFG.PSI_MAX)

		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if cornerThreads[corner] ~= token then
				conn:Disconnect()
				return
			end

			elapsed = elapsed + dt
			local t = math.clamp(elapsed / duration, 0, 1)
			local eased = isDropping and Ease.bleed(t) or Ease.fill(t)

			State.psi[corner] = startPSI + (biasedTarget - startPSI) * eased

			if t >= 1 and not settled then
				settled = true
				conn:Disconnect()

				-- Settle oscillation
				local sElapsed = 0
				local settleConn
				settleConn = RunService.Heartbeat:Connect(function(sdt)
					if cornerThreads[corner] ~= token then
						settleConn:Disconnect()
						return
					end
					sElapsed = sElapsed + sdt
					local offset = Ease.settle(
						sElapsed,
						CFG.SETTLE_AMOUNT * CFG.PSI_MAX,
						CFG.SETTLE_DAMPING,
						CFG.SETTLE_FREQUENCY
					)
					State.psi[corner] = targetPSI + offset
					if sElapsed > 0.6 then
						State.psi[corner] = targetPSI
						settleConn:Disconnect()
					end
				end)
			end
		end)
	end)
end

-- ============================================================
-- SLAM / RETURN
-- ============================================================
local function slam()
	animateCorner("FL", CFG.PSI_MIN, CFG.DURATION.DROP.FL,   CFG.DELAY.DROP.FL,   CFG.WEIGHT_TRANSFER_FRONT, true)
	animateCorner("FR", CFG.PSI_MIN, CFG.DURATION.DROP.FR,   CFG.DELAY.DROP.FR,   CFG.WEIGHT_TRANSFER_FRONT, true)
	animateCorner("RL", CFG.PSI_MIN, CFG.DURATION.DROP.RL,   CFG.DELAY.DROP.RL,   CFG.WEIGHT_TRANSFER_REAR,  true)
	animateCorner("RR", CFG.PSI_MIN, CFG.DURATION.DROP.RR,   CFG.DELAY.DROP.RR,   CFG.WEIGHT_TRANSFER_REAR,  true)
end

local function returnToDefault()
	animateCorner("RL", CFG.PSI_MAX, CFG.DURATION.RETURN.RL, CFG.DELAY.RETURN.RL, 0, false)
	animateCorner("RR", CFG.PSI_MAX, CFG.DURATION.RETURN.RR, CFG.DELAY.RETURN.RR, 0, false)
	animateCorner("FL", CFG.PSI_MAX, CFG.DURATION.RETURN.FL, CFG.DELAY.RETURN.FL, 0, false)
	animateCorner("FR", CFG.PSI_MAX, CFG.DURATION.RETURN.FR, CFG.DELAY.RETURN.FR, 0, false)
end

-- ============================================================
-- GUI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "BagsGUI"
gui.ResetOnSpawn = false
gui.Parent = plr.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 115)
frame.Position = UDim2.new(0.5, -90, 1, -130)
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0
frame.Parent = gui

-- PSI bars
local barsFrame = Instance.new("Frame")
barsFrame.Size = UDim2.new(1, 0, 0, 65)
barsFrame.Position = UDim2.new(0, 0, 0, 0)
barsFrame.BackgroundTransparency = 1
barsFrame.Parent = frame

local corners = {"FL","FR","RL","RR"}
local barObjs = {}
local xPositions = {0, 46, 92, 138}

for i, corner in ipairs(corners) do
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(0, 32, 0, 60)
	bg.Position = UDim2.new(0, xPositions[i], 0, 0)
	bg.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	bg.BackgroundTransparency = 0.35
	bg.BorderSizePixel = 0
	bg.Parent = barsFrame

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.Position = UDim2.new(0, 0, 0, 0)
	fill.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
	fill.BackgroundTransparency = 0.2
	fill.BorderSizePixel = 0
	fill.Parent = bg

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 12)
	lbl.Position = UDim2.new(0, 0, 1, 4)
	lbl.BackgroundTransparency = 1
	lbl.Text = corner
	lbl.TextColor3 = Color3.fromRGB(120, 120, 120)
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 10
	lbl.Parent = bg

	barObjs[corner] = { fill = fill }
end

-- Two buttons: SLAM and RETURN
local slamBtn = Instance.new("TextButton")
slamBtn.Size = UDim2.new(0, 85, 0, 26)
slamBtn.Position = UDim2.new(0, 0, 1, -26)
slamBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
slamBtn.BackgroundTransparency = 0.3
slamBtn.BorderSizePixel = 1
slamBtn.BorderColor3 = Color3.fromRGB(160, 50, 50)
slamBtn.Text = "SLAM"
slamBtn.TextColor3 = Color3.fromRGB(210, 90, 90)
slamBtn.Font = Enum.Font.Code
slamBtn.TextSize = 11
slamBtn.AutoButtonColor = false
slamBtn.Parent = frame

local returnBtn = Instance.new("TextButton")
returnBtn.Size = UDim2.new(0, 85, 0, 26)
returnBtn.Position = UDim2.new(1, -85, 1, -26)
returnBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
returnBtn.BackgroundTransparency = 0.3
returnBtn.BorderSizePixel = 1
returnBtn.BorderColor3 = Color3.fromRGB(60, 60, 60)
returnBtn.Text = "RETURN"
returnBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
returnBtn.Font = Enum.Font.Code
returnBtn.TextSize = 11
returnBtn.AutoButtonColor = false
returnBtn.Parent = frame

-- Dim whichever button isn't usable
local function updateBtnStates()
	if State.isSlammed then
		slamBtn.BackgroundTransparency = 0.7
		slamBtn.TextColor3 = Color3.fromRGB(100, 60, 60)
		returnBtn.BackgroundTransparency = 0.3
		returnBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
		returnBtn.BorderColor3 = Color3.fromRGB(80, 80, 80)
	else
		slamBtn.BackgroundTransparency = 0.3
		slamBtn.TextColor3 = Color3.fromRGB(210, 90, 90)
		slamBtn.BorderColor3 = Color3.fromRGB(160, 50, 50)
		returnBtn.BackgroundTransparency = 0.7
		returnBtn.TextColor3 = Color3.fromRGB(80, 80, 80)
	end
end

updateBtnStates()

-- ============================================================
-- PSI BAR UPDATE LOOP
-- ============================================================
RunService.Heartbeat:Connect(function()
	for _, corner in ipairs(corners) do
		local pct = math.clamp(State.psi[corner] / CFG.PSI_MAX, 0, 1)
		local obj = barObjs[corner]
		if obj then
			obj.fill.Size = UDim2.new(1, 0, pct, 0)
			obj.fill.Position = UDim2.new(0, 0, 1 - pct, 0)
			local r = 100 + math.floor((1 - pct) * 120)
			local g = 80  + math.floor(pct * 80)
			local b = 80  + math.floor(pct * 80)
			obj.fill.BackgroundColor3 = Color3.fromRGB(r, g, b)
		end
	end
end)

-- ============================================================
-- BUTTON LOGIC
-- ============================================================
slamBtn.MouseButton1Click:Connect(function()
	if State.transitioning or State.isSlammed then return end
	State.transitioning = true
	State.isSlammed = true
	updateBtnStates()
	slam()
	task.delay(4.5, function()   -- was 2.2, now covers the longer drop + settle
		State.transitioning = false
	end)
end)

returnBtn.MouseButton1Click:Connect(function()
	if State.transitioning or not State.isSlammed then return end
	State.transitioning = true
	State.isSlammed = false
	updateBtnStates()
	returnToDefault()
	task.delay(1.8, function()
		State.transitioning = false
	end)
end)

-- ============================================================
-- START
-- ============================================================
startPSILoop()
    print("[ModMenu] Air Suspension loaded")
end

function plugin.destroy()
    -- cleanup on disable
end

return plugin
