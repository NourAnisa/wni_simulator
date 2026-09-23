--!strict
local configModule = script.Parent:WaitForChild("ExperienceConfig", 5)
assert(configModule and configModule:IsA("ModuleScript"), "ExperienceConfig missing")
local Config = require(configModule)

export type Admission = {
	matchId: string,
	mode: string,
	rulesVersion: string,
	roster: {number},
	reconnect: boolean,
	matchmakingProposalId: string?,
}

local MatchAdmissionService = {}

local function parseRoster(raw: any): {number}?
	if typeof(raw) ~= "table" or #raw ~= 4 then return nil end
	local roster: {number} = {}
	local seen: {[number]: boolean} = {}
	for index = 1, 4 do
		local userId = raw[index]
		if typeof(userId) ~= "number" or userId <= 0 or userId % 1 ~= 0 or seen[userId] then
			return nil
		end
		seen[userId] = true
		roster[index] = userId
	end
	return roster
end

function MatchAdmissionService.fromTeleportData(userId: number, teleportData: any): (Admission?, string?)
	if typeof(userId) ~= "number" or userId <= 0 or userId % 1 ~= 0 then
		return nil, "UserId tidak valid."
	end
	if typeof(teleportData) ~= "table" then
		return nil, "TeleportData pertandingan tidak tersedia."
	end
	if teleportData.schemaVersion ~= Config.SchemaVersion then
		return nil, "Versi data teleport tidak sesuai."
	end
	if teleportData.mode ~= Config.MatchMode then
		return nil, "Mode pertandingan tidak sesuai."
	end
	if teleportData.rulesVersion ~= Config.RulesVersion then
		return nil, "Versi aturan pertandingan tidak sesuai."
	end
	if typeof(teleportData.matchId) ~= "string" or #teleportData.matchId < 8 or #teleportData.matchId > 80 then
		return nil, "Match ID tidak valid."
	end
	local roster = parseRoster(teleportData.roster)
	if not roster then
		return nil, "Roster pertandingan tidak valid."
	end
	if not table.find(roster, userId) then
		return nil, "Akun ini bukan anggota roster pertandingan."
	end
	if teleportData.reconnect ~= nil and typeof(teleportData.reconnect) ~= "boolean" then
		return nil, "Flag reconnect tidak valid."
	end
	if teleportData.matchmakingProposalId ~= nil then
		if typeof(teleportData.matchmakingProposalId) ~= "string" or #teleportData.matchmakingProposalId < 8 or #teleportData.matchmakingProposalId > 80 then
			return nil, "Proposal matchmaking tidak valid."
		end
	end
	return {
		matchId = teleportData.matchId,
		mode = teleportData.mode,
		rulesVersion = teleportData.rulesVersion,
		roster = roster,
		reconnect = teleportData.reconnect == true,
		matchmakingProposalId = teleportData.matchmakingProposalId,
	}, nil
end

function MatchAdmissionService.fromPlayer(player: Player): (Admission?, string?)
	local joinData = player:GetJoinData()
	return MatchAdmissionService.fromTeleportData(player.UserId, joinData.TeleportData)
end

return table.freeze(MatchAdmissionService)
