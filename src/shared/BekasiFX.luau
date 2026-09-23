--!strict
-- BekasiFX.luau
-- Visualisasi dramatis untuk kartu 'Banjir Bandang' dan evakuasi pemain ke pulau pengasingan Bekasi.
-- Terisolasi, non-blocking, dengan pembersihan Debris otomatis (nol memory leak).

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BekasiFX = {}

local function isMuted(): boolean
	local localPlayer = Players.LocalPlayer
	return localPlayer ~= nil and localPlayer:GetAttribute("AudioMuted") == true
end

-- 1. Efek Saat Terjadi Banjir Bandang & Dievakuasi ke Bekasi
function BekasiFX.playEvacuate(originPos: Vector3, bekasiPos: Vector3)
	-- A. Titik Asal: Geyser Air Banjir + Label Peringatan
	local splashAnchor = Instance.new("Part")
	splashAnchor.Name = "FloodSplashAnchor"
	splashAnchor.Size = Vector3.new(1, 0.2, 1)
	splashAnchor.Transparency = 1
	splashAnchor.Anchored = true
	splashAnchor.CanCollide = false
	splashAnchor.CFrame = CFrame.new(originPos)
	splashAnchor.Parent = Workspace

	local attOrigin = Instance.new("Attachment")
	attOrigin.Parent = splashAnchor

	-- Partikel Geyser Air
	local waterEmitter = Instance.new("ParticleEmitter")
	waterEmitter.Rate = 0
	waterEmitter.Lifetime = NumberRange.new(0.6, 1.2)
	waterEmitter.Speed = NumberRange.new(6.0, 11.0)
	waterEmitter.SpreadAngle = Vector2.new(40, 40)
	waterEmitter.EmissionDirection = Enum.NormalId.Top
	waterEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 1.2),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	waterEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	waterEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 200, 255)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 160, 240)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 160, 130)),
	})
	waterEmitter.LightEmission = 0.5
	waterEmitter.Parent = attOrigin
	waterEmitter:Emit(28)

	-- Billboard Peringatan Banjir
	local bbOrigin = Instance.new("BillboardGui")
	bbOrigin.Name = "FloodWarningGui"
	bbOrigin.Size = UDim2.fromScale(10.0, 2.5)
	bbOrigin.AlwaysOnTop = true
	bbOrigin.Adornee = splashAnchor
	bbOrigin.StudsOffset = Vector3.new(0, 3.2, 0)
	bbOrigin.Parent = splashAnchor

	local labelOrigin = Instance.new("TextLabel")
	labelOrigin.Size = UDim2.fromScale(1, 1)
	labelOrigin.BackgroundTransparency = 1
	labelOrigin.Text = "🌊 BANJIR BANDANG! EVAKUASI KE BEKASI! 🛸"
	labelOrigin.TextColor3 = Color3.fromRGB(80, 210, 255)
	labelOrigin.TextSize = 24
	labelOrigin.Font = Enum.Font.FredokaOne
	labelOrigin.TextScaled = true
	labelOrigin.Parent = bbOrigin

	local strokeOrigin = Instance.new("UIStroke")
	strokeOrigin.Color = Color3.fromRGB(15, 30, 60)
	strokeOrigin.Thickness = 3.5
	strokeOrigin.Parent = labelOrigin

	if not isMuted() then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/splat.wav"
		sound.Volume = 0.6
		sound.PlaybackSpeed = 0.95
		sound.Parent = splashAnchor
		sound:Play()
	end

	-- B. Titik Tujuan: Pulau Bekasi
	local bekasiAnchor = Instance.new("Part")
	bekasiAnchor.Name = "BekasiArrivalAnchor"
	bekasiAnchor.Size = Vector3.new(1, 0.2, 1)
	bekasiAnchor.Transparency = 1
	bekasiAnchor.Anchored = true
	bekasiAnchor.CanCollide = false
	bekasiAnchor.CFrame = CFrame.new(bekasiPos)
	bekasiAnchor.Parent = Workspace

	local bbBekasi = Instance.new("BillboardGui")
	bbBekasi.Name = "BekasiArrivalGui"
	bbBekasi.Size = UDim2.fromScale(9.5, 2.2)
	bbBekasi.AlwaysOnTop = true
	bbBekasi.Adornee = bekasiAnchor
	bbBekasi.StudsOffset = Vector3.new(0, 3.6, 0)
	bbBekasi.Parent = bekasiAnchor

	local labelBekasi = Instance.new("TextLabel")
	labelBekasi.Size = UDim2.fromScale(1, 1)
	labelBekasi.BackgroundTransparency = 1
	labelBekasi.Text = "🛸 TERDAMPAR DI BEKASI (LEWATI 1 GILIRAN) 🛸"
	labelBekasi.TextColor3 = Color3.fromRGB(255, 175, 75)
	labelBekasi.TextSize = 22
	labelBekasi.Font = Enum.Font.FredokaOne
	labelBekasi.TextScaled = true
	labelBekasi.Parent = bbBekasi

	local strokeBekasi = Instance.new("UIStroke")
	strokeBekasi.Color = Color3.fromRGB(40, 20, 10)
	strokeBekasi.Thickness = 3.0
	strokeBekasi.Parent = labelBekasi

	-- Animasi Float & Fade
	task.delay(1.8, function()
		if not splashAnchor:IsDescendantOf(Workspace) then return end
		local fade1 = TweenService:Create(labelOrigin, TweenInfo.new(0.4), {TextTransparency = 1})
		local fade2 = TweenService:Create(strokeOrigin, TweenInfo.new(0.4), {Transparency = 1})
		fade1:Play()
		fade2:Play()
	end)

	task.delay(2.2, function()
		if not bekasiAnchor:IsDescendantOf(Workspace) then return end
		local fade3 = TweenService:Create(labelBekasi, TweenInfo.new(0.4), {TextTransparency = 1})
		local fade4 = TweenService:Create(strokeBekasi, TweenInfo.new(0.4), {Transparency = 1})
		fade3:Play()
		fade4:Play()
	end)

	Debris:AddItem(splashAnchor, 2.8)
	Debris:AddItem(bekasiAnchor, 3.0)
end

-- 2. Efek Saat Selesai Lewati Giliran & Pulang ke Lintasan Papan
function BekasiFX.playReturn(targetPos: Vector3)
	local returnAnchor = Instance.new("Part")
	returnAnchor.Name = "BekasiReturnAnchor"
	returnAnchor.Size = Vector3.new(1, 0.2, 1)
	returnAnchor.Transparency = 1
	returnAnchor.Anchored = true
	returnAnchor.CanCollide = false
	returnAnchor.CFrame = CFrame.new(targetPos)
	returnAnchor.Parent = Workspace

	local att = Instance.new("Attachment")
	att.Parent = returnAnchor

	-- Sparkle Kembalinya Pion
	local returnEmitter = Instance.new("ParticleEmitter")
	returnEmitter.Rate = 0
	returnEmitter.Lifetime = NumberRange.new(0.6, 1.0)
	returnEmitter.Speed = NumberRange.new(3.0, 6.0)
	returnEmitter.SpreadAngle = Vector2.new(180, 180)
	returnEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	returnEmitter.Color = ColorSequence.new(Color3.fromRGB(120, 255, 180))
	returnEmitter.LightEmission = 0.8
	returnEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	returnEmitter.Parent = att
	returnEmitter:Emit(20)

	local bb = Instance.new("BillboardGui")
	bb.Name = "ReturnNotice"
	bb.Size = UDim2.fromScale(8.0, 2.0)
	bb.AlwaysOnTop = true
	bb.Adornee = returnAnchor
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.Parent = returnAnchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "🚌 PULANG DARI BEKASI! 🚌"
	label.TextColor3 = Color3.fromRGB(130, 255, 170)
	label.TextSize = 22
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = bb

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(15, 45, 25)
	stroke.Thickness = 3.0
	stroke.Parent = label

	if not isMuted() then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.Volume = 0.4
		sound.PlaybackSpeed = 1.4
		sound.Parent = returnAnchor
		sound:Play()
	end

	task.delay(1.5, function()
		if not returnAnchor:IsDescendantOf(Workspace) then return end
		local fade1 = TweenService:Create(label, TweenInfo.new(0.35), {TextTransparency = 1})
		local fade2 = TweenService:Create(stroke, TweenInfo.new(0.35), {Transparency = 1})
		fade1:Play()
		fade2:Play()
	end)

	Debris:AddItem(returnAnchor, 2.2)
end

return BekasiFX
