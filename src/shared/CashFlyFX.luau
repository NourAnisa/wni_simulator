--!strict
-- CashFlyFX.luau
-- Visualisasi 3D uang tunai (lembaran rupiah hijau & koin emas) yang melesat terbang
-- melintasi udara dalam lintasan busur parabola dari pembayar ke penerima sewa/denda/negara.
-- Terisolasi, non-blocking, performa tinggi, dan bebas memory leak via DebrisService.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CashFlyFX = {}

local function isMuted(): boolean
	local player = Players.LocalPlayer
	return player ~= nil and player:GetAttribute("AudioMuted") == true
end

-- Menghitung titik pada kurva kuadratik Bézier
local function bezierPoint(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
	local u = 1 - t
	local tt = t * t
	local uu = u * u
	return (uu * p0) + (2 * u * t * p1) + (tt * p2)
end

function CashFlyFX.flyCash(origin: Vector3, destination: Vector3, isToState: boolean?)
	local distance = (destination - origin).Magnitude
	local arcHeight = math.clamp(distance * 0.28, 4.0, 14.0)
	local midPoint = ((origin + destination) * 0.5) + Vector3.new(0, arcHeight, 0)

	local billCount = if isToState then 5 else 7
	local flightDuration = math.clamp(0.55 + (distance * 0.005), 0.55, 0.95)

	for i = 1, billCount do
		task.delay((i - 1) * 0.055, function()
			-- Offset acak kecil agar lembaran uang tidak bertumpuk kaku
			local jitterOrigin = origin + Vector3.new(
				(math.random() - 0.5) * 1.2,
				0.8 + (math.random() * 0.5),
				(math.random() - 0.5) * 1.2
			)
			local jitterMid = midPoint + Vector3.new(
				(math.random() - 0.5) * 2.0,
				(math.random() - 0.5) * 1.0,
				(math.random() - 0.5) * 2.0
			)
			local jitterDest = destination + Vector3.new(
				(math.random() - 0.5) * 1.0,
				0.6,
				(math.random() - 0.5) * 1.0
			)

			-- 1. Part Uang Kertas 3D
			local bill = Instance.new("Part")
			bill.Name = "FlyingCash"
			bill.Size = Vector3.new(1.1, 0.03, 0.6)
			bill.Material = Enum.Material.SmoothPlastic
			bill.Color = if isToState then Color3.fromRGB(240, 195, 45) else Color3.fromRGB(52, 185, 112)
			bill.CanCollide = false
			bill.CastShadow = false
			bill.Anchored = true
			bill.CFrame = CFrame.new(jitterOrigin)
			bill.Parent = Workspace

			-- SurfaceGui untuk lambang Rupiah / Nilai
			local sg = Instance.new("SurfaceGui")
			sg.Name = "BillArt"
			sg.Face = Enum.NormalId.Top
			sg.CanvasSize = Vector2.new(110, 60)
			sg.LightInfluence = 0.2
			sg.Parent = bill

			local frame = Instance.new("Frame")
			frame.Size = UDim2.fromScale(1, 1)
			frame.BackgroundColor3 = bill.Color
			frame.BorderSizePixel = 0
			frame.Parent = sg

			local stroke = Instance.new("UIStroke")
			stroke.Color = if isToState then Color3.fromRGB(255, 230, 120) else Color3.fromRGB(200, 255, 210)
			stroke.Thickness = 2
			stroke.Parent = frame

			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Text = if isToState then "👑" else "Rp"
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextSize = 22
			label.Font = Enum.Font.FredokaOne
			label.Parent = frame

			-- Jejak kilau (Trail)
			local att0 = Instance.new("Attachment")
			att0.Position = Vector3.new(-0.45, 0, 0)
			att0.Parent = bill

			local att1 = Instance.new("Attachment")
			att1.Position = Vector3.new(0.45, 0, 0)
			att1.Parent = bill

			local trail = Instance.new("Trail")
			trail.Attachment0 = att0
			trail.Attachment1 = att1
			trail.Lifetime = 0.22
			trail.Color = ColorSequence.new(
				if isToState then Color3.fromRGB(255, 225, 100) else Color3.fromRGB(120, 245, 160)
			)
			trail.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(1, 1),
			})
			trail.LightEmission = 0.8
			trail.Parent = bill

			-- Animasi lintasan kurva Bézier
			local startTime = os.clock()
			local spinRate = Vector3.new(
				(math.random() - 0.5) * 8,
				(math.random() - 0.5) * 12,
				(math.random() - 0.5) * 8
			)

			local connection: RBXScriptConnection? = nil
			connection = game:GetService("RunService").RenderStepped:Connect(function()
				local elapsed = os.clock() - startTime
				local t = math.clamp(elapsed / flightDuration, 0, 1)

				local currentPos = bezierPoint(jitterOrigin, jitterMid, jitterDest, t)
				local rotAngles = spinRate * elapsed
				bill.CFrame = CFrame.new(currentPos) * CFrame.Angles(rotAngles.X, rotAngles.Y, rotAngles.Z)

				if t >= 1 then
					if connection then
						connection:Disconnect()
						connection = nil
					end

					-- Efek pendaratan di penerima: koin sparkle & clink
					if i == 1 or i == billCount then
						if not isMuted() then
							local sound = Instance.new("Sound")
							sound.SoundId = "rbxasset://sounds/switch.wav"
							sound.Volume = 0.3
							sound.PlaybackSpeed = 1.7 + (math.random() * 0.2)
							sound.Parent = bill
							sound:Play()
						end

						local burstAtt = Instance.new("Attachment")
						burstAtt.Position = Vector3.new(0, 0, 0)
						burstAtt.Parent = bill

						local burstEmitter = Instance.new("ParticleEmitter")
						burstEmitter.Rate = 0
						burstEmitter.Lifetime = NumberRange.new(0.3, 0.6)
						burstEmitter.Speed = NumberRange.new(2.0, 4.0)
						burstEmitter.SpreadAngle = Vector2.new(180, 180)
						burstEmitter.Size = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0.25),
							NumberSequenceKeypoint.new(1, 0),
						})
						burstEmitter.Color = ColorSequence.new(
							if isToState then Color3.fromRGB(255, 215, 60) else Color3.fromRGB(80, 240, 140)
						)
						burstEmitter.LightEmission = 0.9
						burstEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
						burstEmitter.Parent = burstAtt
						burstEmitter:Emit(8)
					end

					bill.Transparency = 1
					if sg then sg.Enabled = false end
					Debris:AddItem(bill, 0.5)
				end
			end)

			Debris:AddItem(bill, flightDuration + 1.0)
		end)
	end
end

return CashFlyFX
