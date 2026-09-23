--!strict
-- UIJuiceController.luau
-- Memberikan animasi mikro, hover bounce, press squash, dan breathing pulse glow
-- pada seluruh tombol interaktif di WNIGameUI agar antarmuka terasa sangat responsif, hidup, dan memuaskan.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local localPlayer = Players.LocalPlayer
if not localPlayer then return end

local playerGui = localPlayer:WaitForChild("PlayerGui")
local gameUI = playerGui:WaitForChild("WNIGameUI", 10)
if not gameUI then return end

local root = gameUI:WaitForChild("Root", 10) :: Frame?
if not root then return end

local function playTactileClick()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/switch.wav"
	sound.Volume = 0.25
	sound.PlaybackSpeed = 1.25 + (math.random() * 0.1)
	sound.Parent = gameUI
	sound:Play()
	Debris:AddItem(sound, 0.6)
end

local function attachButtonJuice(btn: TextButton)
	local scale = btn:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Scale = 1.0
		scale.Parent = btn
	end

	local hoverTween = TweenService:Create(
		scale,
		TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Scale = 1.06}
	)
	local normalTween = TweenService:Create(
		scale,
		TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Scale = 1.0}
	)
	local pressTween = TweenService:Create(
		scale,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Scale = 0.94}
	)

	btn.MouseEnter:Connect(function()
		if btn.Active and btn.Visible then
			hoverTween:Play()
		end
	end)

	btn.MouseLeave:Connect(function()
		normalTween:Play()
	end)

	btn.MouseButton1Down:Connect(function()
		if btn.Active and btn.Visible then
			pressTween:Play()
			playTactileClick()
		end
	end)

	btn.MouseButton1Up:Connect(function()
		hoverTween:Play()
	end)
end

-- Scan seluruh tombol di UI
for _, descendant in ipairs(root:GetDescendants()) do
	if descendant:IsA("TextButton") then
		attachButtonJuice(descendant)
	end
end

root.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("TextButton") then
		attachButtonJuice(descendant)
	end
end)

-- Breathing Pulse untuk RollButton (Menarik Perhatian Pemain Saat Giliran Tiba)
local actionPanel = root:FindFirstChild("ActionPanel")
local rollBtn = actionPanel and actionPanel:FindFirstChild("RollButton") :: TextButton?

if rollBtn then
	local scale = rollBtn:FindFirstChildOfClass("UIScale")
	if scale then
		local pulseTween = TweenService:Create(
			scale,
			TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Scale = 1.04}
		)

		rollBtn:GetPropertyChangedSignal("Visible"):Connect(function()
			if rollBtn.Visible and rollBtn.Active then
				pulseTween:Play()
			else
				pulseTween:Cancel()
				scale.Scale = 1.0
			end
		end)

		if rollBtn.Visible and rollBtn.Active then
			pulseTween:Play()
		end
	end
end
