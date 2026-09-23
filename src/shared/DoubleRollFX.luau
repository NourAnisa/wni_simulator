--!strict
-- DoubleRollFX.luau
-- Visualisasi selebrasi dadu kembar (doubles) dan camera micro-punch untuk game juice.
-- Terisolasi, non-blocking, dengan pembersihan otomatis via DebrisService.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DoubleRollFX = {}

local function isMuted(): boolean
	local localPlayer = Players.LocalPlayer
	if localPlayer and localPlayer:GetAttribute("AudioMuted") == true then
		return true
	end
	return false
end

function DoubleRollFX.playDouble(position: Vector3, dieValue: number, isLocalPlayer: boolean)
	-- 1. Anchor part tak terlihat untuk menaruh BillboardGui & Attachment
	local anchor = Instance.new("Part")
	anchor.Name = "DoubleRollAnchor"
	anchor.Size = Vector3.new(0.5, 0.5, 0.5)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.Anchored = true
	anchor.CFrame = CFrame.new(position + Vector3.new(0, 3.8, 0))
	anchor.Parent = Workspace

	-- 2. BillboardGui
	local bb = Instance.new("BillboardGui")
	bb.Name = "DoubleRollBanner"
	bb.Size = UDim2.fromScale(9.0, 2.2)
	bb.StudsOffset = Vector3.new(0, 0, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = anchor
	bb.Parent = anchor

	local scale = Instance.new("UIScale")
	scale.Scale = 0.01
	scale.Parent = bb

	local label = Instance.new("TextLabel")
	label.Name = "BannerText"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = string.format("🎲 DADU KEMBAR %d-%d! 🎲", dieValue, dieValue)
	label.TextColor3 = Color3.fromRGB(255, 220, 60)
	label.TextSize = 28
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = bb

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(30, 20, 10)
	stroke.Thickness = 3.5
	stroke.Parent = label

	-- 3. Star Burst Partikel
	local att = Instance.new("Attachment")
	att.Parent = anchor

	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.7, 1.2)
	emitter.Speed = NumberRange.new(5.0, 9.0)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(0.6, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 175, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 30)),
	})
	emitter.LightEmission = 1.0
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Parent = att
	emitter:Emit(20)

	-- 4. Audio Selebrasi
	if not isMuted() then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.Volume = 0.55
		sound.PlaybackSpeed = 1.35
		sound.Parent = anchor
		sound:Play()
	end

	-- 5. Camera Micro-Punch (Juice) jika pemain lokal yang melempar
	if isLocalPlayer then
		local camera = Workspace.CurrentCamera
		if camera then
			local baseFov = camera.FieldOfView
			local punchFov = math.max(baseFov - 3.5, 45)
			local punchTween = TweenService:Create(
				camera,
				TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{FieldOfView = punchFov}
			)
			punchTween:Play()
			punchTween.Completed:Once(function()
				local recoverTween = TweenService:Create(
					camera,
					TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{FieldOfView = baseFov}
				)
				recoverTween:Play()
			end)
		end
	end

	-- 6. Koreografi Banner: Pop In -> Float -> Fade Out
	local popTween = TweenService:Create(
		scale,
		TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Scale = 1.0}
	)
	popTween:Play()

	local floatTween = TweenService:Create(
		bb,
		TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{StudsOffset = Vector3.new(0, 1.6, 0)}
	)
	floatTween:Play()

	task.delay(1.5, function()
		if not bb:IsDescendantOf(Workspace) then return end
		local fadeText = TweenService:Create(
			label,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{TextTransparency = 1}
		)
		local fadeStroke = TweenService:Create(
			stroke,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Transparency = 1}
		)
		fadeText:Play()
		fadeStroke:Play()
	end)

	-- Pembersihan total otomatis
	Debris:AddItem(anchor, 2.4)
end

return DoubleRollFX
