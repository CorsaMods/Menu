local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- cleanup old menu if reloaded
if PlayerGui:FindFirstChild("ModMenu") then
    PlayerGui.ModMenu:Destroy()
end

-- base gui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- main frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 300, 0, 400)
Main.Position = UDim2.new(0.5, -150, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

-- title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ MOD MENU v1.0"
TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.Code
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 1, 0)
CloseBtn.Position = UDim2.new(1, -32, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
CloseBtn.TextSize = 13
CloseBtn.Font = Enum.Font.Code
CloseBtn.Parent = TitleBar

CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

-- tab bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 28)
TabBar.Position = UDim2.new(0, 0, 0, 32)
TabBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

local tabs = {"BUILT-IN", "CUSTOM"}
local tabButtons = {}
local tabFrames = {}

-- scroll frame for plugins
local function makeScrollFrame(parent)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, -60)
    sf.Position = UDim2.new(0, 0, 0, 60)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = sf
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = sf
    return sf
end

-- tab switching
local function switchTab(index)
    for i, frame in ipairs(tabFrames) do
        frame.Visible = i == index
        tabButtons[i].TextColor3 = i == index
            and Color3.fromRGB(255, 255, 255)
            or Color3.fromRGB(100, 100, 100)
        tabButtons[i].BackgroundColor3 = i == index
            and Color3.fromRGB(25, 25, 25)
            or Color3.fromRGB(15, 15, 15)
    end
end

-- build tabs
for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#tabs, 0, 1, 0)
    btn.Position = UDim2.new((i-1)/#tabs, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextSize = 11
    btn.Font = Enum.Font.Code
    btn.TextColor3 = Color3.fromRGB(100, 100, 100)
    btn.Parent = TabBar
    tabButtons[i] = btn

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, -60)
    frame.Position = UDim2.new(0, 0, 0, 60)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = Main
    tabFrames[i] = frame

    btn.MouseButton1Click:Connect(function()
        switchTab(i)
    end)
end

switchTab(1)

-- plugin row builder
local function addPluginRow(parent, pluginName, author, enabled)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    row.BorderSizePixel = 0
    row.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -50, 0, 22)
    nameLabel.Position = UDim2.new(0, 10, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = pluginName
    nameLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.Code
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    local authorLabel = Instance.new("TextLabel")
    authorLabel.Size = UDim2.new(1, -50, 0, 16)
    authorLabel.Position = UDim2.new(0, 10, 0, 24)
    authorLabel.BackgroundTransparency = 1
    authorLabel.Text = author
    authorLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
    authorLabel.TextSize = 11
    authorLabel.Font = Enum.Font.Code
    authorLabel.TextXAlignment = Enum.TextXAlignment.Left
    authorLabel.Parent = row

    -- toggle
    local isOn = enabled or false
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 36, 0, 18)
    toggleBtn.Position = UDim2.new(1, -46, 0.5, -9)
    toggleBtn.Text = ""
    toggleBtn.BackgroundColor3 = isOn and Color3.fromRGB(30, 160, 90) or Color3.fromRGB(50, 50, 50)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = row

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(1, 0)
    tCorner.Parent = toggleBtn

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = isOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = toggleBtn

    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(1, 0)
    dCorner.Parent = dot

    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        toggleBtn.BackgroundColor3 = isOn
            and Color3.fromRGB(30, 160, 90)
            or Color3.fromRGB(50, 50, 50)
        dot.Position = isOn
            and UDim2.new(1, -15, 0.5, -6)
            or UDim2.new(0, 3, 0.5, -6)
    end)

    return row
end

-- built-in tab (empty for now, add rows here later)
local builtinScroll = makeScrollFrame(tabFrames[1])

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size = UDim2.new(1, 0, 0, 30)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text = "no plugins yet..."
emptyLabel.TextColor3 = Color3.fromRGB(70, 70, 70)
emptyLabel.TextSize = 12
emptyLabel.Font = Enum.Font.Code
emptyLabel.Parent = builtinScroll

-- custom tab
local customScroll = makeScrollFrame(tabFrames[2])

local urlBox = Instance.new("TextBox")
urlBox.Size = UDim2.new(1, -70, 0, 30)
urlBox.Position = UDim2.new(0, 0, 0, 0)
urlBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
urlBox.BorderSizePixel = 0
urlBox.Text = ""
urlBox.PlaceholderText = "paste raw github url..."
urlBox.TextColor3 = Color3.fromRGB(180, 180, 180)
urlBox.PlaceholderColor3 = Color3.fromRGB(60, 60, 60)
urlBox.TextSize = 11
urlBox.Font = Enum.Font.Code
urlBox.ClearTextOnFocus = false
urlBox.Parent = customScroll

local loadBtn = Instance.new("TextButton")
loadBtn.Size = UDim2.new(0, 58, 0, 30)
loadBtn.Position = UDim2.new(1, -58, 0, 0)
loadBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
loadBtn.BorderSizePixel = 0
loadBtn.Text = "LOAD"
loadBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
loadBtn.TextSize = 11
loadBtn.Font = Enum.Font.Code
loadBtn.Parent = customScroll

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(30, 160, 90)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Code
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = customScroll

-- custom plugin loader
loadBtn.MouseButton1Click:Connect(function()
    local url = urlBox.Text
    if url == "" then return end

    statusLabel.Text = "loading..."
    statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)

    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)

    if ok and type(result) == "table" and result.init then
        result.init()
        local pName = result.name or "Unknown Plugin"
        local pAuthor = result.author or "unknown"
        statusLabel.Text = "✓ loaded: " .. pName
        statusLabel.TextColor3 = Color3.fromRGB(30, 160, 90)
        addPluginRow(customScroll, pName, "@" .. pAuthor, true)
    else
        statusLabel.Text = "✗ failed to load plugin"
        statusLabel.TextColor3 = Color3.fromRGB(180, 50, 50)
    end
end)

-- keybind to toggle menu (RightShift)
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)
