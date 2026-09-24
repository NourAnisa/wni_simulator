--!strict
-- EndgameVisualizer (client): monitors player eliminations & match victory (client-only).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local fxModule = shared:WaitForChild("EndgameFX", 10)
if not fxModule or not fxModule:IsA("ModuleScript") then return end
local EndgameFX = require(fxModule)

local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

local board = Workspace:WaitForChild("WNIBoard", 10)
if not board then return end
local pawnsFolder = board:WaitForChild("Pawns", 10)
local tilesFolder = board:WaitForChild("Tiles", 10)

local function getPawnOrTile(seat: number, tileIndex: number?): Instance?
	if pawnsFolder then
		local miniMe = pawnsFolder:FindFirstChild("MiniMe_" .. tostring(seat))
		if miniMe then return miniMe end
		local pawn = pawnsFolder:FindFirstChild("Pawn_" .. tostring(seat))
		if pawn then return pawn end
	end
	if tileIndex and tilesFolder then
		local tile = tilesFolder:FindFirstChild(string.format("Tile_%02d", tileIndex))
		if tile then return tile end
	end
	return nil
end

local lastSnapshot: any = nil
local victoryPlayed = false

stateUpdated.OnClientEvent:Connect(function(current)
	if typeof(current) ~= "table" then return end
	local previous = lastSnapshot
	lastSnapshot = current

	-- Reset victory guard jika masuk lobi persiapan
	if current.phase == "Waiting" then
		victoryPlayed = false
	end

	-- Deteksi Eliminasi / Bangkrut
	if typeof(previous) == "table" and typeof(previous.players) == "table" and typeof(current.players) == "table" then
		for seat = 1, math.min(#previous.players, #current.players) do
			local prevPlayer = previous.players[seat]
			local curPlayer = current.players[seat]
			if typeof(prevPlayer) == "table" and typeof(curPlayer) == "table" then
				if prevPlayer.eliminated ~= true and curPlayer.eliminated == true then
					local target = getPawnOrTile(seat, curPlayer.position)
					if target then
						EndgameFX.playBankruptcy(target, curPlayer.name)
					end
				end
			end
		end
	end

	-- Deteksi Kemenangan (Phase -> Finished)
	if current.phase == "Finished" and not victoryPlayed then
		victoryPlayed = true
		local winningTeam = "A"
		if typeof(current.result) == "string" then
			if string.find(current.result, "SULTAN") then
				winningTeam = "SULTAN"
			elseif string.find(current.result, "Tim B") or string.find(current.result, "TIM B") then
				winningTeam = "B"
			end
		end
		EndgameFX.playVictory(winningTeam)
	end
end)
