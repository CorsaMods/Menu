local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("ModMenu") then
    PlayerGui.ModMenu:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- shadow backdrop
local Shadow = Instance.new("Frame")
Shadow.Size = UDim2.new(0, 320, 0, 420)
Shadow.Position = UDim2.new(0.5, -156, 0.5, -206)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.5
Shadow.BorderSizePixel = 0
Shadow.Parent = ScreenGui

-- main frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 320, 0, 420)
Main.Position = UDim2.new(0.5, -160, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

-- red accent bar at top
local AccentBar = Instance.new("Frame")
AccentBar.Size = UDim2.new(1, 0, 0, 3)
AccentBar.BackgroundColor3 = Color3.fromRGB(190, 30, 30)
AccentBar.BorderSizePixel = 0
AccentBar.Parent = Main

-- title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.Position = UDim2.new(0, 0, 0, 3)
TitleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

-- logo small in titlebar
local TitleLogo = Instance.new("ImageLabel")
TitleLogo.Size = UDim2.new(0, 24, 0, 24)
TitleLogo.Position = UDim2.new(0, 10, 0.5, -12)
TitleLogo.BackgroundTransparency = 1
TitleLogo.Image = "rbxassetid://122285902567431"
TitleLogo.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -90, 1, 0)
TitleLabel.Position = UDim2.new(0, 42, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "CORSA LEGENDS  MODS+"
TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
TitleLabel.TextSize = 12
TitleLabel.Font = Enum.Font.Code
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.new(0, 40, 1, 0)
VersionLabel.Position = UDim2.new(1, -80, 0, 0)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text = "v1.0"
VersionLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
VersionLabel.TextSize = 11
VersionLabel.Font = Enum.Font.Code
VersionLabel.Parent = TitleBar

-- close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 36, 1, 0)
CloseBtn.Position = UDim2.new(1, -36, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(160, 30, 30)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.Code
CloseBtn.Parent = TitleBar

CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Shadow.Visible = false
end)

-- tab bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 30)
TabBar.Position = UDim2.new(0, 0, 0, 39)
TabBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

-- divider under tabs
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, 0, 0, 1)
Divider.Position = UDim2.new(0, 0, 1, 0)
Divider.BackgroundColor3 = Color3.fromRGB(190, 30, 30)
Divider.BorderSizePixel = 0
Divider.Parent = TabBar

local tabs = {"BUILT-IN", "CUSTOM"}
local tabButtons = {}
local tabFrames = {}

local function makeScrollFrame(parent)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, -70)
    sf.Position = UDim2.new(0, 0, 0, 70)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 2
    sf.ScrollBarImageColor3 = Color3.fromRGB(190, 30, 30)
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = sf

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = sf

    return sf
end

local function switchTab(index)
    for i, frame in ipairs(tabFrames) do
        frame.Visible = i == index
        tabButtons[i].TextColor3 = i == index
            and Color3.fromRGB(255, 255, 255)
            or Color3.fromRGB(80, 80, 80)
        tabButtons[i].BackgroundColor3 = i == index
            and Color3.fromRGB(18, 18, 18)
            or Color3.fromRGB(10, 10, 10)
    end
end

for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / #tabs, 0, 1, 0)
    btn.Position = UDim2.new((i - 1) / #tabs, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextSize = 11
    btn.Font = Enum.Font.Code
    btn.TextColor3 = Color3.fromRGB(80, 80, 80)
    btn.Parent = TabBar
    tabButtons[i] = btn

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, -70)
    frame.Position = UDim2.new(0, 0, 0, 70)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = Main
    tabFrames[i] = frame

    btn.MouseButton1Click:Connect(function()
        switchTab(i)
    end)
end

switchTab(1)

-- section label
local function addSection(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(190, 30, 30)
    label.TextSize = 10
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

-- plugin row
local function addPluginRow(parent, pluginName, author, enabled)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 48)
    row.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    row.BorderSizePixel = 0
    row.Parent = parent

    -- left red accent stripe
    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(0, 2, 1, 0)
    stripe.BackgroundColor3 = Color3.fromRGB(190, 30, 30)
    stripe.BorderSizePixel = 0
    stripe.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -60, 0, 24)
    nameLabel.Position = UDim2.new(0, 14, 0, 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = pluginName
    nameLabel.TextColor3 = Color3.fromRGB(215, 215, 215)
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.Code
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    local authorLabel = Instance.new("TextLabel")
    authorLabel.Size = UDim2.new(1, -60, 0, 16)
    authorLabel.Position = UDim2.new(0, 14, 0, 27)
    authorLabel.BackgroundTransparency = 1
    authorLabel.Text = author
    authorLabel.TextColor3 = Color3.fromRGB(70, 70, 70)
    authorLabel.TextSize = 10
    authorLabel.Font = Enum.Font.Code
    authorLabel.TextXAlignment = Enum.TextXAlignment.Left
    authorLabel.Parent = row

    local isOn = enabled or false

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 36, 0, 18)
    toggleBtn.Position = UDim2.new(1, -46, 0.5, -9)
    toggleBtn.Text = ""
    toggleBtn.BackgroundColor3 = isOn and Color3.fromRGB(190, 30, 30) or Color3.fromRGB(40, 40, 40)
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
            and Color3.fromRGB(190, 30, 30)
            or Color3.fromRGB(40, 40, 40)
        dot.Position = isOn
            and UDim2.new(1, -15, 0.5, -6)
            or UDim2.new(0, 3, 0.5, -6)
    end)

    return row
end

-- built-in tab
local builtinScroll = makeScrollFrame(tabFrames[1])
addSection(builtinScroll, "VEHICLE")

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size = UDim2.new(1, 0, 0, 30)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text = "no plugins installed yet"
emptyLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
emptyLabel.TextSize = 11
emptyLabel.Font = Enum.Font.Code
emptyLabel.Parent = builtinScroll

-- custom tab
local customScroll = makeScrollFrame(tabFrames[2])
addSection(customScroll, "LOAD CUSTOM PLUGIN")

local urlBox = Instance.new("TextBox")
urlBox.Size = UDim2.new(1, 0, 0, 32)
urlBox.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
urlBox.BorderSizePixel = 0
urlBox.Text = ""
urlBox.PlaceholderText = "paste raw github url..."
urlBox.TextColor3 = Color3.fromRGB(180, 180, 180)
urlBox.PlaceholderColor3 = Color3.fromRGB(50, 50, 50)
urlBox.TextSize = 11
urlBox.Font = Enum.Font.Code
urlBox.ClearTextOnFocus = false
urlBox.Parent = customScroll

-- left border accent on textbox
local urlAccent = Instance.new("Frame")
urlAccent.Size = UDim2.new(0, 2, 1, 0)
urlAccent.BackgroundColor3 = Color3.fromRGB(190, 30, 30)
urlAccent.BorderSizePixel = 0
urlAccent.Parent = urlBox

local loadBtn = Instance.new("TextButton")
loadBtn.Size = UDim2.new(1, 0, 0, 30)
loadBtn.BackgroundColor3 = Color3.fromRGB(190, 30, 30)
loadBtn.BorderSizePixel = 0
loadBtn.Text = "LOAD PLUGIN"
loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loadBtn.TextSize = 11
loadBtn.Font = Enum.Font.Code
loadBtn.Parent = customScroll

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(190, 30, 30)
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.Code
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = customScroll

local loadedSection = addSection(customScroll, "LOADED")

loadBtn.MouseButton1Click:Connect(function()
    local url = urlBox.Text
    if url == "" then return end

    statusLabel.Text = "loading..."
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)

    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)

    if ok and type(result) == "table" and result.init then
        result.init()
        local pName = result.name or "Unknown Plugin"
        local pAuthor = result.author or "unknown"
        statusLabel.Text = "loaded: " .. pName
        statusLabel.TextColor3 = Color3.fromRGB(190, 30, 30)
        addPluginRow(customScroll, pName, "@" .. pAuthor, true)
        urlBox.Text = ""
    else
        statusLabel.Text = "failed to load — check url or plugin format"
        statusLabel.TextColor3 = Color3.fromRGB(180, 50, 50)
    end
end)

-- keybind RightShift to toggle
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        local visible = not Main.Visible
        Main.Visible = visible
        Shadow.Visible = visible
    end
end)

-- footer
local Footer = Instance.new("Frame")
Footer.Size = UDim2.new(1, 0, 0, 24)
Footer.Position = UDim2.new(0, 0, 1, -24)
Footer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
Footer.BorderSizePixel = 0
Footer.Parent = Main

local FooterLabel = Instance.new("TextLabel")
FooterLabel.Size = UDim2.new(1, -10, 1, 0)
FooterLabel.Position = UDim2.new(0, 10, 0, 0)
FooterLabel.BackgroundTransparency = 1
FooterLabel.Text = "RSHIFT to toggle  //  corsamods"
FooterLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
FooterLabel.TextSize = 10
FooterLabel.Font = Enum.Font.Code
FooterLabel.TextXAlignment = Enum.TextXAlignment.Left
FooterLabel.Parent = Footer
