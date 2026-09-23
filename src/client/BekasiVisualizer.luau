--!strict
-- BekasiVisualizer.luau
-- Mendeteksi status evakuasi pemain ke pulau pengasingan Bekasi (inBekasi) dari snapshot server
-- dan memicu efek dramatis banjir bandang BekasiFX.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local sharedFolder = ReplicatedStorage:WaitForChild("WNI", 10)
if not sharedFolder then return end

local bekasiFXModule = sharedFolder:WaitForChild("BekasiFX", 10)
if not bekasiFXModule or not bekasiFXModule:IsA("ModuleScript") then return end
local BekasiFX = require(bekasiFXModule)

local remotes = sharedFolder:WaitForChild("Remotes", 10)
if not remotes then return end

local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

local board = Workspace:WaitForChild("WNIBoard", 10)
local decos = board and board:WaitForChild("Decorations", 10)
local bekasiDisplay = decos and decos:WaitForChild("BekasiDisplay", 10) :: BasePart?

local BEKASI_DEFAULT_POS = Vector3.new(27.225, 3.9, 10.6)

local function getBekasiPosition(): Vector3
	if bekasiDisplay and bekasiDisplay:IsA("BasePart") then
		return bekasiDisplay.Position + Vector3.new(0, 1.2, 0)
	end
	return BEKASI_DEFAULT_POS
end

local function getTilePosition(index: number): Vector3
	if board then
		local tiles = board:FindFirstChild("Tiles")
		if tiles then
			local tile = tiles:FindFirstChild(string.format("Tile_%02d", index))
			if tile and tile:IsA("BasePart") then
				return tile.Position + Vector3.new(0, 1.0, 0)
			end
		end
	end
	return Vector3.new(9.225, 3.5, 8.603)
end

local lastBekasiState: {[number]: boolean} = {}

stateUpdated.OnClientEvent:Connect(function(snapshot: any)
	if typeof(snapshot) ~= "table" then return end
	local players = snapshot.players
	if typeof(players) ~= "table" then return end

	for seat = 1, 4 do
		local p = players[seat]
		if typeof(p) == "table" then
			local isBekasi = p.inBekasi == true
			local wasBekasi = lastBekasiState[seat] == true

			if isBekasi and not wasBekasi then
				-- Pemain baru saja terdampar di Bekasi
				local tileIdx = typeof(p.position) == "number" and p.position or 1
				local originPos = getTilePosition(tileIdx)
				local bekasiPos = getBekasiPosition()
				BekasiFX.playEvacuate(originPos, bekasiPos)
			elseif not isBekasi and wasBekasi then
				-- Pemain selesai lewati giliran dan pulang ke lintasan
				local tileIdx = typeof(p.position) == "number" and p.position or 1
				local returnPos = getTilePosition(tileIdx)
				BekasiFX.playReturn(returnPos)
			end

			lastBekasiState[seat] = isBekasi
		end
	end
end)
