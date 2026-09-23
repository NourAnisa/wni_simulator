--!strict
-- PawnEmoteVisualizer (client): triggers overhead emoji reactions from snapshot diffs (client-only).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local fxModule = shared:WaitForChild("PawnEmoteFX", 10)
if not fxModule or not fxModule:IsA("ModuleScript") then return end
local PawnEmoteFX = require(fxModule)

local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

local lastSnapshot: any = nil

stateUpdated.OnClientEvent:Connect(function(current)
	if typeof(current) ~= "table" then return end
	local previous = lastSnapshot
	lastSnapshot = current
	if typeof(previous) ~= "table" then return end
	local phase = current.phase
	if phase == "Waiting" or phase == "Finished" or phase == "Cancelled" then return end

	local prevPlayers = previous.players
	local curPlayers = current.players
	if typeof(prevPlayers) ~= "table" or typeof(curPlayers) ~= "table" then return end

	local playerCount = math.min(#prevPlayers, #curPlayers)

	-- Deteksi transaksi uang (Sewa / Gaji / Denda)
	local payers: {number} = {}
	local payees: {number} = {}

	for seat = 1, playerCount do
		local p0 = prevPlayers[seat]
		local p1 = curPlayers[seat]
		if typeof(p0) == "table" and typeof(p1) == "table" then
			local diff = (p1.cash or 0) - (p0.cash or 0)
			if diff < 0 then
				table.insert(payers, seat)
			elseif diff > 0 then
				table.insert(payees, seat)
				-- Gaji START (+Rp1.000.000)
				if diff == 1000000 then
					PawnEmoteFX.showEmote(seat, "💰", Color3.fromRGB(240, 195, 45))
				end
			end

			-- Masuk LAPAS
			if p0.inJail ~= true and p1.inJail == true then
				PawnEmoteFX.showEmote(seat, "🚓", Color3.fromRGB(220, 50, 50))
			end

			-- Sidang Pengadilan
			if (p0.position or 1) ~= (p1.position or 1) and p1.position == 25 then
				PawnEmoteFX.showEmote(seat, "⚖️", Color3.fromRGB(230, 180, 50))
			end

			-- Bangkrut
			if p0.eliminated ~= true and p1.eliminated == true then
				PawnEmoteFX.showEmote(seat, "💀", Color3.fromRGB(45, 45, 50))
			end
		end
	end

	-- Sewa antar-pemain: satu berkurang, satu bertambah
	if #payers > 0 and #payees > 0 then
		for _, payerSeat in ipairs(payers) do
			PawnEmoteFX.showEmote(payerSeat, "💸", Color3.fromRGB(220, 60, 60))
		end
		for _, payeeSeat in ipairs(payees) do
			PawnEmoteFX.showEmote(payeeSeat, "🤑", Color3.fromRGB(50, 185, 110))
		end
	end

	-- Deteksi beli tanah & upgrade rumah
	local prevOwners = previous.owners
	local curOwners = current.owners
	local prevBuilds = previous.buildings
	local curBuilds = current.buildings

	if typeof(prevOwners) == "table" and typeof(curOwners) == "table" then
		for i = 1, 40 do
			if (prevOwners[i] or 0) == 0 and (curOwners[i] or 0) > 0 then
				PawnEmoteFX.showEmote(curOwners[i], "🏠", Color3.fromRGB(70, 160, 240))
			end
		end
	end

	if typeof(prevBuilds) == "table" and typeof(curBuilds) == "table" and typeof(curOwners) == "table" then
		for i = 1, 40 do
			if (curBuilds[i] or 0) > (prevBuilds[i] or 0) and (curOwners[i] or 0) > 0 then
				PawnEmoteFX.showEmote(curOwners[i], "🏗️", Color3.fromRGB(235, 160, 40))
			end
		end
	end
end)
