--!strict
-- MoneyFloat bootstrap: +/- cash labels floating from tiles on cash deltas (client-only).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local fxModule = shared:WaitForChild("FloatingFX", 10)
if not fxModule or not fxModule:IsA("ModuleScript") then return end
local FloatingFX = require(fxModule)
local rulesModule = shared:WaitForChild("PrototypeRules", 10)
if not rulesModule or not rulesModule:IsA("ModuleScript") then return end
local Rules = require(rulesModule)
local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

local board = Workspace:WaitForChild("WNIBoard", 10)
if not board then return end

local function anchorPosition(index: number): Vector3?
	local tiles = board:FindFirstChild("Tiles")
	local tile = tiles and tiles:FindFirstChild(string.format("Tile_%02d", index))
	local anchor = tile and tile:FindFirstChild("PawnAnchor")
	if anchor and anchor:IsA("Attachment") then return anchor.WorldPosition end
	return nil
end

local lastSnapshot: any = nil
stateUpdated.OnClientEvent:Connect(function(current)
	if typeof(current) ~= "table" then return end
	local previous = lastSnapshot
	lastSnapshot = current
	if typeof(previous) ~= "table" then return end
	local prevPlayers = previous.players
	local curPlayers = current.players
	if typeof(prevPlayers) ~= "table" or typeof(curPlayers) ~= "table" then return end
	for seat = 1, math.min(#prevPlayers, #curPlayers) do
		local prev = prevPlayers[seat]
		local cur = curPlayers[seat]
		if typeof(prev) == "table" and typeof(cur) == "table" and typeof(cur.cash) == "number" and typeof(prev.cash) == "number" then
			local delta = cur.cash - prev.cash
			if delta ~= 0 and typeof(cur.position) == "number" then
				local pos = anchorPosition(cur.position)
				if pos then
					FloatingFX.showMoney(pos, delta)
				end
			end
		end
	end
end)
