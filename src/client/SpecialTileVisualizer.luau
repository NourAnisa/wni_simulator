--!strict
-- SpecialTileVisualizer (client): monitors pawn movement and triggers 3D atmosphere on special tiles.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local fxModule = shared:WaitForChild("SpecialTileFX", 10)
if not fxModule or not fxModule:IsA("ModuleScript") then return end
local SpecialTileFX = require(fxModule)

local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

local board = Workspace:WaitForChild("WNIBoard", 10)
if not board then return end
local tilesFolder = board:WaitForChild("Tiles", 10)
if not tilesFolder then return end

local function tileAt(index: number): BasePart?
	return tilesFolder:FindFirstChild(string.format("Tile_%02d", index))
end

local lastSnapshot: any = nil

stateUpdated.OnClientEvent:Connect(function(current)
	if typeof(current) ~= "table" then return end
	local previous = lastSnapshot
	lastSnapshot = current
	if typeof(previous) ~= "table" then return end
	if current.phase == "Waiting" or current.phase == "Finished" or current.phase == "Cancelled" then return end

	local prevPlayers = previous.players
	local curPlayers = current.players
	if typeof(prevPlayers) ~= "table" or typeof(curPlayers) ~= "table" then return end

	for seat = 1, math.min(#prevPlayers, #curPlayers) do
		local prevP = prevPlayers[seat]
		local curP = curPlayers[seat]
		if typeof(prevP) == "table" and typeof(curP) == "table" then
			local oldPos = prevP.position or 1
			local newPos = curP.position or 1
			if oldPos ~= newPos then
				local tile = tileAt(newPos)
				if tile then
					local kind = tile:GetAttribute("TileKind")
					if kind == "Start" then
						SpecialTileFX.triggerStartSalary(tile)
					elseif kind == "Tax" then
						SpecialTileFX.triggerTaxFine(tile)
					elseif kind == "Court" then
						SpecialTileFX.triggerCourtTrial(tile)
					elseif kind == "Fate" then
						SpecialTileFX.triggerCardVortex(tile, false)
					elseif kind == "Disaster" then
						SpecialTileFX.triggerCardVortex(tile, true)
					end
				end
			end
		end
	end
end)
