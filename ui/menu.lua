local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
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

-- main window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 240, 0, 420)
Main.Position = UDim2.new(0.5, -120, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Main.BackgroundTransparency = 0.12
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Visible = false
Main.Parent = ScreenGui

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Transparency = 0.92
mainStroke.Thickness = 1
mainStroke.Parent = Main

-- header gradient bg
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 54)
Header.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
Header.BorderSizePixel = 0
Header.Parent = Main

local headerGrad = Instance.new("UIGradient")
headerGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 25, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 10, 10)),
})
headerGrad.Rotation = 90
headerGrad.Parent = Header

-- red line under header
local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, 0, 0, 2)
HeaderLine.Position = UDim2.new(0, 0, 1, -2)
HeaderLine.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 28)
TitleLabel.Position = UDim2.new(0, 0, 0, 8)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "CORSA MODS+"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 17
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.Parent = Header

local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(1, 0, 0, 14)
SubLabel.Position = UDim2.new(0, 0, 0, 36)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = "V1.0  |  CORSA LEGENDS"
SubLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SubLabel.TextTransparency = 0.5
SubLabel.TextSize = 9
SubLabel.Font = Enum.Font.GothamBold
SubLabel.Parent = Header

-- scrolling content
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, 0, 1, -82)
ScrollFrame.Position = UDim2.new(0, 0, 0, 54)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 2
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(160, 20, 20)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = Main

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 0)
listLayout.Parent = ScrollFrame

-- section header
local function addSection(text)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 22)
    section.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
    section.BackgroundTransparency = 0.82
    section.BorderSizePixel = 0
    section.Parent = ScrollFrame

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 2, 1, 0)
    accent.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    accent.BorderSizePixel = 0
    accent.Parent = section

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 80, 80)
    label.TextSize = 9
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section

    return section
end

-- toggle row
local function addToggleRow(name, subtext, enabled)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    row.BackgroundTransparency = 0.97
    row.BorderSizePixel = 0
    row.Parent = ScrollFrame

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 1, -1)
    divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    divider.BackgroundTransparency = 0.94
    divider.BorderSizePixel = 0
    divider.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -60, 0, 20)
    nameLabel.Position = UDim2.new(0, 12, 0, subtext and 4 or 9)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    if subtext then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -60, 0, 14)
        sub.Position = UDim2.new(0, 12, 0, 22)
        sub.BackgroundTransparency = 1
        sub.Text = subtext
        sub.TextColor3 = Color3.fromRGB(255, 255, 255)
        sub.TextTransparency = 0.7
        sub.TextSize = 9
        sub.Font = Enum.Font.Gotham
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = row
    end

    local isOn = enabled or false

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 32, 0, 16)
    toggleBtn.Position = UDim2.new(1, -44, 0.5, -8)
    toggleBtn.Text = ""
    toggleBtn.BackgroundColor3 = isOn and Color3.fromRGB(180, 25, 25) or Color3.fromRGB(50, 50, 50)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = row

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(1, 0)
    tCorner.Parent = toggleBtn

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = isOn and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = toggleBtn

    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(1, 0)
    dCorner.Parent = dot

    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        toggleBtn.BackgroundColor3 = isOn
            and Color3.fromRGB(180, 25, 25)
            or Color3.fromRGB(50, 50, 50)
        dot.Position = isOn
            and UDim2.new(1, -14, 0.5, -6)
            or UDim2.new(0, 2, 0.5, -6)
        row.BackgroundTransparency = isOn and 0.94 or 0.97
    end)

    return row
end

-- arrow row (for sub menus / custom plugins)
local function addArrowRow(name, subtext, callback)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    row.BackgroundTransparency = 0.97
    row.BorderSizePixel = 0
    row.Text = ""
    row.Parent = ScrollFrame

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 1, -1)
    divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    divider.BackgroundTransparency = 0.94
    divider.BorderSizePixel = 0
    divider.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -40, 0, 20)
    nameLabel.Position = UDim2.new(0, 12, 0, subtext and 4 or 9)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    if subtext then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -40, 0, 14)
        sub.Position = UDim2.new(0, 12, 0, 22)
        sub.BackgroundTransparency = 1
        sub.Text = subtext
        sub.TextColor3 = Color3.fromRGB(255, 255, 255)
        sub.TextTransparency = 0.7
        sub.TextSize = 9
        sub.Font = Enum.Font.Gotham
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = row
    end

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -28, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = ">"
    arrow.TextColor3 = Color3.fromRGB(255, 255, 255)
    arrow.TextTransparency = 0.6
    arrow.TextSize = 14
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = row

    row.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    return row
end

-- build the menu items
addSection("VEHICLE")
addToggleRow("Air Suspension", "built-in", false)
addToggleRow("Custom Liveries", "built-in", false)
addToggleRow("Speedometer HUD", "built-in", false)

addSection("VISUAL")
addToggleRow("Neon Underglow", "built-in", false)

addSection("PLUGINS")
addArrowRow("Load Custom Plugin", "paste a github url", function()
    -- open custom plugin panel
    CustomPanel.Visible = not CustomPanel.Visible
end)

-- custom plugin panel
local CustomPanel = Instance.new("Frame")
CustomPanel.Size = UDim2.new(1, 0, 0, 80)
CustomPanel.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
CustomPanel.BackgroundTransparency = 0.1
CustomPanel.BorderSizePixel = 0
CustomPanel.Visible = false
CustomPanel.Parent = ScrollFrame

local cpLayout = Instance.new("UIListLayout")
cpLayout.Padding = UDim.new(0, 6)
cpLayout.Parent = CustomPanel

local cpPad = Instance.new("UIPadding")
cpPad.PaddingTop = UDim.new(0, 8)
cpPad.PaddingLeft = UDim.new(0, 10)
cpPad.PaddingRight = UDim.new(0, 10)
cpPad.PaddingBottom = UDim.new(0, 8)
cpPad.Parent = CustomPanel

local urlBox = Instance.new("TextBox")
urlBox.Size = UDim2.new(1, 0, 0, 28)
urlBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
urlBox.BorderSizePixel = 0
urlBox.Text = ""
urlBox.PlaceholderText = "raw github url..."
urlBox.TextColor3 = Color3.fromRGB(200, 200, 200)
urlBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
urlBox.TextSize = 11
urlBox.Font = Enum.Font.Code
urlBox.ClearTextOnFocus = false
urlBox.Parent = CustomPanel

local urlCorner = Instance.new("UICorner")
urlCorner.CornerRadius = UDim.new(0, 4)
urlCorner.Parent = urlBox

local urlPad = Instance.new("UIPadding")
urlPad.PaddingLeft = UDim.new(0, 8)
urlPad.Parent = urlBox

local loadBtn = Instance.new("TextButton")
loadBtn.Size = UDim2.new(1, 0, 0, 26)
loadBtn.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
loadBtn.BorderSizePixel = 0
loadBtn.Text = "LOAD PLUGIN"
loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loadBtn.TextSize = 11
loadBtn.Font = Enum.Font.GothamBold
loadBtn.Parent = CustomPanel

local loadCorner = Instance.new("UICorner")
loadCorner.CornerRadius = UDim.new(0, 4)
loadCorner.Parent = loadBtn

-- status label (outside panel, in scroll)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(200, 40, 40)
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = ScrollFrame

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
        local pName = result.name or "Unknown"
        statusLabel.Text = "loaded: " .. pName
        statusLabel.TextColor3 = Color3.fromRGB(200, 40, 40)
        addToggleRow(pName, "@" .. (result.author or "unknown"), true)
        urlBox.Text = ""
        CustomPanel.Visible = false
    else
        statusLabel.Text = "failed — check url or format"
        statusLabel.TextColor3 = Color3.fromRGB(220, 60, 60)
    end
end)

-- footer
local Footer = Instance.new("Frame")
Footer.Size = UDim2.new(1, 0, 0, 28)
Footer.Position = UDim2.new(0, 0, 1, -28)
Footer.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
Footer.BackgroundTransparency = 0.2
Footer.BorderSizePixel = 0
Footer.Parent = Main

local footerGrad = Instance.new("UIGradient")
footerGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 20, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 10, 10)),
})
footerGrad.Rotation = 90
footerGrad.Parent = Footer

local FooterLabel = Instance.new("TextLabel")
FooterLabel.Size = UDim2.new(0.5, 0, 1, 0)
FooterLabel.Position = UDim2.new(0, 10, 0, 0)
FooterLabel.BackgroundTransparency = 1
FooterLabel.Text = "RSHIFT TO TOGGLE"
FooterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FooterLabel.TextTransparency = 0.45
FooterLabel.TextSize = 9
FooterLabel.Font = Enum.Font.GothamBold
FooterLabel.TextXAlignment = Enum.TextXAlignment.Left
FooterLabel.Parent = Footer

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.new(0.5, -10, 1, 0)
VersionLabel.Position = UDim2.new(0.5, 0, 0, 0)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text = "CORSAMODS V1.0"
VersionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
VersionLabel.TextTransparency = 0.55
VersionLabel.TextSize = 9
VersionLabel.Font = Enum.Font.GothamBold
VersionLabel.TextXAlignment = Enum.TextXAlignment.Right
VersionLabel.Parent = Footer

-- toggle visibility
local menuOpen = false

local function setMenuVisible(visible)
    menuOpen = visible
    Main.Visible = visible
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setMenuVisible(not menuOpen)
    end
end)
