--!strict
-- SpecialTileFX (client): 3D visual effects for special tiles (START, Tax, Court, Fate/Disaster).
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local SpecialTileFX = {}

local function tempAnchor(position: Vector3, life: number): BasePart
	local part = Instance.new("Part")
	part.Name = "SpecialTileFX_Anchor"
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Position = position
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = Workspace
	Debris:AddItem(part, life)
	return part
end

function SpecialTileFX.triggerStartSalary(tile: BasePart)
	local anchor = tempAnchor(tile.Position + Vector3.new(0, 1.2, 0), 3)

	-- Pancaran koin emas (Golden Sparkle Burst)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SalarySparkles"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 40)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.5, 1.2),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(1.2, 2.0)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(8, 16)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Acceleration = Vector3.new(0, -15, 0)
	emitter.Parent = anchor
	emitter:Emit(40)
end

function SpecialTileFX.triggerTaxFine(tile: BasePart)
	local anchor = tempAnchor(tile.Position + Vector3.new(0, 1.2, 0), 3)

	-- Partikel denda merah (Red Tax Dust)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "TaxDust"
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(220, 60, 60))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 2.2),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(1.0, 1.5)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(4, 9)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.Parent = anchor
	emitter:Emit(25)
end

function SpecialTileFX.triggerCourtTrial(tile: BasePart)
	local anchor = tempAnchor(tile.Position + Vector3.new(0, 0.5, 0), 3)

	-- Ring keadilan bercahaya (Justice Shockwave Ring)
	local ring = Instance.new("Part")
	ring.Name = "CourtRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.1, 1.0, 1.0)
	ring.CFrame = (tile.CFrame * CFrame.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = Color3.fromRGB(240, 200, 60)
	ring.Material = Enum.Material.Neon
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Parent = anchor

	local expandTween = TweenService:Create(ring, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.05, 7.5, 7.5),
		Transparency = 1,
	})
	expandTween:Play()
end

function SpecialTileFX.triggerCardVortex(tile: BasePart, isDisaster: boolean)
	local anchor = tempAnchor(tile.Position + Vector3.new(0, 1.2, 0), 3)

	local color = if isDisaster
		then Color3.fromRGB(230, 80, 50)
		else Color3.fromRGB(80, 160, 255)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "CardSparkles"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1.0),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(1.0, 1.8)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(6, 12)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.Parent = anchor
	emitter:Emit(30)
end

return SpecialTileFX
