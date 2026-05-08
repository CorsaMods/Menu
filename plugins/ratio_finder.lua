local plugin = {
	name = "Ratio Finder",
	version = "1.0",
	author = "Kyoshin"
}

function plugin.init()
	local Players   = game:GetService("Players")
	local plr       = Players.LocalPlayer
	local workspace = game.Workspace

	-- ============================================================
	-- CONFIG
	-- ============================================================
	local CFG = {
		POLL_RATE     = 0.5,   -- seconds between vehicle list refreshes
		FD_PATTERN    = "^FD%d+$",  -- matches FD2, FD3, FD10, etc.
	}

	-- ============================================================
	-- STATE
	-- ============================================================
	local State = {
		vehicles        = {},   -- list of vehicle model names
		selectedVehicle = nil,  -- currently viewed vehicle Model
		fdEntries       = {},   -- { name, value } pairs found in Stats
	}

	-- ============================================================
	-- HELPERS
	-- ============================================================
	local function getAVehicleWorkspace()
		return workspace:FindFirstChild("AVehicleWorkspace")
	end

	-- Collect direct children of AVehicleWorkspace
	local function refreshVehicleList()
		local avw = getAVehicleWorkspace()
		local list = {}
		if avw then
			for _, child in ipairs(avw:GetChildren()) do
				table.insert(list, child)
			end
		end
		return list
	end

	-- Collect FD* string values + FinalDrive from model.Stats
	local function getFDEntries(vehicle)
		local entries = {}
		local Stats = vehicle:FindFirstChild("Stats")
		if not Stats then return entries end

		-- FinalDrive first (always shown if present)
		local fd = Stats:FindFirstChild("FinalDrive")
		if fd and fd:IsA("StringValue") then
			table.insert(entries, { name = "FinalDrive", value = fd.Value })
		elseif fd and fd:IsA("NumberValue") then
			table.insert(entries, { name = "FinalDrive", value = tostring(fd.Value) })
		end

		-- FD2, FD3 … (any StringValue matching pattern)
		local numbered = {}
		for _, v in ipairs(Stats:GetChildren()) do
			if v.Name:match(CFG.FD_PATTERN) and v:IsA("StringValue") then
				table.insert(numbered, v)
			end
		end
		-- Sort by number suffix
		table.sort(numbered, function(a, b)
			local na = tonumber(a.Name:match("%d+"))
			local nb = tonumber(b.Name:match("%d+"))
			return na < nb
		end)
		for _, v in ipairs(numbered) do
			table.insert(entries, { name = v.Name, value = v.Value })
		end

		return entries
	end

	-- ============================================================
	-- GUI
	-- ============================================================
	local W, H_LIST, H_DETAIL = 220, 180, 200

	local gui = Instance.new("ScreenGui")
	gui.Name = "FinalDriveBrowserGUI"
	gui.ResetOnSpawn = false
	gui.Parent = plr.PlayerGui

	-- ── ROOT FRAME ──────────────────────────────────────────────
	local rootFrame = Instance.new("Frame")
	rootFrame.Name = "Root"
	rootFrame.Size = UDim2.new(0, W, 0, H_LIST + 22)
	rootFrame.Position = UDim2.new(1, -(W + 12), 1, -(H_LIST + 22 + 12))
	rootFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	rootFrame.BackgroundTransparency = 0.30
	rootFrame.BorderSizePixel = 1
	rootFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
	rootFrame.Parent = gui

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 22)
	titleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	titleBar.BackgroundTransparency = 0.2
	titleBar.BorderSizePixel = 0
	titleBar.Parent = rootFrame

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -8, 1, 0)
	titleLbl.Position = UDim2.new(0, 8, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "FINAL DRIVE BROWSER"
	titleLbl.TextColor3 = Color3.fromRGB(160, 160, 160)
	titleLbl.Font = Enum.Font.Code
	titleLbl.TextSize = 10
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = titleBar

	-- Dot indicator
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 6, 0, 6)
	dot.Position = UDim2.new(1, -14, 0.5, -3)
	dot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	dot.BorderSizePixel = 0
	dot.Parent = titleBar

	-- ── LIST PANEL ───────────────────────────────────────────────
	local listPanel = Instance.new("Frame")
	listPanel.Name = "ListPanel"
	listPanel.Size = UDim2.new(1, 0, 0, H_LIST)
	listPanel.Position = UDim2.new(0, 0, 0, 22)
	listPanel.BackgroundTransparency = 1
	listPanel.Parent = rootFrame

	local listScroll = Instance.new("ScrollingFrame")
	listScroll.Size = UDim2.new(1, 0, 1, 0)
	listScroll.BackgroundTransparency = 1
	listScroll.BorderSizePixel = 0
	listScroll.ScrollBarThickness = 3
	listScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
	listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	listScroll.Parent = listPanel

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 1)
	listLayout.Parent = listScroll

	-- ── DETAIL PANEL (hidden by default) ────────────────────────
	local detailPanel = Instance.new("Frame")
	detailPanel.Name = "DetailPanel"
	detailPanel.Size = UDim2.new(1, 0, 0, H_DETAIL)
	detailPanel.Position = UDim2.new(0, 0, 0, 22)
	detailPanel.BackgroundTransparency = 1
	detailPanel.Visible = false
	detailPanel.Parent = rootFrame

	-- Back button tab strip
	local tabStrip = Instance.new("Frame")
	tabStrip.Size = UDim2.new(1, 0, 0, 20)
	tabStrip.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	tabStrip.BackgroundTransparency = 0.1
	tabStrip.BorderSizePixel = 0
	tabStrip.Parent = detailPanel

	local backBtn = Instance.new("TextButton")
	backBtn.Size = UDim2.new(0, 60, 1, 0)
	backBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	backBtn.BackgroundTransparency = 0.2
	backBtn.BorderSizePixel = 0
	backBtn.Text = "← back"
	backBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
	backBtn.Font = Enum.Font.Code
	backBtn.TextSize = 9
	backBtn.Parent = tabStrip

	local detailTitle = Instance.new("TextLabel")
	detailTitle.Size = UDim2.new(1, -68, 1, 0)
	detailTitle.Position = UDim2.new(0, 68, 0, 0)
	detailTitle.BackgroundTransparency = 1
	detailTitle.Text = ""
	detailTitle.TextColor3 = Color3.fromRGB(130, 130, 130)
	detailTitle.Font = Enum.Font.Code
	detailTitle.TextSize = 9
	detailTitle.TextXAlignment = Enum.TextXAlignment.Left
	detailTitle.TextTruncate = Enum.TextTruncate.AtEnd
	detailTitle.Parent = tabStrip

	local detailScroll = Instance.new("ScrollingFrame")
	detailScroll.Size = UDim2.new(1, 0, 1, -20)
	detailScroll.Position = UDim2.new(0, 0, 0, 20)
	detailScroll.BackgroundTransparency = 1
	detailScroll.BorderSizePixel = 0
	detailScroll.ScrollBarThickness = 3
	detailScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
	detailScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	detailScroll.Parent = detailPanel

	local detailLayout = Instance.new("UIListLayout")
	detailLayout.SortOrder = Enum.SortOrder.LayoutOrder
	detailLayout.Padding = UDim.new(0, 1)
	detailLayout.Parent = detailScroll

	-- ============================================================
	-- UI BUILDERS
	-- ============================================================
	local function makeVehicleRow(vehicle, order)
		local btn = Instance.new("TextButton")
		btn.Name = vehicle.Name
		btn.Size = UDim2.new(1, 0, 0, 22)
		btn.LayoutOrder = order
		btn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
		btn.BackgroundTransparency = 0.1
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.Parent = listScroll

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -28, 1, 0)
		nameLbl.Position = UDim2.new(0, 10, 0, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = vehicle.Name
		nameLbl.TextColor3 = Color3.fromRGB(170, 170, 170)
		nameLbl.Font = Enum.Font.Code
		nameLbl.TextSize = 10
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.Parent = btn

		local arrow = Instance.new("TextLabel")
		arrow.Size = UDim2.new(0, 18, 1, 0)
		arrow.Position = UDim2.new(1, -20, 0, 0)
		arrow.BackgroundTransparency = 1
		arrow.Text = "›"
		arrow.TextColor3 = Color3.fromRGB(80, 80, 80)
		arrow.Font = Enum.Font.Code
		arrow.TextSize = 12
		arrow.Parent = btn

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
		end)

		return btn
	end

	local function makeDetailRow(entry, order, isFirst)
		local row = Instance.new("Frame")
		row.Name = entry.name
		row.Size = UDim2.new(1, 0, 0, 24)
		row.LayoutOrder = order
		row.BackgroundColor3 = isFirst
			and Color3.fromRGB(30, 35, 30)
			or  Color3.fromRGB(24, 24, 24)
		row.BackgroundTransparency = 0.1
		row.BorderSizePixel = 0
		row.Parent = detailScroll

		local keyLbl = Instance.new("TextLabel")
		keyLbl.Size = UDim2.new(0.45, -4, 1, 0)
		keyLbl.Position = UDim2.new(0, 10, 0, 0)
		keyLbl.BackgroundTransparency = 1
		keyLbl.Text = entry.name
		keyLbl.TextColor3 = isFirst
			and Color3.fromRGB(110, 190, 110)
			or  Color3.fromRGB(120, 120, 120)
		keyLbl.Font = Enum.Font.Code
		keyLbl.TextSize = 10
		keyLbl.TextXAlignment = Enum.TextXAlignment.Left
		keyLbl.Parent = row

		local valLbl = Instance.new("TextLabel")
		valLbl.Size = UDim2.new(0.55, -10, 1, 0)
		valLbl.Position = UDim2.new(0.45, 0, 0, 0)
		valLbl.BackgroundTransparency = 1
		valLbl.Text = entry.value
		valLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
		valLbl.Font = Enum.Font.Code
		valLbl.TextSize = 10
		valLbl.TextXAlignment = Enum.TextXAlignment.Left
		valLbl.TextTruncate = Enum.TextTruncate.AtEnd
		valLbl.Parent = row

		return row
	end

	local function makeEmptyRow(msg)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 28)
		lbl.BackgroundTransparency = 1
		lbl.Text = msg
		lbl.TextColor3 = Color3.fromRGB(70, 70, 70)
		lbl.Font = Enum.Font.Code
		lbl.TextSize = 9
		lbl.Parent = detailScroll
	end

	-- ============================================================
	-- NAVIGATION
	-- ============================================================
	local function showDetail(vehicle)
		State.selectedVehicle = vehicle
		detailTitle.Text = vehicle.Name .. "  ›  Stats"

		-- Clear old rows
		for _, c in ipairs(detailScroll:GetChildren()) do
			if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
		end

		local entries = getFDEntries(vehicle)
		if #entries == 0 then
			makeEmptyRow("no FD values found in Stats")
		else
			for i, entry in ipairs(entries) do
				makeDetailRow(entry, i, i == 1 and entry.name == "FinalDrive")
			end
		end

		-- Resize root to detail height
		rootFrame.Size = UDim2.new(0, W, 0, H_DETAIL + 22)
		detailScroll.CanvasSize = UDim2.new(0, 0, 0, #entries * 25)

		listPanel.Visible  = false
		detailPanel.Visible = true

		dot.BackgroundColor3 = Color3.fromRGB(80, 160, 200)
	end

	local function showList()
		State.selectedVehicle = nil
		listPanel.Visible  = true
		detailPanel.Visible = false
		rootFrame.Size = UDim2.new(0, W, 0, H_LIST + 22)
		dot.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
	end

	backBtn.MouseButton1Click:Connect(showList)

	-- ============================================================
	-- POLL LOOP — refreshes vehicle list
	-- ============================================================
	local loopActive = true

	task.spawn(function()
		while loopActive do
			-- Only refresh list when list panel is visible
			if listPanel.Visible then
				local vehicles = refreshVehicleList()

				-- Diff: rebuild only if names changed
				local changed = (#vehicles ~= #State.vehicles)
				if not changed then
					for i, v in ipairs(vehicles) do
						if not State.vehicles[i] or State.vehicles[i].Name ~= v.Name then
							changed = true
							break
						end
					end
				end

				if changed then
					State.vehicles = vehicles

					-- Clear old buttons
					for _, c in ipairs(listScroll:GetChildren()) do
						if c:IsA("TextButton") then c:Destroy() end
					end

					if #vehicles == 0 then
						dot.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
					else
						dot.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
					end

					for i, vehicle in ipairs(vehicles) do
						local btn = makeVehicleRow(vehicle, i)
						btn.MouseButton1Click:Connect(function()
							showDetail(vehicle)
						end)
					end

					listScroll.CanvasSize = UDim2.new(0, 0, 0, #vehicles * 23)
				end
			end

			task.wait(CFG.POLL_RATE)
		end
	end)

	State._killLoop = function() loopActive = false end

	print("[ModMenu] Final Drive Browser loaded")

	plugin._gui      = gui
	plugin._state    = State
	plugin._killLoop = State._killLoop
end

function plugin.destroy()
	if plugin._killLoop then
		plugin._killLoop()
		plugin._killLoop = nil
	end

	if plugin._gui and plugin._gui.Parent then
		plugin._gui:Destroy()
	end
	plugin._gui = nil

	print("[ModMenu] Final Drive Browser unloaded")
end

return plugin
