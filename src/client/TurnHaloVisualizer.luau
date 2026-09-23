--!strict
-- TurnHaloVisualizer.luau
-- Menghubungkan perubahan giliran aktif (snapshot.activeSeat) dari server ke visualisasi 3D TurnHaloFX.
-- Menyorot pion pemain yang sedang aktif bermain secara mulus dan adaptif.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

local sharedFolder = ReplicatedStorage:WaitForChild("WNI", 10)
if not sharedFolder then return end

local haloFXModule = sharedFolder:WaitForChild("TurnHaloFX", 10)
if not haloFXModule or not haloFXModule:IsA("ModuleScript") then return end
local TurnHaloFX = require(haloFXModule)

local remotes = sharedFolder:WaitForChild("Remotes", 10)
if not remotes then return end

local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

local board = Workspace:WaitForChild("WNIBoard", 10)

local TEAM_COLORS = {
	A = Color3.fromRGB(75, 215, 195),
	B = Color3.fromRGB(255, 160, 55),
}

local function findPawn(seat: number): Instance?
	if not board or seat <= 0 then return nil end
	local pawnsFolder = board:FindFirstChild("Pawns")
	if not pawnsFolder then return nil end

	return pawnsFolder:FindFirstChild(string.format("Pawn_%d", seat))
		or pawnsFolder:FindFirstChild(string.format("MiniMe_%d", seat))
end

local lastActiveSeat = -1

stateUpdated.OnClientEvent:Connect(function(snapshot: any)
	if typeof(snapshot) ~= "table" then return end

	local phase = snapshot.phase
	if phase == "Finished" or phase == "Cancelled" or phase == "Waiting" then
		TurnHaloFX.hide()
		lastActiveSeat = -1
		return
	end

	local activeSeat = typeof(snapshot.activeSeat) == "number" and snapshot.activeSeat or 0
	if activeSeat <= 0 then
		TurnHaloFX.hide()
		lastActiveSeat = -1
		return
	end

	if activeSeat ~= lastActiveSeat then
		lastActiveSeat = activeSeat

		local pawn = findPawn(activeSeat)
		local playerName = string.format("Pemain %d", activeSeat)
		local isLocal = false
		local teamColor = TEAM_COLORS.A

		if typeof(snapshot.players) == "table" then
			local p = snapshot.players[activeSeat]
			if typeof(p) == "table" then
				if typeof(p.name) == "string" then playerName = p.name end
				if localPlayer and (p.userId == localPlayer.UserId or p.name == localPlayer.Name) then
					isLocal = true
				end
				if p.team == "B" then
					teamColor = TEAM_COLORS.B
				end
			end
		end

		if pawn then
			TurnHaloFX.setTarget(pawn, playerName, isLocal, teamColor)
		else
			-- Coba cari lagi sebentar jika pion baru saja di-spawn
			task.delay(0.2, function()
				local retryPawn = findPawn(activeSeat)
				if retryPawn then
					TurnHaloFX.setTarget(retryPawn, playerName, isLocal, teamColor)
				end
			end)
		end
	end
end)
