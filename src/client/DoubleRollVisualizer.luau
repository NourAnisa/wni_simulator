--!strict
-- DoubleRollVisualizer.luau
-- Menghubungkan perubahan nilai dadu dari snapshot server ke efek selebrasi DoubleRollFX.
-- Bersifat modular, non-blocking, dan terisolasi dari core controller.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

local sharedFolder = ReplicatedStorage:WaitForChild("WNI", 10)
if not sharedFolder then return end

local doubleFXModule = sharedFolder:WaitForChild("DoubleRollFX", 10)
if not doubleFXModule or not doubleFXModule:IsA("ModuleScript") then return end
local DoubleRollFX = require(doubleFXModule)

local remotes = sharedFolder:WaitForChild("Remotes", 10)
if not remotes then return end

local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

local board = Workspace:WaitForChild("WNIBoard", 10)

local lastDiceState = {d1 = 0, d2 = 0, turn = 0}

local function resolveTargetPosition(activeSeat: number?): Vector3
	-- 1. Coba cari Dice3D di Workspace
	local dicePart = Workspace:FindFirstChild("Dice3D")
	if dicePart and dicePart:IsA("BasePart") then
		return dicePart.Position
	end

	-- 2. Coba cari pion pemain aktif di WNIBoard.Pawns
	if board and activeSeat and activeSeat > 0 then
		local pawnsFolder = board:FindFirstChild("Pawns")
		if pawnsFolder then
			local pawn = pawnsFolder:FindFirstChild(string.format("Pawn_%d", activeSeat))
				or pawnsFolder:FindFirstChild(string.format("MiniMe_%d", activeSeat))

			if pawn then
				if pawn:IsA("BasePart") then
					return pawn.Position
				elseif pawn:IsA("Model") then
					local root = pawn.PrimaryPart or pawn:FindFirstChildWhichIsA("BasePart")
					if root then
						return root.Position
					end
				end
			end
		end
	end

	-- 3. Fallback: Pusat meja papan
	return Vector3.new(9.225, 4.0, 8.603)
end

stateUpdated.OnClientEvent:Connect(function(snapshot: any)
	if typeof(snapshot) ~= "table" then return end

	local dice = snapshot.dice
	if typeof(dice) ~= "table" then return end

	local d1 = dice[1]
	local d2 = dice[2]
	if typeof(d1) ~= "number" or typeof(d2) ~= "number" then return end
	if d1 <= 0 or d2 <= 0 then return end

	local currentRev = typeof(snapshot.revision) == "number" and snapshot.revision or 0
	local activeSeat = typeof(snapshot.activeSeat) == "number" and snapshot.activeSeat or 0

	-- Cek apakah lemparan ini dadu kembar dan merupakan roll baru
	if d1 == d2 then
		local isNewRoll = (d1 ~= lastDiceState.d1 or d2 ~= lastDiceState.d2 or currentRev ~= lastDiceState.turn)
		if isNewRoll then
			lastDiceState = {d1 = d1, d2 = d2, turn = currentRev}

			-- Tentukan apakah pemain lokal yang melempar
			local isLocal = false
			if localPlayer and typeof(snapshot.players) == "table" and activeSeat > 0 then
				local activePlayerInfo = snapshot.players[activeSeat]
				if typeof(activePlayerInfo) == "table" then
					if activePlayerInfo.userId == localPlayer.UserId or activePlayerInfo.name == localPlayer.Name then
						isLocal = true
					end
				end
			end

			local targetPos = resolveTargetPosition(activeSeat)
			DoubleRollFX.playDouble(targetPos, d1, isLocal)
		end
	else
		lastDiceState = {d1 = d1, d2 = d2, turn = currentRev}
	end
end)
