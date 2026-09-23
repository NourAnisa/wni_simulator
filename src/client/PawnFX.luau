--!strict
-- PawnFX bootstrap: wires PawnAnimator to the WNI snapshot stream (client-only visuals).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local animatorModule = shared:WaitForChild("PawnAnimator", 10)
if not animatorModule or not animatorModule:IsA("ModuleScript") then return end
local PawnAnimator = require(animatorModule)
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
end)
