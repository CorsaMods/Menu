local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("ModMenu") then
    PlayerGui.ModMenu:Destroy()
end

-- blur effect behind menu
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- dark overlay
local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 0.55
Overlay.BorderSizePixel = 0
Overlay.Visible = false
Overlay.Parent = ScreenGui

-- main glass frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 300, 0, 440)
Main.Position = UDim2.new(0.5, -150, 0.5, -220)
Main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Main.BackgroundTransparency = 0.88
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Visible = false
Main.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = Main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Transparency = 0.82
mainStroke.Thickness = 0.5
mainStroke.Parent = Main

-- title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 52)
TitleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.BackgroundTransparency = 0.94
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 18)
tbCorner.Parent = TitleBar

-- title bar bottom fill to hide bottom corners
local tbFill = Instance.new("Frame")
tbFill.Size = UDim2.new(1, 0, 0, 18)
tbFill.Position = UDim2.new(0, 0, 1, -18)
tbFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
tbFill.BackgroundTransparency = 0.94
tbFill.BorderSizePixel = 0
tbFill.Parent = TitleBar

local tbDivider = Instance.new("Frame")
tbDivider.Size = UDim2.new(1, 0, 0, 0.5)
tbDivider.Position = UDim2.new(0, 0, 1, -0.5)
tbDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
tbDivider.BackgroundTransparency = 0.88
tbDivider.BorderSizePixel = 0
tbDivider.Parent = TitleBar

-- logo
local Logo = Instance.new("ImageLabel")
Logo.Size = UDim2.new(0, 30, 0, 30)
Logo.Position = UDim2.new(0, 12, 0.5, -15)
Logo.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
Logo.BackgroundTransparency = 0
Logo.BorderSizePixel = 0
Logo.Image = "rbxassetid://122285902567431"
Logo.Parent = TitleBar

local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(0, 8)
logoCorner.Parent = Logo

local TitleName = Instance.new("TextLabel")
TitleName.Size = UDim2.new(1, -100, 0, 18)
TitleName.Position = UDim2.new(0, 50, 0, 9)
TitleName.BackgroundTransparency = 1
TitleName.Text = "Corsa Legends"
TitleName.TextColor3 = Color3.fromRGB(240, 240, 240)
TitleName.TextTransparency = 0.08
TitleName.TextSize = 13
TitleName.Font = Enum.Font.GothamBold
TitleName.TextXAlignment = Enum.TextXAlignment.Left
TitleName.Parent = TitleBar

local TitleSub = Instance.new("TextLabel")
TitleSub.Size = UDim2.new(1, -100, 0, 14)
TitleSub.Position = UDim2.new(0, 50, 0, 28)
TitleSub.BackgroundTransparency = 1
TitleSub.Text = "MODS+   v1.0"
TitleSub.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleSub.TextTransparency = 0.65
TitleSub.TextSize = 10
TitleSub.Font = Enum.Font.Gotham
TitleSub.TextXAlignment = Enum.TextXAlignment.Left
TitleSub.Parent = TitleBar

-- close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.BackgroundTransparency = 0.88
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "x"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextTransparency = 0.5
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = CloseBtn

local closeStroke = Instance.new("UIStroke")
closeStroke.Color = Color3.fromRGB(255, 255, 255)
closeStroke.Transparency = 0.88
closeStroke.Thickness = 0.5
closeStroke.Parent = CloseBtn

-- tab bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -24, 0, 28)
TabBar.Position = UDim2.new(0, 12, 0, 58)
TabBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TabBar.BackgroundTransparency = 0.92
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

local tabCorner = Instance.new("UICorner")
tabCorner.CornerRadius = UDim.new(0, 8)
tabCorner.Parent = TabBar

local tabStroke = Instance.new("UIStroke")
tabStroke.Color = Color3.fromRGB(255, 255, 255)
tabStroke.Transparency = 0.88
tabStroke.Thickness = 0.5
tabStroke.Parent = TabBar

local tabs = {"BUILT-IN", "CUSTOM"}
local tabButtons = {}
local tabFrames = {}

local function makeScrollFrame(parent)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, -98)
    sf.Position = UDim2.new(0, 0, 0, 98)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 2
    sf.ScrollBarImageColor3 = Color3.fromRGB(180, 30, 30)
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = sf

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.Parent = sf

    return sf
end

local function switchTab(index)
    for i, frame in ipairs(tabFrames) do
        frame.Visible = i == index
        tabButtons[i].TextColor3 = i == index
            and Color3.fromRGB(255, 255, 255)
            or Color3.fromRGB(255, 255, 255)
        tabButtons[i].TextTransparency = i == index and 0.05 or 0.6
        tabButtons[i].BackgroundTransparency = i == index and 0.82 or 1
    end
end

for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / #tabs, -2, 1, -4)
    btn.Position = UDim2.new((i - 1) / #tabs, i == 1 and 2 or 0, 0, 2)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextTransparency = 0.6
    btn.Parent = TabBar
    tabButtons[i] = btn

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, -98)
    frame.Position = UDim2.new(0, 0, 0, 98)
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
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 40, 40)
    label.TextSize = 10
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

-- plugin row
local function addPluginRow(parent, pluginName, author, enabled)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 52)
    row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    row.BackgroundTransparency = 0.92
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 12)
    rowCorner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Color = Color3.fromRGB(255, 255, 255)
    rowStroke.Transparency = 0.88
    rowStroke.Thickness = 0.5
    rowStroke.Parent = row

    -- icon box
    local iconBox = Instance.new("Frame")
    iconBox.Size = UDim2.new(0, 32, 0, 32)
    iconBox.Position = UDim2.new(0, 10, 0.5, -16)
    iconBox.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
    iconBox.BackgroundTransparency = 0.7
    iconBox.BorderSizePixel = 0
    iconBox.Parent = row

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = iconBox

    local iconStroke = Instance.new("UIStroke")
    iconStroke.Color = Color3.fromRGB(200, 40, 40)
    iconStroke.Transparency = 0.6
    iconStroke.Thickness = 0.5
    iconStroke.Parent = iconBox

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -100, 0, 20)
    nameLabel.Position = UDim2.new(0, 52, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = pluginName
    nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    nameLabel.TextTransparency = 0.08
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    local authorLabel = Instance.new("TextLabel")
    authorLabel.Size = UDim2.new(1, -100, 0, 14)
    authorLabel.Position = UDim2.new(0, 52, 0, 28)
    authorLabel.BackgroundTransparency = 1
    authorLabel.Text = author
    authorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    authorLabel.TextTransparency = 0.7
    authorLabel.TextSize = 10
    authorLabel.Font = Enum.Font.Gotham
    authorLabel.TextXAlignment = Enum.TextXAlignment.Left
    authorLabel.Parent = row

    local isOn = enabled or false

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 38, 0, 22)
    toggleBtn.Position = UDim2.new(1, -48, 0.5, -11)
    toggleBtn.Text = ""
    toggleBtn.BackgroundColor3 = isOn and Color3.fromRGB(180, 25, 25) or Color3.fromRGB(255, 255, 255)
    toggleBtn.BackgroundTransparency = isOn and 0 or 0.88
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = row

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(1, 0)
    tCorner.Parent = toggleBtn

    local tStroke = Instance.new("UIStroke")
    tStroke.Color = Color3.fromRGB(255, 255, 255)
    tStroke.Transparency = isOn and 1 or 0.82
    tStroke.Thickness = 0.5
    tStroke.Parent = toggleBtn

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = isOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = toggleBtn

    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(1, 0)
    dCorner.Parent = dot

    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        toggleBtn.BackgroundColor3 = isOn and Color3.fromRGB(180, 25, 25) or Color3.fromRGB(255, 255, 255)
        toggleBtn.BackgroundTransparency = isOn and 0 or 0.88
        tStroke.Transparency = isOn and 1 or 0.82
        dot.Position = isOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
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
emptyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
emptyLabel.TextTransparency = 0.75
emptyLabel.TextSize = 11
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.Parent = builtinScroll

-- custom tab
local customScroll = makeScrollFrame(tabFrames[2])
addSection(customScroll, "LOAD CUSTOM PLUGIN")

local urlBox = Instance.new("TextBox")
urlBox.Size = UDim2.new(1, 0, 0, 34)
urlBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
urlBox.BackgroundTransparency = 0.92
urlBox.BorderSizePixel = 0
urlBox.Text = ""
urlBox.PlaceholderText = "paste raw github url..."
urlBox.TextColor3 = Color3.fromRGB(230, 230, 230)
urlBox.PlaceholderColor3 = Color3.fromRGB(255, 255, 255)
urlBox.TextSize = 11
urlBox.Font = Enum.Font.Code
urlBox.ClearTextOnFocus = false
urlBox.Parent = customScroll

local urlCorner = Instance.new("UICorner")
urlCorner.CornerRadius = UDim.new(0, 10)
urlCorner.Parent = urlBox

local urlStroke = Instance.new("UIStroke")
urlStroke.Color = Color3.fromRGB(255, 255, 255)
urlStroke.Transparency = 0.85
urlStroke.Thickness = 0.5
urlStroke.Parent = urlBox

local urlPad = Instance.new("UIPadding")
urlPad.PaddingLeft = UDim.new(0, 10)
urlPad.Parent = urlBox

local loadBtn = Instance.new("TextButton")
loadBtn.Size = UDim2.new(1, 0, 0, 34)
loadBtn.BackgroundColor3 = Color3.fromRGB(180, 25, 25)
loadBtn.BackgroundTransparency = 0.1
loadBtn.BorderSizePixel = 0
loadBtn.Text = "Load Plugin"
loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loadBtn.TextTransparency = 0.05
loadBtn.TextSize = 12
loadBtn.Font = Enum.Font.GothamBold
loadBtn.Parent = customScroll

local loadCorner = Instance.new("UICorner")
loadCorner.CornerRadius = UDim.new(0, 10)
loadCorner.Parent = loadBtn

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 18)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(200, 40, 40)
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = customScroll

addSection(customScroll, "LOADED")

loadBtn.MouseButton1Click:Connect(function()
    local url = urlBox.Text
    if url == "" then return end
    statusLabel.Text = "loading..."
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)

    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)

    if ok and type(result) == "table" and result.init then
        result.init()
        local pName = result.name or "Unknown Plugin"
        local pAuthor = result.author or "unknown"
        statusLabel.Text = "loaded: " .. pName
        statusLabel.TextColor3 = Color3.fromRGB(200, 40, 40)
        addPluginRow(customScroll, pName, "@" .. pAuthor, true)
        urlBox.Text = ""
    else
        statusLabel.Text = "failed — check url or plugin format"
        statusLabel.TextColor3 = Color3.fromRGB(220, 60, 60)
    end
end)

-- footer
local Footer = Instance.new("Frame")
Footer.Size = UDim2.new(1, 0, 0, 28)
Footer.Position = UDim2.new(0, 0, 1, -28)
Footer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Footer.BackgroundTransparency = 0.7
Footer.BorderSizePixel = 0
Footer.Parent = Main

local footCorner = Instance.new("UICorner")
footCorner.CornerRadius = UDim.new(0, 18)
footCorner.Parent = Footer

local footFill = Instance.new("Frame")
footFill.Size = UDim2.new(1, 0, 0, 18)
footFill.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
footFill.BackgroundTransparency = 0.7
footFill.BorderSizePixel = 0
footFill.Parent = Footer

local FooterLabel = Instance.new("TextLabel")
FooterLabel.Size = UDim2.new(1, 0, 1, 0)
FooterLabel.BackgroundTransparency = 1
FooterLabel.Text = "RSHIFT to toggle"
FooterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FooterLabel.TextTransparency = 0.75
FooterLabel.TextSize = 10
FooterLabel.Font = Enum.Font.Gotham
FooterLabel.Parent = Footer

-- toggle menu open/close with blur
local menuOpen = false

local function setMenuVisible(visible)
    menuOpen = visible
    Main.Visible = visible
    Overlay.Visible = visible
    TweenService:Create(blur, TweenInfo.new(0.3), {
        Size = visible and 20 or 0
    }):Play()
end

CloseBtn.MouseButton1Click:Connect(function()
    setMenuVisible(false)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setMenuVisible(not menuOpen)
    end
end)
