--!strict
-- CardDeckVisualizer.luau
-- Menghubungkan deck kartu fisik 3D dengan event penarikan kartu dari snapshot server WNI Simulator.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local sharedFolder = ReplicatedStorage:WaitForChild("WNI", 10)
if not sharedFolder then return end

local deckFXModule = sharedFolder:WaitForChild("CardDeck3DFX", 10)
if not deckFXModule or not deckFXModule:IsA("ModuleScript") then return end
local CardDeck3DFX = require(deckFXModule)

local remotes = sharedFolder:WaitForChild("Remotes", 10)
if not remotes then return end

local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

-- Inisialisasi prop dek 3D di atas papan
task.defer(function()
	CardDeck3DFX.ensureDecks()
end)

local lastSeenLogIndex = 0

stateUpdated.OnClientEvent:Connect(function(snapshot: any)
	if typeof(snapshot) ~= "table" then return end

	local logs = snapshot.logs
	if typeof(logs) ~= "table" then return end

	if lastSeenLogIndex == 0 then
		lastSeenLogIndex = #logs
		return
	end

	for i = lastSeenLogIndex + 1, #logs do
		local line = logs[i]
		if typeof(line) == "string" then
			-- Contoh log: "Pemain 1 menarik KPK (Musibah, dadu 4)." atau "Pemain 2 menarik Mafia Tanah (Takdir)."
			local cardName, deckName = line:match("menarik (.-) %((%u%a+), dadu %d+%)")
			if not cardName then
				cardName, deckName = line:match("menarik (.-) %((%u%a+)%)")
			end

			if cardName and deckName then
				CardDeck3DFX.animateDraw(deckName, cardName, 2.5)
			end
		end
	end

	lastSeenLogIndex = #logs
end)
