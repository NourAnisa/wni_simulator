--!strict
-- BoardVisualizer: active-tile glow + jail strobe from snapshot diffs (client-only).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local fxModule = shared:WaitForChild("BoardHighlightFX", 10)
if not fxModule or not fxModule:IsA("ModuleScript") then return end
local BoardHighlightFX = require(fxModule)
local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

local board = Workspace:WaitForChild("WNIBoard", 10)
if not board then return end
local tilesFolder = board:WaitForChild("Tiles", 10)
if not tilesFolder then return end

local TEAM_COLOR = {
	A = Color3.fromRGB(80, 200, 160),
	B = Color3.fromRGB(255, 130, 90),
}
local JAIL_TILE = 9

local function tileAt(index: number): BasePart?
	return tilesFolder:FindFirstChild(string.format("Tile_%02d", index))
end

local function jailTile(): BasePart?
	return tileAt(JAIL_TILE)
end

local lastSnapshot: any = nil
stateUpdated.OnClientEvent:Connect(function(current)
	if typeof(current) ~= "table" then return end
	local previous = lastSnapshot
	lastSnapshot = current
	local phase = current.phase
	local over = phase == "Finished" or phase == "Cancelled" or phase == "Waiting"
	local activeSeat = current.activeSeat
	if not over and typeof(activeSeat) == "number" and activeSeat >= 1 and typeof(current.players) == "table" then
		local activePlayer = current.players[activeSeat]
		if typeof(activePlayer) == "table" and typeof(activePlayer.position) == "number" then
			local tile = tileAt(activePlayer.position)
			local color = TEAM_COLOR[activePlayer.team]
			if tile and color then
				BoardHighlightFX.highlightTile(tile, color)
			end
		end
	else
		BoardHighlightFX.clearHighlight()
	end
	if typeof(previous) == "table" and typeof(previous.players) == "table" and typeof(current.players) == "table" then
		for seat = 1, math.min(#previous.players, #current.players) do
			local prev = previous.players[seat]
			local cur = current.players[seat]
			if typeof(prev) == "table" and typeof(cur) == "table" and prev.inJail ~= true and cur.inJail == true then
				local target = jailTile()
				if target then
					BoardHighlightFX.triggerJailStrobe(target)
				end
			end
		end
	end
	if typeof(current.monopolies) == "table" then
		for _, team in ipairs({"A", "B"}) do
			local islands = current.monopolies[team]
			if typeof(islands) == "table" then
				local ISLAND_TILES: {[string]: {number}} = {
					SUMATERA = {2, 3, 5, 6, 8},
					KALIMANTAN = {10, 11, 13, 14, 16},
					SULAWESI = {18, 19, 21, 22, 24},
					PAPUA = {26, 27, 29, 30, 32},
					JAWA = {34, 35, 37, 38, 40},
				}
				for _, islandKey in ipairs(islands) do
					local tileList = ISLAND_TILES[islandKey]
					if tileList then
						for _, idx in ipairs(tileList) do
							local t = tileAt(idx)
							local container = t and t:FindFirstChild("Face") and t.Face:FindFirstChild("TileCardContainer")
							local stroke = container and container:FindFirstChildOfClass("UIStroke")
							if stroke then
								stroke.Color = if team == "A" then Color3.fromRGB(80, 240, 200) else Color3.fromRGB(255, 175, 75)
								stroke.Thickness = 8
							end
						end
					end
				end
			end
		end
	end
end)
