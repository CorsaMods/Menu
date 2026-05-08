local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("ModMenuLoading") then
    PlayerGui.ModMenuLoading:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModMenuLoading"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- blurred dark background
local Blur = Instance.new("Frame")
Blur.Size = UDim2.new(1, 0, 1, 0)
Blur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Blur.BackgroundTransparency = 0
Blur.BorderSizePixel = 0
Blur.Parent = ScreenGui

-- actual blur effect
local BlurEffect = Instance.new("BlurEffect")
BlurEffect.Size = 24
BlurEffect.Parent = game:GetService("Lighting")

-- logo image
local Logo = Instance.new("ImageLabel")
Logo.Size = UDim2.new(0, 300, 0, 300)
Logo.Position = UDim2.new(0.5, -150, 0.5, -150)
Logo.BackgroundTransparency = 1
Logo.Image = "rbxassetid://122285902567431"
Logo.ImageTransparency = 0
Logo.Parent = ScreenGui

-- loading text under logo
local LoadingLabel = Instance.new("TextLabel")
LoadingLabel.Size = UDim2.new(0, 300, 0, 24)
LoadingLabel.Position = UDim2.new(0.5, -150, 0.5, 165)
LoadingLabel.BackgroundTransparency = 1
LoadingLabel.Text = "loading..."
LoadingLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
LoadingLabel.TextSize = 12
LoadingLabel.Font = Enum.Font.Code
LoadingLabel.Parent = ScreenGui

local module = {}

function module.show(msg)
    LoadingLabel.Text = msg
    ScreenGui.Enabled = true
end

function module.dismiss()
    -- fade out logo and text
    local fadeLogo = TweenService:Create(Logo, TweenInfo.new(0.6), {ImageTransparency = 1})
    local fadeText = TweenService:Create(LoadingLabel, TweenInfo.new(0.6), {TextTransparency = 1})
    local fadeBg = TweenService:Create(Blur, TweenInfo.new(0.8), {BackgroundTransparency = 1})

    fadeLogo:Play()
    fadeText:Play()

    fadeLogo.Completed:Connect(function()
        fadeBg:Play()
        fadeBg.Completed:Connect(function()
            -- remove blur effect from lighting
            BlurEffect:Destroy()
            ScreenGui:Destroy()
        end)
    end)
end

function module.error(msg)
    LoadingLabel.Text = "failed: " .. msg
    LoadingLabel.TextColor3 = Color3.fromRGB(180, 50, 50)
end

return module
