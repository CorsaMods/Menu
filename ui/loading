local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- cleanup
if PlayerGui:FindFirstChild("ModMenuLoading") then
    PlayerGui.ModMenuLoading:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModMenuLoading"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 260, 0, 60)
Frame.Position = UDim2.new(0.5, -130, 1, -80)
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, 0, 1, 0)
Label.BackgroundTransparency = 1
Label.TextColor3 = Color3.fromRGB(180, 180, 180)
Label.TextSize = 12
Label.Font = Enum.Font.Code
Label.Text = "loading..."
Label.Parent = Frame

local module = {}

function module.show(msg)
    Label.Text = "⚡ " .. msg
    ScreenGui.Enabled = true
    task.delay(3, function()
        ScreenGui.Enabled = false
    end)
end

function module.error(msg)
    Label.Text = "✗ " .. msg
    Label.TextColor3 = Color3.fromRGB(180, 50, 50)
end

return module
