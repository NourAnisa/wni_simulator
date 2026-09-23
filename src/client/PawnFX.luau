--!strict
-- PawnFX bootstrap: wires PawnAnimator to the WNI snapshot stream (client-only visuals).
-- Also renders floating cash popups (+Rp / -Rp) on money transactions.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local animatorModule = shared:WaitForChild("PawnAnimator", 10)
if not animatorModule or not animatorModule:IsA("ModuleScript") then return end
local PawnAnimator = require(animatorModule)
local rulesModule = shared:WaitForChild("PrototypeRules", 10)
if not rulesModule or not rulesModule:IsA("ModuleScript") then return end
local Rules = require(rulesModule)

local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

local board = Workspace:WaitForChild("WNIBoard", 10)
if not board then return end
local pawnFolder = board:WaitForChild("Pawns", 10)
if not pawnFolder then return end
PawnAnimator.watch(pawnFolder)

local function tileAt(index: number): BasePart?
	local tiles = board:FindFirstChild("Tiles")
	if not tiles then return nil end
	return tiles:FindFirstChild(string.format("Tile_%02d", index))
end

local function spawnFloatingCash(seat: number, delta: number)
	if math.abs(delta) < 100 then return end
	local pawn = pawnFolder:FindFirstChild("MiniMe_" .. seat) or pawnFolder:FindFirstChild("Pawn_" .. seat)
	if not pawn then return end
	local adornee: BasePart? = nil
	if pawn:IsA("Model") then
		adornee = (pawn:FindFirstChild("Head") or pawn.PrimaryPart or pawn:FindFirstChildWhichIsA("BasePart")) :: BasePart?
	elseif pawn:IsA("BasePart") then
		adornee = pawn
	end
	if not adornee then return end

	local isGain = delta > 0
	local text = if isGain then ("+" .. Rules.formatMoney(delta)) else Rules.formatMoney(delta)
	local textColor = if isGain then Color3.fromRGB(75, 250, 150) else Color3.fromRGB(255, 80, 80)
	local strokeColor = if isGain then Color3.fromRGB(15, 60, 30) else Color3.fromRGB(65, 15, 15)

	local bb = Instance.new("BillboardGui")
	bb.Name = "FloatingCash_" .. seat
	bb.Adornee = adornee
	bb.Size = UDim2.fromOffset(160, 38)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.AlwaysOnTop = true
	bb.ResetOnSpawn = false

	local label = Instance.new("TextLabel")
	label.Name = "CashText"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = textColor
	label.TextStrokeColor3 = strokeColor
	label.TextStrokeTransparency = 0.2
	label.Parent = bb

	local stroke = Instance.new("UIStroke")
	stroke.Color = strokeColor
	stroke.Thickness = 2.5
	stroke.Transparency = 0.2
	stroke.Parent = label

	local textSizeLimit = Instance.new("UITextSizeConstraint")
	textSizeLimit.MinTextSize = 12
	textSizeLimit.MaxTextSize = 22
	textSizeLimit.Parent = label

	bb.Parent = adornee

	-- Animate upwards and fade out
	local duration = 1.35
	local tweenOffset = TweenService:Create(bb, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 4.6, 0)
	})
	local tweenFade = TweenService:Create(label, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1
	})
	local tweenStroke = TweenService:Create(stroke, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Transparency = 1
	})

	tweenOffset:Play()
	tweenFade:Play()
	tweenStroke:Play()

	Debris:AddItem(bb, duration + 0.1)
end

local lastSnapshot: any = nil
stateUpdated.OnClientEvent:Connect(function(current)
	if typeof(current) ~= "table" then return end
	local previous = lastSnapshot
	lastSnapshot = current
	if typeof(previous) ~= "table" then return end

	-- Land Purchase FX
	local prevOwners = previous.owners
	local curOwners = current.owners
	if typeof(prevOwners) == "table" and typeof(curOwners) == "table" then
		for index = 1, 40 do
			if (prevOwners[index] or 0) == 0 and (curOwners[index] or 0) > 0 then
				local tile = tileAt(index)
				if tile then PawnAnimator.celebratePurchase(tile) end
			end
		end
	end

	-- Building Upgrade FX
	local prevBuilds = previous.buildings
	local curBuilds = current.buildings
	if typeof(prevBuilds) == "table" and typeof(curBuilds) == "table" then
		for index = 1, 40 do
			if (curBuilds[index] or 0) > (prevBuilds[index] or 0) then
				local tile = tileAt(index)
				if tile then PawnAnimator.celebrateBuild(tile) end
			end
		end
	end

	-- Floating Cash FX for all seats
	local prevPlayers = previous.players
	local curPlayers = current.players
	if typeof(prevPlayers) == "table" and typeof(curPlayers) == "table" then
		for seat = 1, 4 do
			local pPrev = prevPlayers[seat]
			local pCur = curPlayers[seat]
			if pPrev and pCur and typeof(pPrev.cash) == "number" and typeof(pCur.cash) == "number" then
				local delta = pCur.cash - pPrev.cash
				if delta ~= 0 then
					spawnFloatingCash(seat, delta)
				end
			end
		end
	end
end)
