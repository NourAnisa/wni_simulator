--!strict
-- BoardHighlightFX (client): active-tile glow + jail strobe. Visual only.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local BoardHighlightFX = {}
local activeHighlight: Highlight? = nil
local activePulse: Tween? = nil
local strobeActive = false

local function ensureHighlight(): Highlight
	if activeHighlight and activeHighlight:IsDescendantOf(workspace) then
		return activeHighlight
	end
	local h = Instance.new("Highlight")
	h.Name = "ActiveTileHighlight"
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = workspace
	activeHighlight = h
	return h
end

function BoardHighlightFX.highlightTile(tilePart: BasePart, color: Color3)
	local h = ensureHighlight()
	if activePulse then activePulse:Cancel() activePulse = nil end
	h.Adornee = tilePart
	h.FillColor = color
	h.OutlineColor = color
	h.FillTransparency = 0.8
	h.OutlineTransparency = 0.15
	h.Enabled = true
	local t = TweenService:Create(h, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {FillTransparency = 0.45})
	t:Play()
	activePulse = t
end

function BoardHighlightFX.clearHighlight()
	if activePulse then activePulse:Cancel() activePulse = nil end
	if activeHighlight then
		activeHighlight.Adornee = nil
		activeHighlight.Enabled = false
	end
end

function BoardHighlightFX.triggerJailStrobe(pawnOrTile: Instance)
	local part = if pawnOrTile:IsA("BasePart") then pawnOrTile else pawnOrTile:FindFirstChildWhichIsA("BasePart", true)
	if not part or strobeActive then return end
	strobeActive = true
	local h = Instance.new("Highlight")
	h.Name = "JailStrobe"
	h.Adornee = part
	h.FillTransparency = 0.35
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = workspace
	local light = Instance.new("PointLight")
	light.Brightness = 3
	light.Range = 12
	light.Shadows = false
	light.Color = Color3.fromRGB(255, 60, 60)
	light.Parent = part
	Debris:AddItem(h, 2)
	Debris:AddItem(light, 2)

	-- Putar audio sirine LAPAS jika tersedia
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer and localPlayer:FindFirstChild("PlayerGui")
	local gameUI = playerGui and playerGui:FindFirstChild("WNIGameUI")
	local uiSounds = gameUI and gameUI:FindFirstChild("UISounds")
	local sirenTemplate = uiSounds and (uiSounds:FindFirstChild("JailSiren") or uiSounds:FindFirstChild("SirenLapas"))
	if sirenTemplate and sirenTemplate:IsA("Sound") and sirenTemplate.SoundId ~= "" then
		local s = sirenTemplate:Clone()
		s.Parent = part
		s:Play()
		Debris:AddItem(s, 3)
	end
	task.spawn(function()
		local red = Color3.fromRGB(255, 60, 60)
		local blue = Color3.fromRGB(70, 130, 255)
		local flip = false
		for _ = 1, 13 do
			if not h:IsDescendantOf(workspace) then break end
			flip = not flip
			local c = if flip then blue else red
			h.FillColor = c
			h.OutlineColor = c
			light.Color = c
			task.wait(0.15)
		end
		strobeActive = false
	end)
end

return BoardHighlightFX
