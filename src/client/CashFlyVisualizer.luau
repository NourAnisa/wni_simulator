--!strict
-- CashFlyVisualizer.luau
-- Mendeteksi transaksi pembayaran (sewa tanah, denda, pajak, kas negara) dari snapshot server
-- dan memicu animasi lembaran uang terbang CashFlyFX dari pembayar ke penerima.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local sharedFolder = ReplicatedStorage:WaitForChild("WNI", 10)
if not sharedFolder then return end

local cashFXModule = sharedFolder:WaitForChild("CashFlyFX", 10)
if not cashFXModule or not cashFXModule:IsA("ModuleScript") then return end
local CashFlyFX = require(cashFXModule)

local remotes = sharedFolder:WaitForChild("Remotes", 10)
if not remotes then return end

local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

local board = Workspace:WaitForChild("WNIBoard", 10)
local STATE_TREASURY_POS = Vector3.new(9.225, 4.5, 8.603) -- Pusat meja / Paviliun Nusantara

local function resolvePawnPosition(seat: number): Vector3?
	if not board or seat <= 0 then return nil end
	local pawnsFolder = board:FindFirstChild("Pawns")
	if not pawnsFolder then return nil end

	local pawn = pawnsFolder:FindFirstChild(string.format("Pawn_%d", seat))
		or pawnsFolder:FindFirstChild(string.format("MiniMe_%d", seat))

	if pawn then
		if pawn:IsA("BasePart") then
			return pawn.Position
		elseif pawn:IsA("Model") then
			local root = pawn.PrimaryPart or pawn:FindFirstChildWhichIsA("BasePart")
			if root then return root.Position end
		end
	end
	return nil
end

local function findSeatByName(players: {any}, name: string): number?
	for seat, p in ipairs(players) do
		if typeof(p) == "table" and p.name == name then
			return seat
		end
	end
	return nil
end

local lastSeenLogIndex = 0

stateUpdated.OnClientEvent:Connect(function(snapshot: any)
	if typeof(snapshot) ~= "table" then return end

	local logs = snapshot.logs
	local players = snapshot.players
	if typeof(logs) ~= "table" or typeof(players) ~= "table" then return end

	if lastSeenLogIndex == 0 then
		lastSeenLogIndex = #logs
		return
	end

	for i = lastSeenLogIndex + 1, #logs do
		local line = logs[i]
		if typeof(line) == "string" then
			-- Pola umum: "<Payer> membayar <Amount> ke <Target>: <Reason>"
			local payerName, amountStr, targetName, reason = line:match("^(.-) membayar (.-) ke (.-): (.*)$")
			if payerName and targetName then
				local payerSeat = findSeatByName(players, payerName)
				local payerPos = if payerSeat then resolvePawnPosition(payerSeat) else nil

				if payerPos then
					local isToState = targetName:lower():find("negara") ~= nil
					local recipientPos: Vector3? = nil

					if isToState then
						recipientPos = STATE_TREASURY_POS
					else
						local recipientSeat = findSeatByName(players, targetName)
						recipientPos = if recipientSeat then resolvePawnPosition(recipientSeat) else nil
					end

					if recipientPos then
						CashFlyFX.flyCash(payerPos, recipientPos, isToState)
					end
				end
			end
		end
	end

	lastSeenLogIndex = #logs
end)
