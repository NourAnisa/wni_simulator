--!strict
-- PawnAnimator (client): visual-only hop for board pawns + tile burst FX.
-- Reads replicated positions every RenderStep and adds a sinusoidal Y offset,
-- so it never fights the server tween (which owns the real Position).
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local HOP_HEIGHT = 1.4
local STEP_TIME = 0.55
local MOVE_EPS = 0.03

type Track = {last: Vector3, startedAt: number, moving: boolean, soundOnly: boolean}

local PawnAnimator = {}
local tracked: {[BasePart]: Track} = {}
local connection: RBXScriptConnection? = nil

local function trackPart(part: BasePart, soundOnly: boolean?)
	if tracked[part] then return end
	tracked[part] = {last = part.Position, startedAt = 0, moving = false, soundOnly = soundOnly == true}
end

local function trackInstance(child: Instance)
	if child:IsA("BasePart") then
		trackPart(child, false)
	elseif child:IsA("Model") then
		local root = child.PrimaryPart or child:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			trackPart(root, true)
		else
			child:GetPropertyChangedSignal("PrimaryPart"):Once(function()
				if child.PrimaryPart then trackPart(child.PrimaryPart, true) end
			end)
		end
	end
end

local function playHopSound(part: BasePart)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/switch.wav"
	sound.Volume = 0.35
	sound.PlaybackSpeed = 1.15 + (math.random() * 0.18)
	sound.Parent = part
	sound:Play()
	Debris:AddItem(sound, 1)
end

local function playLandingPuff(part: BasePart)
	if not part:IsDescendantOf(workspace) then return end
	local att = Instance.new("Attachment")
	att.Position = Vector3.new(0, -part.Size.Y * 0.45, 0)
	att.Parent = part

	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.3, 0.5)
	emitter.Speed = NumberRange.new(0.8, 1.8)
	emitter.SpreadAngle = Vector2.new(90, 90)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.7, 0.65),
		NumberSequenceKeypoint.new(1, 0.85),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.6, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Color = ColorSequence.new(Color3.fromRGB(225, 218, 198))
	emitter.LightEmission = 0.2
	emitter.Parent = att
	emitter:Emit(6)

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/switch.wav"
	sound.Volume = 0.25
	sound.PlaybackSpeed = 0.85 + (math.random() * 0.1)
	sound.Parent = part
	sound:Play()

	Debris:AddItem(att, 0.6)
end

function PawnAnimator.watch(pawnsContainer: Instance)
	for _, child in ipairs(pawnsContainer:GetChildren()) do
		trackInstance(child)
	end
	pawnsContainer.ChildAdded:Connect(function(child)
		trackInstance(child)
	end)
	if connection then return end
	connection = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for part, state in pairs(tracked) do
			if not part:IsDescendantOf(workspace) then
				tracked[part] = nil
				continue
			end
			local pos = part.Position
			if (pos - state.last).Magnitude > MOVE_EPS then
				if not state.moving then
					state.moving = true
					state.startedAt = now
					playHopSound(part)
				end
				if not state.soundOnly then
					local progress = math.clamp((now - state.startedAt) / STEP_TIME, 0, 1)
					local offset = HOP_HEIGHT * math.sin(progress * math.pi)
					if offset > 0.01 then
						part.CFrame = CFrame.new(pos + Vector3.new(0, offset, 0)) * part.CFrame.Rotation
					end
				end
			else
				if state.moving then
					state.moving = false
					playLandingPuff(part)
				end
			end
			state.last = pos
		end
	end)
end

local function burst(tile: BasePart, color: Color3, count: number)
	local anchor = tile:FindFirstChild("PawnAnchor")
	local att: Attachment
	if anchor and anchor:IsA("Attachment") then
		att = anchor
	else
		att = Instance.new("Attachment")
		att.Parent = tile
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.Speed = NumberRange.new(4, 7)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Size = NumberSequence.new(0.3)
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.8
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = att
	emitter:Emit(count)
	Debris:AddItem(emitter, 2)
end

function PawnAnimator.celebratePurchase(tile: BasePart)
	burst(tile, Color3.fromRGB(255, 208, 84), 26)
end

function PawnAnimator.celebrateBuild(tile: BasePart)
	burst(tile, Color3.fromRGB(120, 220, 200), 30)
end

return PawnAnimator
