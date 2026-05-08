local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- clean up any leftover blur from a previous run
local existing = PlayerGui:FindFirstChild("ModMenuLoading")
if existing then existing:Destroy() end
for _, v in ipairs(Lighting:GetChildren()) do
	if v:IsA("BlurEffect") and v.Name == "ModMenuBlur" then
		v:Destroy()
	end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModMenuLoading"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local Blur = Instance.new("Frame")
Blur.Size = UDim2.new(1, 0, 1, 0)
Blur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Blur.BackgroundTransparency = 0
Blur.BorderSizePixel = 0
Blur.Parent = ScreenGui

local BlurEffect = Instance.new("BlurEffect")
BlurEffect.Name = "ModMenuBlur"
BlurEffect.Size = 24
BlurEffect.Parent = Lighting

local Logo = Instance.new("ImageLabel")
Logo.Size = UDim2.new(0, 300, 0, 300)
Logo.Position = UDim2.new(0.5, -150, 0.5, -150)
Logo.BackgroundTransparency = 1
Logo.Image = "rbxassetid://122285902567431"
Logo.ImageTransparency = 0
Logo.Parent = ScreenGui

local LoadingLabel = Instance.new("TextLabel")
LoadingLabel.Size = UDim2.new(0, 300, 0, 24)
LoadingLabel.Position = UDim2.new(0.5, -150, 0.5, 165)
LoadingLabel.BackgroundTransparency = 1
LoadingLabel.Text = "loading..."
LoadingLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
LoadingLabel.TextSize = 12
LoadingLabel.Font = Enum.Font.Code
LoadingLabel.Parent = ScreenGui

local dismissed = false

local module = {}

function module.show(msg)
	LoadingLabel.Text = msg
	LoadingLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	ScreenGui.Enabled = true
end

function module.dismiss()
	if dismissed then return end
	dismissed = true

	local fadeLogo = TweenService:Create(Logo, TweenInfo.new(0.6), { ImageTransparency = 1 })
	local fadeText = TweenService:Create(LoadingLabel, TweenInfo.new(0.6), { TextTransparency = 1 })
	local fadeBg = TweenService:Create(Blur, TweenInfo.new(0.8), { BackgroundTransparency = 1 })

	fadeLogo:Play()
	fadeText:Play()

	fadeLogo.Completed:Connect(function()
		fadeBg:Play()
		fadeBg.Completed:Connect(function()
			BlurEffect:Destroy()
			ScreenGui:Destroy()
		end)
	end)

	-- safety fallback in case tweens fail or ScreenGui gets destroyed early
	task.delay(2.5, function()
		if BlurEffect and BlurEffect.Parent then
			BlurEffect:Destroy()
		end
		if ScreenGui and ScreenGui.Parent then
			ScreenGui:Destroy()
		end
	end)
end

function module.error(msg)
	LoadingLabel.Text = "failed: " .. msg
	LoadingLabel.TextColor3 = Color3.fromRGB(180, 50, 50)
end

return module
