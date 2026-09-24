--!strict
-- Dice3DFX (client): two 3D dice tumble onto the board center. Visual+audio only.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProgressionConfig = require(ReplicatedStorage:WaitForChild("WNI"):WaitForChild("ProgressionConfig"))

local Dice3DFX = {}
local DICE_SIZE = 1.2
local FACE_ORIENTATIONS: {[number]: Vector3} = {
	[1] = Vector3.new(0, 0, 0),
	[2] = Vector3.new(90, 0, 0),
	[3] = Vector3.new(0, 0, -90),
	[4] = Vector3.new(0, 0, 90),
	[5] = Vector3.new(-90, 0, 0),
	[6] = Vector3.new(180, 0, 0),
}

local function isMuted(): boolean
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChild("PlayerGui")
	local gui = playerGui and playerGui:FindFirstChild("WNIGameUI")
	local root = gui and gui:FindFirstChild("Root")
	return root ~= nil and root:GetAttribute("AudioMuted") == true
end

local function playBounceSound()
	if isMuted() then return end
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChild("PlayerGui")
	local gui = playerGui and playerGui:FindFirstChild("WNIGameUI")
	local sounds = gui and gui:FindFirstChild("UISounds")
	if not sounds then
		local starterGui = game:GetService("StarterGui"):FindFirstChild("WNIGameUI")
		sounds = starterGui and starterGui:FindFirstChild("UISounds")
	end
	local source = sounds and (sounds:FindFirstChild("RollDice") or sounds:FindFirstChild("Dice") or sounds:FindFirstChild("Click"))
	if not source or not source:IsA("Sound") then return end
	local clone = source:Clone()
	clone.Name = "Dice3DFX_Bounce"
	clone.PlaybackSpeed = 0.9 + math.random() * 0.25
	clone.Volume = 0.9
	clone.Parent = workspace
	clone:Play()
	Debris:AddItem(clone, 3)
end

local PIP_LAYOUTS: {[number]: {Vector2}} = {
	[1] = {Vector2.new(0.5, 0.5)},
	[2] = {Vector2.new(0.3, 0.3), Vector2.new(0.7, 0.7)},
	[3] = {Vector2.new(0.25, 0.25), Vector2.new(0.5, 0.5), Vector2.new(0.75, 0.75)},
	[4] = {Vector2.new(0.3, 0.3), Vector2.new(0.7, 0.3), Vector2.new(0.3, 0.7), Vector2.new(0.7, 0.7)},
	[5] = {Vector2.new(0.28, 0.28), Vector2.new(0.72, 0.28), Vector2.new(0.5, 0.5), Vector2.new(0.28, 0.72), Vector2.new(0.72, 0.72)},
	[6] = {Vector2.new(0.3, 0.25), Vector2.new(0.7, 0.25), Vector2.new(0.3, 0.5), Vector2.new(0.7, 0.5), Vector2.new(0.3, 0.75), Vector2.new(0.7, 0.75)},
}
local NORMAL_FACES: {Enum.NormalId} = {Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right}

local function buildDie(skinKey: string?): BasePart
	local skin = (skinKey and ProgressionConfig.DICE_SKINS[skinKey]) or ProgressionConfig.DICE_SKINS.Classic
	local die = Instance.new("Part")
	die.Name = "Dice3D"
	die.Size = Vector3.new(DICE_SIZE, DICE_SIZE, DICE_SIZE)
	die.Color = skin.Color
	die.Material = skin.Material
	die.Anchored = true
	die.CanCollide = false
	die.CanQuery = false
	die.CanTouch = false
	die.CastShadow = true
	for _, normalId in ipairs(NORMAL_FACES) do
		local face = Instance.new("SurfaceGui")
		face.Name = "Pips"
		face.Face = normalId
		face.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		face.PixelsPerStud = 60
		face.Parent = die
	end
	return die
end

local FACE_VALUES: {[Enum.NormalId]: number} = {
	[Enum.NormalId.Top] = 1,
	[Enum.NormalId.Bottom] = 6,
	[Enum.NormalId.Front] = 2,
	[Enum.NormalId.Back] = 5,
	[Enum.NormalId.Right] = 3,
	[Enum.NormalId.Left] = 4,
}

local function paintDie(die: BasePart, skinKey: string?)
	local skin = (skinKey and ProgressionConfig.DICE_SKINS[skinKey]) or ProgressionConfig.DICE_SKINS.Classic
	local dotColor = skin.DotColor or Color3.fromRGB(35, 35, 40)
	for normalId, val in pairs(FACE_VALUES) do
		local layout = PIP_LAYOUTS[val]
		if not layout then continue end
		local found: SurfaceGui? = nil
		for _, child in ipairs(die:GetChildren()) do
			if child:IsA("SurfaceGui") and child.Face == normalId then found = child break end
		end
		if found then
			found:ClearAllChildren()
			for _, uv in ipairs(layout) do
				local pip = Instance.new("Frame")
				pip.AnchorPoint = Vector2.new(0.5, 0.5)
				pip.Position = UDim2.fromScale(uv.X, uv.Y)
				pip.Size = UDim2.fromScale(0.18, 0.18)
				pip.BackgroundColor3 = if val == 1 and skinKey == "Classic" then Color3.fromRGB(220, 50, 40) else dotColor
				pip.BorderSizePixel = 0
				pip.Parent = found
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(1, 0)
				corner.Parent = pip
			end
		end
	end
end

function Dice3DFX.rollDice3D(d1: number, d2: number, skinKey: string?)
	local board = workspace:FindFirstChild("WNIBoard")
	local center = if board then board:GetPivot().Position else Vector3.new(9, 9, 8)
	local values = {d1, d2}
	local dice: {BasePart} = {}
	for index = 1, 2 do
		local value = values[index]
		if typeof(value) ~= "number" or value < 1 or value > 6 then return end
		local die = buildDie(skinKey)
		paintDie(die, skinKey)
		local sideOffset = if index == 1 then -0.9 else 0.9
		local launch = CFrame.new(center + Vector3.new(sideOffset, 9, -2)) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		die.CFrame = launch
		die.Parent = workspace
		table.insert(dice, die)
	end
	playBounceSound()
	task.delay(0.18, function()
		for index, die in ipairs(dice) do
			if not die:IsDescendantOf(workspace) then continue end
			local value = values[index]
			local sideOffset = if index == 1 then -0.9 else 0.9
			local zOffset = if index == 1 then 0.5 else -0.5
			local landPos = center + Vector3.new(sideOffset, DICE_SIZE / 2 + 0.06, zOffset)
			local orient = FACE_ORIENTATIONS[value]
			local landCF = CFrame.new(landPos) * CFrame.Angles(math.rad(orient.X), 0, math.rad(orient.Z))
			local tumble = CFrame.new(landPos + Vector3.new(0, 2.2, 1.2)) * CFrame.Angles(math.rad(orient.X) + 2.4, math.random() * 6.28, math.rad(orient.Z) - 1.7)
			local flight = TweenService:Create(die, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = tumble})
			flight:Play()
			flight.Completed:Once(function()
				if not die:IsDescendantOf(workspace) then return end
				playBounceSound()
				local settle = TweenService:Create(die, TweenInfo.new(0.28, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {CFrame = landCF})
				settle:Play()
			end)
		end
	end)
	task.delay(1.55, function()
		for _, die in ipairs(dice) do
			if die:IsDescendantOf(workspace) then
				local fadeParts = {die}
				for _, descendant in ipairs(die:GetDescendants()) do
					if descendant:IsA("SurfaceGui") then
						for _, pip in ipairs(descendant:GetChildren()) do
							if pip:IsA("Frame") then table.insert(fadeParts, pip) end
						end
					end
				end
				for _, obj in ipairs(fadeParts) do
					local goal = {}
					if obj:IsA("BasePart") then goal.Transparency = 1 end
					if obj:IsA("Frame") then goal.BackgroundTransparency = 1 end
					TweenService:Create(obj, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), goal):Play()
				end
			end
		end
	end)
	for _, die in ipairs(dice) do
		Debris:AddItem(die, 2.8)
	end
end

return Dice3DFX
