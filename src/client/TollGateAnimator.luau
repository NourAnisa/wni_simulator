--!strict
-- TollGateAnimator (client): dynamic boom barrier lift & card tapping flash when pawns approach G-TOLL.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

local board = Workspace:WaitForChild("WNIBoard", 10)
if not board then return end
local buildings = board:WaitForChild("Buildings", 10)
if not buildings then return end

type GateState = {
	model: Model,
	isOpen: boolean,
	barrier: BasePart,
	stripes: {BasePart},
	reader: BasePart?,
	hingeCF: CFrame,
	barrierLocalCF: CFrame,
	stripeLocalCFs: {CFrame},
	baseBarrierCF: CFrame,
	baseStripeCFs: {CFrame},
}

local gates: {[number]: GateState} = {}

local function setupGate(model: Model, tileIndex: number)
	if gates[tileIndex] and gates[tileIndex].model == model then return end
	local barrier = model:FindFirstChild("BoomBarrier") :: BasePart?
	local tapBooth = model:FindFirstChild("TapBooth") :: BasePart?
	if not barrier or not tapBooth then return end

	local reader = model:FindFirstChild("TapCardReader") :: BasePart?
	local stripes: {BasePart} = {}
	for _, child in ipairs(model:GetChildren()) do
		if string.find(child.Name, "Stripe") and child:IsA("BasePart") then
			table.insert(stripes, child)
		end
	end

	local hingeCF = tapBooth.CFrame * CFrame.new(0, 0.4, 0)
	local barrierLocal = hingeCF:ToObjectSpace(barrier.CFrame)
	local stripeLocals: {CFrame} = {}
	local baseStripeCFs: {CFrame} = {}
	for _, s in ipairs(stripes) do
		table.insert(stripeLocals, hingeCF:ToObjectSpace(s.CFrame))
		table.insert(baseStripeCFs, s.CFrame)
	end

	gates[tileIndex] = {
		model = model,
		isOpen = false,
		barrier = barrier,
		stripes = stripes,
		reader = reader,
		hingeCF = hingeCF,
		barrierLocalCF = barrierLocal,
		stripeLocalCFs = stripeLocals,
		baseBarrierCF = barrier.CFrame,
		baseStripeCFs = baseStripeCFs,
	}
end

local function setGateOpen(gate: GateState, open: boolean)
	if gate.isOpen == open then return end
	gate.isOpen = open

	local angle = if open then math.rad(75) else 0
	local targetHinge = gate.hingeCF * CFrame.Angles(0, 0, angle)
	local targetBarrierCF = targetHinge * gate.barrierLocalCF

	local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Back, if open then Enum.EasingDirection.Out else Enum.EasingDirection.In)
	TweenService:Create(gate.barrier, tweenInfo, {CFrame = targetBarrierCF}):Play()

	for i, s in ipairs(gate.stripes) do
		local targetStripeCF = targetHinge * gate.stripeLocalCFs[i]
		TweenService:Create(s, tweenInfo, {CFrame = targetStripeCF}):Play()
	end

	if gate.reader then
		local readerColor = if open then Color3.fromRGB(80, 255, 200) else Color3.fromRGB(50, 200, 100)
		TweenService:Create(gate.reader, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Color = readerColor
		}):Play()
	end

	if open then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.Volume = 0.35
		sound.PlaybackSpeed = 1.6
		sound.Parent = gate.barrier
		sound:Play()
		Debris:AddItem(sound, 1.5)
	end
end

local function scanBuildings()
	for _, child in ipairs(buildings:GetChildren()) do
		if child:IsA("Model") and child.Name:sub(1, 2) == "B_" and child:GetAttribute("IsToll") == true then
			local index = tonumber(child.Name:sub(3))
			if index then
				setupGate(child, index)
			end
		end
	end
end

scanBuildings()
buildings.ChildAdded:Connect(function()
	task.wait(0.1)
	scanBuildings()
end)

stateUpdated.OnClientEvent:Connect(function(current)
	if typeof(current) ~= "table" then return end
	local players = current.players
	if typeof(players) ~= "table" then return end

	for index, gate in pairs(gates) do
		if not gate.model:IsDescendantOf(Workspace) then
			gates[index] = nil
			continue
		end
		local pawnOnTile = false
		for _, p in ipairs(players) do
			if typeof(p) == "table" and p.position == index then
				pawnOnTile = true
				break
			end
		end
		setGateOpen(gate, pawnOnTile)
	end
end)
