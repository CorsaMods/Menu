local plugin = {
	name    = "Texture Studio v2",
	version = "3.0",
	author  = "Kyoshin"
}

function plugin.init()
	local Players        = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local plr            = Players.LocalPlayer
	local pname          = plr.Name
	local workspace      = game.Workspace

	-- ============================================================
	-- DATA MODEL
	-- ============================================================
	--
	-- layers[layerId] = {
	--   id        : string  (unique key)
	--   name      : string
	--   kind      : "Texture" | "Decal"
	--   assetId   : string
	--   face      : Enum.NormalId
	--   visible   : bool
	--   studsU    : number   (Texture only)
	--   studsV    : number   (Texture only)
	--   offsetU   : number   (Texture only)
	--   offsetV   : number   (Texture only)
	--   targets   : { [partRef] = true }   -- BasePart instances
	-- }
	--
	-- layerOrder[partRef] = { layerId, layerId, ... }  (top = index 1)
	--
	local Layers     = {}   -- id -> layer def
	local LayerOrder = {}   -- partRef -> ordered list of layer ids
	local layerCounter = 0

	local function newId()
		layerCounter = layerCounter + 1
		return "L" .. layerCounter
	end

	local function newLayer(kind, partRef)
		local id = newId()
		Layers[id] = {
			id      = id,
			name    = kind .. " " .. layerCounter,
			kind    = kind,
			assetId = "rbxassetid://",
			face    = Enum.NormalId.Top,
			visible = true,
			studsU  = 6,
			studsV  = 6,
			offsetU = 0,
			offsetV = 0,
			targets = {},
		}
		if partRef then
			Layers[id].targets[partRef] = true
		end
		return id
	end

	local function getOrInitOrder(partRef)
		if not LayerOrder[partRef] then
			LayerOrder[partRef] = {}
		end
		return LayerOrder[partRef]
	end

	local function addLayerTopart(id, partRef)
		local order = getOrInitOrder(partRef)
		table.insert(order, 1, id)   -- new layers on top
	end

	local function removeLayerFromPart(id, partRef)
		local order = LayerOrder[partRef]
		if not order then return end
		for i = #order, 1, -1 do
			if order[i] == id then
				table.remove(order, i)
			end
		end
	end

	-- ============================================================
	-- ROBLOX INSTANCE MANAGEMENT
	-- ============================================================
	local INSTANCE_TAG = "TStudio_"

	local function getInstanceName(layerId, kind)
		return INSTANCE_TAG .. kind .. "_" .. layerId
	end

	local function applyLayerToInstance(layer, part)
		if not part or not part:IsA("BasePart") then return end
		if not layer.visible then
			-- hide: destroy if exists
			for _, ch in ipairs(part:GetChildren()) do
				if ch.Name == getInstanceName(layer.id, layer.kind) then
					ch:Destroy()
				end
			end
			return
		end

		local instName = getInstanceName(layer.id, layer.kind)
		local existing = part:FindFirstChild(instName)
		if existing then existing:Destroy() end

		local inst = Instance.new(layer.kind)
		inst.Name    = instName
		inst.Texture = layer.assetId
		inst.Face    = layer.face
		if layer.kind == "Texture" then
			inst.StudsPerTileU = layer.studsU
			inst.StudsPerTileV = layer.studsV
			inst.OffsetStudsU  = layer.offsetU
			inst.OffsetStudsV  = layer.offsetV
		end
		inst.Parent = part
	end

	local function removeLayerFromInstance(layer, part)
		if not part then return end
		local instName = getInstanceName(layer.id, layer.kind)
		local ch = part:FindFirstChild(instName)
		if ch then ch:Destroy() end
	end

	local function applyLayer(layerId)
		local layer = Layers[layerId]
		if not layer then return end
		for part, _ in pairs(layer.targets) do
			applyLayerToInstance(layer, part)
		end
	end

	local function applyAllLayers()
		for id, _ in pairs(Layers) do
			applyLayer(id)
		end
	end

	local function removeLayer(layerId)
		local layer = Layers[layerId]
		if not layer then return end
		for part, _ in pairs(layer.targets) do
			removeLayerFromInstance(layer, part)
		end
		-- remove from all part orders
		for partRef, order in pairs(LayerOrder) do
			for i = #order, 1, -1 do
				if order[i] == layerId then table.remove(order, i) end
			end
		end
		Layers[layerId] = nil
	end

	-- ============================================================
	-- PATH / TREE
	-- ============================================================
	local function getPlayerFolder()
		local avs = workspace:FindFirstChild("AVehicleStorage")
		if not avs then return nil end
		return avs:FindFirstChild(pname)
	end

	local function collectTree(root, depth, out, maxDepth)
		maxDepth = maxDepth or 7
		if depth > maxDepth then return end
		for _, child in ipairs(root:GetChildren()) do
			if child:IsA("BasePart") then
				table.insert(out, { inst = child, depth = depth, isFolder = false, label = child.Name })
			elseif child:IsA("Model") or child:IsA("Folder") then
				table.insert(out, { inst = child, depth = depth, isFolder = true,  label = child.Name })
				collectTree(child, depth + 1, out, maxDepth)
			end
		end
	end

	-- ============================================================
	-- UI STATE
	-- ============================================================
	local UI = {
		selectedPart  = nil,   -- BasePart
		selectedLayer = nil,   -- layer id string
		treeRows      = {},    -- TextButton refs for cleanup
		layerRows     = {},    -- Frame refs for cleanup
	}

	-- ============================================================
	-- COLOURS (reused)
	-- ============================================================
	local C = {
		bg0     = Color3.fromRGB(8,  8,  8),
		bg1     = Color3.fromRGB(10, 10, 10),
		bg2     = Color3.fromRGB(14, 14, 14),
		bg3     = Color3.fromRGB(18, 18, 18),
		border  = Color3.fromRGB(22, 22, 22),
		border2 = Color3.fromRGB(32, 32, 32),
		dimText = Color3.fromRGB(40, 40, 40),
		midText = Color3.fromRGB(60, 60, 60),
		text    = Color3.fromRGB(130,130,130),
		accent  = Color3.fromRGB(80, 135, 200),
		accentBg= Color3.fromRGB(12, 22, 42),
		accentBd= Color3.fromRGB(22, 42, 80),
		purple  = Color3.fromRGB(100, 70, 160),
		purpleBg= Color3.fromRGB(18, 10, 30),
		green   = Color3.fromRGB(55, 160, 75),
		greenBg = Color3.fromRGB(10, 24, 12),
		red     = Color3.fromRGB(160, 60, 45),
		redBg   = Color3.fromRGB(28, 10, 8),
	}

	-- ============================================================
	-- GUI ROOT
	-- ============================================================
	local gui = Instance.new("ScreenGui")
	gui.Name           = "TextureStudio3GUI"
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent         = plr.PlayerGui

	local window = Instance.new("Frame")
	window.Name             = "Window"
	window.Size             = UDim2.new(0, 620, 0, 430)
	window.Position         = UDim2.new(0.5, -310, 0.5, -215)
	window.BackgroundColor3 = C.bg1
	window.BorderSizePixel  = 0
	window.ClipsDescendants = true
	window.Parent           = gui
	Instance.new("UICorner", window).CornerRadius = UDim.new(0, 8)
	local winStroke = Instance.new("UIStroke", window)
	winStroke.Color = C.border2; winStroke.Thickness = 1

	-- Title bar
	local tbar = Instance.new("Frame")
	tbar.Size             = UDim2.new(1, 0, 0, 28)
	tbar.BackgroundColor3 = C.bg0
	tbar.BorderSizePixel  = 0
	tbar.Parent           = window

	local function makeLabel(parent, text, size, color, font, xAlign, pos, siz)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Text            = text
		l.TextColor3      = color
		l.Font            = font or Enum.Font.Code
		l.TextSize        = size
		l.TextXAlignment  = xAlign or Enum.TextXAlignment.Left
		l.Position        = pos  or UDim2.new(0,0,0,0)
		l.Size            = siz  or UDim2.new(1,0,1,0)
		l.Parent          = parent
		return l
	end

	makeLabel(tbar, "TEXTURE STUDIO  ·  v3.0", 9, C.dimText, Enum.Font.Code,
		Enum.TextXAlignment.Center, UDim2.new(0,0,0,0), UDim2.new(1,0,1,0))

	local playerTag = makeLabel(tbar, pname, 8, Color3.fromRGB(28,28,28), Enum.Font.Code,
		Enum.TextXAlignment.Right, UDim2.new(0,0,0,0), UDim2.new(1,-36,1,0))

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0,28,1,0); closeBtn.Position = UDim2.new(1,-28,0,0)
	closeBtn.BackgroundTransparency = 1; closeBtn.Text = "×"
	closeBtn.TextColor3 = Color3.fromRGB(55,55,55); closeBtn.Font = Enum.Font.Code
	closeBtn.TextSize = 14; closeBtn.Parent = tbar

	-- Drag
	do
		local drag, start, startPos
		tbar.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				drag = true; start = i.Position; startPos = window.Position
			end
		end)
		tbar.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
				local d = i.Position - start
				window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
	end

	-- Body frame
	local body = Instance.new("Frame")
	body.Size = UDim2.new(1,0,1,-28); body.Position = UDim2.new(0,0,0,28)
	body.BackgroundTransparency = 1; body.Parent = window

	-- ── Column builder helper ────────────────────────────────────
	local function makeColumn(parent, x, w, color)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(0,w,1,0); f.Position = UDim2.new(0,x,0,0)
		f.BackgroundColor3 = color; f.BorderSizePixel = 0
		f.Parent = parent
		if x + w < 620 then
			local sep = Instance.new("Frame")
			sep.Size = UDim2.new(0,1,1,0); sep.Position = UDim2.new(1,-1,0,0)
			sep.BackgroundColor3 = C.border; sep.BorderSizePixel = 0
			sep.Parent = f
		end
		return f
	end

	local function makeColHeader(parent, text, hasAddBtn, addCb, addBtnText)
		local hdr = Instance.new("Frame")
		hdr.Size = UDim2.new(1,0,0,24); hdr.BackgroundColor3 = C.bg0
		hdr.BorderSizePixel = 0; hdr.Parent = parent
		local lbl = makeLabel(hdr, text, 8, C.dimText, Enum.Font.Code,
			Enum.TextXAlignment.Left, UDim2.new(0,8,0,0), UDim2.new(1,-30,1,0))
		if hasAddBtn then
			local ab = Instance.new("TextButton")
			ab.Size = UDim2.new(0,22,1,0); ab.Position = UDim2.new(1,-24,0,0)
			ab.BackgroundTransparency = 1; ab.Text = addBtnText or "+"
			ab.TextColor3 = C.dimText; ab.Font = Enum.Font.Code; ab.TextSize = 12
			ab.Parent = hdr
			ab.Activated:Connect(addCb or function() end)
			return hdr, ab
		end
		return hdr
	end

	-- ============================================================
	-- COLUMN 1 – PART TREE
	-- ============================================================
	local colTree = makeColumn(body, 0, 150, C.bg0)
	local treeHdr, refreshBtn = makeColHeader(colTree, "PARTS", true, nil, "↺")

	local treeScroll = Instance.new("ScrollingFrame")
	treeScroll.Size = UDim2.new(1,0,1,-24); treeScroll.Position = UDim2.new(0,0,0,24)
	treeScroll.BackgroundTransparency = 1; treeScroll.BorderSizePixel = 0
	treeScroll.ScrollBarThickness = 2; treeScroll.CanvasSize = UDim2.new(0,0,0,0)
	treeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	treeScroll.ScrollBarImageColor3 = C.border2; treeScroll.Parent = colTree
	Instance.new("UIListLayout", treeScroll).SortOrder = Enum.SortOrder.LayoutOrder

	-- ============================================================
	-- COLUMN 2 – LAYER STACK
	-- ============================================================
	local colLayers = makeColumn(body, 150, 172, C.bg1)
	local layerHdrFrame = makeColHeader(colLayers, "LAYERS", false)

	-- Dynamic label in layer header showing selected part name
	local layerPartTag = makeLabel(layerHdrFrame, "", 8, Color3.fromRGB(24,24,24),
		Enum.Font.Code, Enum.TextXAlignment.Right,
		UDim2.new(0,0,0,0), UDim2.new(1,-8,1,0))

	local layerScroll = Instance.new("ScrollingFrame")
	layerScroll.Size = UDim2.new(1,0,1,-52); layerScroll.Position = UDim2.new(0,0,0,24)
	layerScroll.BackgroundTransparency = 1; layerScroll.BorderSizePixel = 0
	layerScroll.ScrollBarThickness = 2; layerScroll.CanvasSize = UDim2.new(0,0,0,0)
	layerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	layerScroll.ScrollBarImageColor3 = C.border2; layerScroll.Parent = colLayers
	Instance.new("UIListLayout", layerScroll).SortOrder = Enum.SortOrder.LayoutOrder

	local layerAddBar = Instance.new("Frame")
	layerAddBar.Size = UDim2.new(1,0,0,28); layerAddBar.Position = UDim2.new(0,0,1,-28)
	layerAddBar.BackgroundColor3 = C.bg0; layerAddBar.BorderSizePixel = 0
	layerAddBar.Parent = colLayers
	local layerAddLine = Instance.new("Frame")
	layerAddLine.Size = UDim2.new(1,0,0,1); layerAddLine.BackgroundColor3 = C.border
	layerAddLine.BorderSizePixel = 0; layerAddLine.Parent = layerAddBar

	local function makeAddBtn(text, xPos, color, bgColor)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0,72,0,20); b.Position = UDim2.new(0, xPos, 0.5, -10)
		b.BackgroundColor3 = bgColor; b.BorderSizePixel = 0
		b.Text = text; b.TextColor3 = color
		b.Font = Enum.Font.Code; b.TextSize = 9
		b.Parent = layerAddBar
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 3)
		local s = Instance.new("UIStroke", b); s.Color = color; s.Thickness = 0.5; s.Transparency = 0.5
		return b
	end
	local addTexBtn = makeAddBtn("+ Texture", 8,  C.accent,  C.accentBg)
	local addDecBtn = makeAddBtn("+ Decal",   86, C.purple, C.purpleBg)

	-- ============================================================
	-- COLUMN 3 – PROPERTIES
	-- ============================================================
	local colProps = makeColumn(body, 322, 298, C.bg1)
	local propsHdrFrame = makeColHeader(colProps, "PROPERTIES", false)
	local propsLayerTag = makeLabel(propsHdrFrame, "", 8, Color3.fromRGB(24,24,24),
		Enum.Font.Code, Enum.TextXAlignment.Right,
		UDim2.new(0,0,0,0), UDim2.new(1,-8,1,0))

	local propsScroll = Instance.new("ScrollingFrame")
	propsScroll.Size = UDim2.new(1,0,1,-60); propsScroll.Position = UDim2.new(0,0,0,24)
	propsScroll.BackgroundTransparency = 1; propsScroll.BorderSizePixel = 0
	propsScroll.ScrollBarThickness = 2; propsScroll.CanvasSize = UDim2.new(0,0,0,0)
	propsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	propsScroll.ScrollBarImageColor3 = C.border2; propsScroll.Parent = colProps
	local propsLayout = Instance.new("UIListLayout", propsScroll)
	propsLayout.SortOrder = Enum.SortOrder.LayoutOrder

	-- Bottom action bar
	local bottomBar = Instance.new("Frame")
	bottomBar.Size = UDim2.new(1,0,0,36); bottomBar.Position = UDim2.new(0,0,1,-36)
	bottomBar.BackgroundColor3 = C.bg0; bottomBar.BorderSizePixel = 0
	bottomBar.Parent = colProps
	local bottomLine = Instance.new("Frame")
	bottomLine.Size = UDim2.new(1,0,0,1); bottomLine.BackgroundColor3 = C.border
	bottomLine.BorderSizePixel = 0; bottomLine.Parent = bottomBar

	local statsLbl = makeLabel(bottomBar, "", 8, C.dimText, Enum.Font.Code,
		Enum.TextXAlignment.Left, UDim2.new(0,10,0,0), UDim2.new(1,-200,1,0))

	local function makeActionBtn(text, xOff, color, bgColor, bdColor)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0,58,0,22); b.Position = UDim2.new(1,xOff,0.5,-11)
		b.BackgroundColor3 = bgColor; b.BorderSizePixel = 0
		b.Text = text; b.TextColor3 = color
		b.Font = Enum.Font.Code; b.TextSize = 9
		b.Parent = bottomBar
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,3)
		Instance.new("UIStroke", b).Color = bdColor
		return b
	end
	local removeLayerBtn = makeActionBtn("Remove", -196, C.red,   C.redBg,   C.red)
	local applyAllBtn    = makeActionBtn("Apply all", -132, C.green, C.greenBg, C.green)
	local applyBtn       = makeActionBtn("Apply ▸", -68,  C.accent, C.accentBg, C.accent)

	-- ============================================================
	-- TOAST
	-- ============================================================
	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(0,280,0,28); toast.Position = UDim2.new(0.5,-140,1,-48)
	toast.BackgroundColor3 = C.bg0; toast.BorderSizePixel = 0
	toast.BackgroundTransparency = 1; toast.Parent = gui
	Instance.new("UICorner", toast).CornerRadius = UDim.new(0,6)
	Instance.new("UIStroke", toast).Color = C.border2

	local toastTxt = makeLabel(toast, "", 10, C.green, Enum.Font.Code,
		Enum.TextXAlignment.Center)

	local function showToast(msg, isErr)
		toastTxt.Text = msg
		toastTxt.TextColor3 = isErr and C.red or C.green
		toast.BackgroundTransparency = 0
		task.delay(2.5, function() toast.BackgroundTransparency = 1; toastTxt.Text = "" end)
	end

	-- ============================================================
	-- PROPS PANEL BUILDER
	-- ============================================================
	local propConnections = {}  -- connections to disconnect on rebuild

	local function clearProps()
		for _, conn in ipairs(propConnections) do conn:Disconnect() end
		propConnections = {}
		for _, ch in ipairs(propsScroll:GetChildren()) do
			if not ch:IsA("UIListLayout") then ch:Destroy() end
		end
	end

	local function makePropSection(labelText, order)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1,0,0,24); f.BackgroundTransparency = 1; f.LayoutOrder = order
		f.Parent = propsScroll
		makeLabel(f, labelText, 8, C.dimText, Enum.Font.Code,
			Enum.TextXAlignment.Left, UDim2.new(0,10,0,0), UDim2.new(1,0,1,0))
	end

	local function makePropRow(labelText, value, order, isWide)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1,0,0,26); f.BackgroundTransparency = 1; f.LayoutOrder = order
		f.Parent = propsScroll
		makeLabel(f, labelText, 9, C.midText, Enum.Font.Code,
			Enum.TextXAlignment.Left, UDim2.new(0,10,0,0), UDim2.new(0,100,1,0))
		local w = isWide and 160 or 90
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0,w,0,20); box.Position = UDim2.new(1,-(w+8),0.5,-10)
		box.BackgroundColor3 = C.bg2; box.BorderSizePixel = 0
		box.Text = tostring(value); box.TextColor3 = C.accent
		box.Font = Enum.Font.Code; box.TextSize = 9; box.ClearTextOnFocus = false
		box.Parent = f
		Instance.new("UICorner", box).CornerRadius = UDim.new(0,3)
		local pad = Instance.new("UIPadding", box)
		pad.PaddingLeft = UDim.new(0,5); pad.PaddingRight = UDim.new(0,5)
		local stroke = Instance.new("UIStroke", box); stroke.Color = C.border2; stroke.Thickness = 1
		table.insert(propConnections, box.Focused:Connect(function() stroke.Color = C.accentBd end))
		table.insert(propConnections, box.FocusLost:Connect(function() stroke.Color = C.border2 end))
		return box
	end

	local function makePropPair(lbl1, val1, lbl2, val2, order)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1,0,0,26); f.BackgroundTransparency = 1; f.LayoutOrder = order
		f.Parent = propsScroll
		local function half(x, lbl, val)
			local g = Instance.new("Frame")
			g.Size = UDim2.new(0,140,1,0); g.Position = UDim2.new(0,x,0,0)
			g.BackgroundTransparency = 1; g.Parent = f
			makeLabel(g, lbl, 8, Color3.fromRGB(38,38,38), Enum.Font.Code,
				Enum.TextXAlignment.Left, UDim2.new(0,10,0,0), UDim2.new(0,50,1,0))
			local box = Instance.new("TextBox")
			box.Size = UDim2.new(0,55,0,20); box.Position = UDim2.new(1,-62,0.5,-10)
			box.BackgroundColor3 = C.bg2; box.BorderSizePixel = 0
			box.Text = tostring(val); box.TextColor3 = C.accent
			box.Font = Enum.Font.Code; box.TextSize = 9
			box.TextXAlignment = Enum.TextXAlignment.Center
			box.ClearTextOnFocus = false; box.Parent = g
			Instance.new("UICorner", box).CornerRadius = UDim.new(0,3)
			local stroke = Instance.new("UIStroke", box); stroke.Color = C.border2; stroke.Thickness = 1
			table.insert(propConnections, box.Focused:Connect(function() stroke.Color = C.accentBd end))
			table.insert(propConnections, box.FocusLost:Connect(function() stroke.Color = C.border2 end))
			return box
		end
		local b1 = half(0, lbl1, val1)
		local b2 = half(146, lbl2, val2)
		return b1, b2
	end

	local FACE_NAMES = { "Top","Bottom","Front","Back","Left","Right" }
	local FACE_MAP   = {}
	for _, n in ipairs(FACE_NAMES) do FACE_MAP[n] = Enum.NormalId[n] end
	local FACE_REV   = {}
	for k,v in pairs(FACE_MAP) do FACE_REV[v] = k end

	local function makeFaceDropdown(current, order, onChange)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1,0,0,26); f.BackgroundTransparency = 1; f.LayoutOrder = order
		f.Parent = propsScroll
		makeLabel(f, "Face", 9, C.midText, Enum.Font.Code,
			Enum.TextXAlignment.Left, UDim2.new(0,10,0,0), UDim2.new(0,100,1,0))

		local selected  = FACE_REV[current] or "Top"
		local dropOpen  = false

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0,90,0,20); btn.Position = UDim2.new(1,-98,0.5,-10)
		btn.BackgroundColor3 = C.bg2; btn.BorderSizePixel = 0
		btn.Text = selected .. "  ▾"; btn.TextColor3 = C.accent
		btn.Font = Enum.Font.Code; btn.TextSize = 9; btn.Parent = f
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,3)
		Instance.new("UIStroke", btn).Color = C.border2

		local popup = Instance.new("Frame")
		popup.Size = UDim2.new(0,90,0,#FACE_NAMES*20); popup.BackgroundColor3 = C.bg2
		popup.BorderSizePixel = 0; popup.ZIndex = 30; popup.Visible = false
		popup.Parent = window
		Instance.new("UICorner", popup).CornerRadius = UDim.new(0,4)
		Instance.new("UIStroke", popup).Color = C.border2
		Instance.new("UIListLayout", popup).SortOrder = Enum.SortOrder.LayoutOrder

		for i, name in ipairs(FACE_NAMES) do
			local item = Instance.new("TextButton")
			item.Size = UDim2.new(1,0,0,20); item.BackgroundTransparency = 1
			item.Text = name; item.Font = Enum.Font.Code; item.TextSize = 9
			item.TextColor3 = name == selected and C.accent or C.dimText
			item.ZIndex = 31; item.LayoutOrder = i; item.Parent = popup
			table.insert(propConnections, item.MouseEnter:Connect(function()
				item.BackgroundTransparency = 0; item.BackgroundColor3 = C.bg3
			end))
			table.insert(propConnections, item.MouseLeave:Connect(function()
				item.BackgroundTransparency = 1
			end))
			table.insert(propConnections, item.Activated:Connect(function()
				selected = name; btn.Text = name .. "  ▾"
				popup.Visible = false; dropOpen = false
				if onChange then onChange(FACE_MAP[name]) end
			end))
		end

		table.insert(propConnections, btn.Activated:Connect(function()
			dropOpen = not dropOpen
			if dropOpen then
				local abs = btn.AbsolutePosition; local winAbs = window.AbsolutePosition
				popup.Position = UDim2.new(0, abs.X - winAbs.X, 0, abs.Y - winAbs.Y + 22)
			end
			popup.Visible = dropOpen
		end))

		return btn
	end

	-- Targets sub-panel
	local function makeTargetsPanel(layer, order)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1,0,0,0); f.AutomaticSize = Enum.AutomaticSize.Y
		f.BackgroundTransparency = 1; f.LayoutOrder = order; f.Parent = propsScroll

		makePropSection("TARGET PARTS", 0)  -- visual header already placed by caller

		local chipArea = Instance.new("Frame")
		chipArea.Size = UDim2.new(1,-16,0,0); chipArea.Position = UDim2.new(0,8,0,24)
		chipArea.AutomaticSize = Enum.AutomaticSize.Y
		chipArea.BackgroundColor3 = C.bg2; chipArea.BorderSizePixel = 0
		chipArea.Parent = f
		Instance.new("UICorner", chipArea).CornerRadius = UDim.new(0,4)
		Instance.new("UIStroke", chipArea).Color = C.border2
		local chipLayout = Instance.new("UIListLayout", chipArea)
		chipLayout.FillDirection = Enum.FillDirection.Horizontal
		chipLayout.Wraps = true; chipLayout.Padding = UDim.new(0,4)
		local chipPad = Instance.new("UIPadding", chipArea)
		chipPad.PaddingLeft = UDim.new(0,6); chipPad.PaddingRight = UDim.new(0,6)
		chipPad.PaddingTop = UDim.new(0,5); chipPad.PaddingBottom = UDim.new(0,5)

		local rebuildChips  -- forward

		local function addChip(part)
			local chip = Instance.new("Frame")
			chip.BackgroundColor3 = C.accentBg; chip.BorderSizePixel = 0
			chip.AutomaticSize = Enum.AutomaticSize.XY; chip.Parent = chipArea
			Instance.new("UICorner", chip).CornerRadius = UDim.new(1,0)
			Instance.new("UIStroke", chip).Color = C.accentBd
			local cl = Instance.new("UIListLayout", chip)
			cl.FillDirection = Enum.FillDirection.Horizontal
			cl.VerticalAlignment = Enum.VerticalAlignment.Center
			cl.Padding = UDim.new(0,3)
			local cp = Instance.new("UIPadding", chip)
			cp.PaddingLeft = UDim.new(0,7); cp.PaddingRight = UDim.new(0,5)
			cp.PaddingTop = UDim.new(0,3); cp.PaddingBottom = UDim.new(0,3)

			local nameLbl = makeLabel(chip, part.Name, 8, C.accent, Enum.Font.Code,
				Enum.TextXAlignment.Left, UDim2.new(0,0,0,0), UDim2.new(0,0,1,0))
			nameLbl.AutomaticSize = Enum.AutomaticSize.X; nameLbl.LayoutOrder = 0

			local xBtn = Instance.new("TextButton")
			xBtn.BackgroundTransparency = 1; xBtn.Text = "×"
			xBtn.TextColor3 = C.accentBd; xBtn.Font = Enum.Font.Code; xBtn.TextSize = 10
			xBtn.AutomaticSize = Enum.AutomaticSize.XY; xBtn.LayoutOrder = 1; xBtn.Parent = chip
			table.insert(propConnections, xBtn.Activated:Connect(function()
				layer.targets[part] = nil
				chip:Destroy()
			end))
			table.insert(propConnections, xBtn.MouseEnter:Connect(function()
				xBtn.TextColor3 = C.red
			end))
			table.insert(propConnections, xBtn.MouseLeave:Connect(function()
				xBtn.TextColor3 = C.accentBd
			end))
		end

		-- "Add from tree" button
		local addTarget = Instance.new("TextButton")
		addTarget.BackgroundColor3 = C.bg3; addTarget.BorderSizePixel = 0
		addTarget.Text = "+ add selected"; addTarget.TextColor3 = C.dimText
		addTarget.Font = Enum.Font.Code; addTarget.TextSize = 8
		addTarget.AutomaticSize = Enum.AutomaticSize.XY; addTarget.Parent = chipArea
		Instance.new("UICorner", addTarget).CornerRadius = UDim.new(1,0)
		Instance.new("UIStroke", addTarget).Color = C.border
		table.insert(propConnections, addTarget.Activated:Connect(function()
			local part = UI.selectedPart
			if not part then showToast("Select a part in the tree first", true) return end
			if layer.targets[part] then showToast(part.Name .. " already targeted", true) return end
			layer.targets[part] = true
			addChip(part)
		end))

		-- populate existing chips
		for part, _ in pairs(layer.targets) do addChip(part) end

		return f
	end

	-- ============================================================
	-- REBUILD PROPS PANEL FOR SELECTED LAYER
	-- ============================================================
	local function rebuildProps()
		clearProps()
		local layer = UI.selectedLayer and Layers[UI.selectedLayer]

		if not layer then
			propsLayerTag.Text = ""
			local hint = Instance.new("TextLabel")
			hint.Size = UDim2.new(1,0,0,40); hint.BackgroundTransparency = 1
			hint.Text = "Select a layer →"; hint.TextColor3 = C.dimText
			hint.Font = Enum.Font.Code; hint.TextSize = 9
			hint.LayoutOrder = 1; hint.Parent = propsScroll
			return
		end

		propsLayerTag.Text = layer.name

		-- ASSET section
		makePropSection("ASSET", 1)
		local idBox   = makePropRow("Asset ID", layer.assetId, 2, true)
		local nameBox = makePropRow("Name",     layer.name,    3)

		table.insert(propConnections, idBox.FocusLost:Connect(function()
			layer.assetId = idBox.Text:match("^%s*(.-)%s*$")
		end))
		table.insert(propConnections, nameBox.FocusLost:Connect(function()
			local v = nameBox.Text:match("^%s*(.-)%s*$")
			if v ~= "" then layer.name = v end
		end))

		-- TILING (Texture only)
		if layer.kind == "Texture" then
			makePropSection("TILING", 10)
			local suBox, svBox = makePropPair("Studs U", layer.studsU, "Studs V", layer.studsV, 11)
			local ouBox, ovBox = makePropPair("Offset U", layer.offsetU, "Offset V", layer.offsetV, 12)
			table.insert(propConnections, suBox.FocusLost:Connect(function() layer.studsU  = tonumber(suBox.Text) or layer.studsU  end))
			table.insert(propConnections, svBox.FocusLost:Connect(function() layer.studsV  = tonumber(svBox.Text) or layer.studsV  end))
			table.insert(propConnections, ouBox.FocusLost:Connect(function() layer.offsetU = tonumber(ouBox.Text) or layer.offsetU end))
			table.insert(propConnections, ovBox.FocusLost:Connect(function() layer.offsetV = tonumber(ovBox.Text) or layer.offsetV end))
		end

		-- FACE
		makePropSection("FACE", 20)
		makeFaceDropdown(layer.face, 21, function(v) layer.face = v end)

		-- TARGETS
		makePropSection("TARGET PARTS", 30)
		makeTargetsPanel(layer, 31)

		-- spacer
		local sp = Instance.new("Frame")
		sp.Size = UDim2.new(1,0,0,12); sp.BackgroundTransparency = 1
		sp.LayoutOrder = 99; sp.Parent = propsScroll
	end

	-- ============================================================
	-- REBUILD LAYER LIST FOR SELECTED PART
	-- ============================================================
	local function updateStats()
		local partCount = 0
		for _ in pairs(LayerOrder) do partCount = partCount + 1 end
		local layerCount = 0
		for _ in pairs(Layers) do layerCount = layerCount + 1 end
		statsLbl.Text = layerCount .. " layers  ·  " .. partCount .. " parts tracked"
	end

	local function rebuildLayerList()
		for _, r in ipairs(UI.layerRows) do r:Destroy() end
		UI.layerRows = {}

		local part = UI.selectedPart
		layerPartTag.Text = part and part.Name or ""

		if not part then return end

		local order = LayerOrder[part] or {}

		for idx, layerId in ipairs(order) do
			local layer = Layers[layerId]
			if not layer then continue end

			local row = Instance.new("Frame")
			row.Size = UDim2.new(1,0,0,32); row.BackgroundTransparency = 1
			row.LayoutOrder = idx; row.BorderSizePixel = 0; row.Parent = layerScroll
			Instance.new("UIStroke", row).Color = C.border

			local function updateRowBg()
				row.BackgroundTransparency = (UI.selectedLayer == layerId) and 0 or 1
				row.BackgroundColor3 = C.accentBg
			end
			updateRowBg()

			-- Vis toggle
			local visBtn = Instance.new("TextButton")
			visBtn.Size = UDim2.new(0,22,1,0); visBtn.Position = UDim2.new(0,0,0,0)
			visBtn.BackgroundTransparency = 1
			visBtn.Text = layer.visible and "◉" or "○"
			visBtn.TextColor3 = layer.visible and C.green or C.dimText
			visBtn.Font = Enum.Font.Code; visBtn.TextSize = 11; visBtn.Parent = row
			visBtn.Activated:Connect(function()
				layer.visible = not layer.visible
				visBtn.Text = layer.visible and "◉" or "○"
				visBtn.TextColor3 = layer.visible and C.green or C.dimText
			end)

			-- Name + sub
			local infoF = Instance.new("Frame")
			infoF.Size = UDim2.new(1,-44,1,0); infoF.Position = UDim2.new(0,22,0,0)
			infoF.BackgroundTransparency = 1; infoF.Parent = row
			local nameLbl = makeLabel(infoF, layer.name, 9,
				UI.selectedLayer == layerId and C.accent or C.midText,
				Enum.Font.Code, Enum.TextXAlignment.Left,
				UDim2.new(0,0,0,2), UDim2.new(1,-4,0,14))
			nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
			local subLbl = makeLabel(infoF, layer.kind .. "  ·  " .. FACE_REV[layer.face],
				8, C.dimText, Enum.Font.Code, Enum.TextXAlignment.Left,
				UDim2.new(0,0,0,17), UDim2.new(1,-4,0,12))

			-- Kind badge dot
			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0,6,0,6); dot.Position = UDim2.new(1,-14,0.5,-3)
			dot.BackgroundColor3 = layer.kind == "Texture" and C.accent or C.purple
			dot.BorderSizePixel = 0; dot.Parent = row
			Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

			-- Select on click
			row.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 then
					UI.selectedLayer = layerId
					rebuildLayerList()
					rebuildProps()
				end
			end)

			table.insert(UI.layerRows, row)
		end

		updateStats()
	end

	-- ============================================================
	-- REBUILD PART TREE
	-- ============================================================
	local function rebuildTree()
		for _, r in ipairs(UI.treeRows) do r:Destroy() end
		UI.treeRows = {}

		local root = getPlayerFolder()
		if not root then
			local lbl = makeLabel(treeScroll, "  Not in vehicle", 9, C.dimText,
				Enum.Font.Code, Enum.TextXAlignment.Left, UDim2.new(0,0,0,0), UDim2.new(1,0,0,32))
			lbl.LayoutOrder = 1; table.insert(UI.treeRows, lbl)
			return
		end

		local nodes = {}
		collectTree(root, 0, nodes)

		for i, node in ipairs(nodes) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1,0,0,22); btn.BorderSizePixel = 0
			btn.BackgroundTransparency = 1
			btn.Font = Enum.Font.Code; btn.TextSize = 9
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.LayoutOrder = i; btn.Parent = treeScroll

			local indent = node.depth * 10 + 8
			local icon   = node.isFolder and "▸ " or "◼ "
			btn.Text = string.rep(" ", node.depth * 2) .. icon .. node.label

			local isSel = (not node.isFolder) and (UI.selectedPart == node.inst)
			btn.BackgroundColor3 = C.accentBg
			btn.BackgroundTransparency = isSel and 0 or 1
			btn.TextColor3 = isSel and C.accent
				or (node.isFolder and C.dimText or C.midText)

			if not node.isFolder then
				btn.MouseEnter:Connect(function()
					if UI.selectedPart ~= node.inst then
						btn.BackgroundTransparency = 0
						btn.BackgroundColor3 = C.bg3
					end
				end)
				btn.MouseLeave:Connect(function()
					if UI.selectedPart ~= node.inst then
						btn.BackgroundTransparency = 1
					end
				end)
				btn.Activated:Connect(function()
					UI.selectedPart = node.inst
					UI.selectedLayer = nil
					rebuildTree()
					rebuildLayerList()
					rebuildProps()
				end)
			end

			table.insert(UI.treeRows, btn)
		end

		updateStats()
	end

	-- ============================================================
	-- WIRE UP BUTTONS
	-- ============================================================
	refreshBtn.Activated:Connect(function()
		rebuildTree()
		showToast("Tree refreshed")
	end)

	closeBtn.Activated:Connect(function() gui:Destroy() end)

	local function addNewLayer(kind)
		if not UI.selectedPart then
			showToast("Select a part first", true) return
		end
		local id = newLayer(kind, UI.selectedPart)
		addLayerTopart(id, UI.selectedPart)
		UI.selectedLayer = id
		rebuildLayerList()
		rebuildProps()
		showToast("Added new " .. kind)
	end

	addTexBtn.Activated:Connect(function() addNewLayer("Texture") end)
	addDecBtn.Activated:Connect(function() addNewLayer("Decal") end)

	applyBtn.Activated:Connect(function()
		if not UI.selectedLayer then showToast("No layer selected", true) return end
		local layer = Layers[UI.selectedLayer]
		if not layer then return end
		if layer.assetId == "rbxassetid://" or layer.assetId == "" then
			showToast("Set an Asset ID first", true) return
		end
		local count = 0
		for part, _ in pairs(layer.targets) do
			applyLayerToInstance(layer, part)
			count = count + 1
		end
		if count == 0 then
			showToast("No target parts set", true)
		else
			showToast("Applied to " .. count .. " part(s)")
		end
		rebuildLayerList()
	end)

	applyAllBtn.Activated:Connect(function()
		local applied = 0
		for id, layer in pairs(Layers) do
			if layer.assetId ~= "rbxassetid://" and layer.assetId ~= "" then
				for part, _ in pairs(layer.targets) do
					applyLayerToInstance(layer, part)
					applied = applied + 1
				end
			end
		end
		showToast("Applied all  (" .. applied .. " instances)")
	end)

	removeLayerBtn.Activated:Connect(function()
		if not UI.selectedLayer then showToast("No layer selected", true) return end
		local name = Layers[UI.selectedLayer] and Layers[UI.selectedLayer].name or "?"
		removeLayer(UI.selectedLayer)
		UI.selectedLayer = nil
		rebuildLayerList()
		rebuildProps()
		showToast("Removed: " .. name)
	end)

	-- ============================================================
	-- INITIAL BUILD
	-- ============================================================
	rebuildTree()
	rebuildLayerList()
	rebuildProps()

	plugin._gui   = gui
	plugin._state = { Layers = Layers, LayerOrder = LayerOrder }

	print("[ModMenu] Texture Studio v3.0 loaded")
end

-- ============================================================
-- DESTROY
-- ============================================================
function plugin.destroy()
	if plugin._gui and plugin._gui.Parent then
		-- Best-effort: remove all managed instances from workspace
		if plugin._state then
			for id, layer in pairs(plugin._state.Layers) do
				for part, _ in pairs(layer.targets) do
					if part and part.Parent then
						local instName = "TStudio_" .. layer.kind .. "_" .. id
						local ch = part:FindFirstChild(instName)
						if ch then ch:Destroy() end
					end
				end
			end
		end
		plugin._gui:Destroy()
	end
	plugin._gui   = nil
	plugin._state = nil
	print("[ModMenu] Texture Studio v3.0 unloaded")
end

return plugin
