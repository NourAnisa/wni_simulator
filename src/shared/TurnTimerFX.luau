--!strict
-- TurnTimerFX (client): urgency vignette + per-second tick + timeout buzzer. Visual+audio only.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local TurnTimerFX = {}
local vignette: ImageLabel? = nil
local vignetteTween: Tween? = nil
local tickThread: thread? = nil

local URGENCY_IMAGE = "rbxassetid://15544890544"
local EDGE_COLOR = Color3.fromRGB(255, 96, 40)

local function isMuted(): boolean
	local player = Players.LocalPlayer
	local playerGui = player:FindFirstChild("PlayerGui")
	local gui = playerGui and playerGui:FindFirstChild("WNIGameUI")
	local root = gui and gui:FindFirstChild("Root")
	return root ~= nil and root:GetAttribute("AudioMuted") == true
end

local function sourceSound(name: string): Sound?
	local player = Players.LocalPlayer
	local playerGui = player:FindFirstChild("PlayerGui")
	local gui = playerGui and playerGui:FindFirstChild("WNIGameUI")
	local sounds = gui and gui:FindFirstChild("UISounds")
	local found = sounds and sounds:FindFirstChild(name)
	if found and found:IsA("Sound") then return found end
	return nil
end

local function ensureVignette(): ImageLabel
	if vignette and vignette:IsDescendantOf(workspace) and vignette:IsDescendantOf(game) then
		return vignette
	end
	local player = Players.LocalPlayer
	local playerGui = player:FindFirstChild("PlayerGui")
	local gui = playerGui and playerGui:FindFirstChild("WNIGameUI")
	if not gui then error("TurnTimerFX: WNIGameUI missing") end
	local root = gui:FindFirstChild("Root")
	local img = Instance.new("ImageLabel")
	img.Name = "TurnTimerVignette"
	img.Image = URGENCY_IMAGE
	img.ImageColor3 = EDGE_COLOR
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1.18, 1.5)
	img.Position = UDim2.fromScale(-0.09, -0.25)
	img.ImageTransparency = 1
	img.ZIndex = 5
	img.Parent = if root then root else gui
	vignette = img
	return img
end

function TurnTimerFX.startCountdown(remainingSeconds: number)
	local img = ensureVignette()
	if vignetteTween then vignetteTween:Cancel() vignetteTween = nil end
	vignette.ImageTransparency = 0.35
	vignetteTween = TweenService:Create(img, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.08})
	vignetteTween:Play()
	if tickThread then task.cancel(tickThread) tickThread = nil end
	tickThread = task.spawn(function()
		local tickIndex = 0
		while true do
			if not isMuted() then
				local source = sourceSound("Click")
				if source then
					local clone = source:Clone()
					clone.Name = "TurnTimerTick"
					clone.PlaybackSpeed = 1 + (tickIndex % 2) * 0.18
					clone.Volume = 0.7
					clone.Parent = workspace
					clone:Play()
					Debris:AddItem(clone, 1.5)
				end
			end
			tickIndex += 1
			task.wait(1)
		end
	end)
end

function TurnTimerFX.stopCountdown()
	if tickThread then task.cancel(tickThread) tickThread = nil end
	if vignetteTween then vignetteTween:Cancel() vignetteTween = nil end
	if vignette and vignette:IsDescendantOf(game) then
		local fade = TweenService:Create(vignette, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 1})
		fade:Play()
		fade.Completed:Once(function()
			if vignette and vignette:IsDescendantOf(game) and not vignetteTween then vignette.Visible = false end
		end)
		vignette.Visible = true
	end
end

function TurnTimerFX.playBuzzer()
	if tickThread then task.cancel(tickThread) tickThread = nil end
	if vignetteTween then vignetteTween:Cancel() vignetteTween = nil end
	if vignette and vignette:IsDescendantOf(game) then
		vignette.ImageTransparency = 0.05
		local flare = TweenService:Create(vignette, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 1})
		flare:Play()
	end
	if isMuted() then return end
	local source = sourceSound("RollDice") or sourceSound("Click")
	if source then
		local clone = source:Clone()
		clone.Name = "TurnTimerBuzzer"
		clone.PlaybackSpeed = 0.45
		clone.Volume = 1
		clone.Parent = workspace
		clone:Play()
		Debris:AddItem(clone, 2.5)
	end
end

return TurnTimerFX
