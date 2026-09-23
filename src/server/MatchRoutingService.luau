--!strict
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local configModule = script.Parent:WaitForChild("ExperienceConfig", 5)
local registryModule = script.Parent:WaitForChild("SessionRegistryService", 5)
assert(configModule and configModule:IsA("ModuleScript"), "ExperienceConfig missing")
assert(registryModule and registryModule:IsA("ModuleScript"), "SessionRegistryService missing")
local Config = require(configModule)
local SessionRegistryService = require(registryModule)

export type Reservation = {
	matchId: string,
	accessCode: string,
	privateServerId: string,
	createdAt: number,
	proposalId: string?,
}

local MatchRoutingService = {}
MatchRoutingService.__index = MatchRoutingService

function MatchRoutingService.new()
	local self: any = setmetatable({}, MatchRoutingService)
	self.registry = SessionRegistryService.new()
	return self
end

function MatchRoutingService.createReservation(self: any): (Reservation?, string?)
	if not Config.canTeleportToMatch() then
		return nil, "Match teleport belum aktif: publish experience dan isi MatchPlaceId."
	end
	local ok, accessCode, privateServerId = pcall(function()
		return TeleportService:ReserveServerAsync(Config.MatchPlaceId)
	end)
	if not ok or typeof(accessCode) ~= "string" or accessCode == "" then
		return nil, "Gagal membuat reserved Match server."
	end
	return {
		matchId = HttpService:GenerateGUID(false),
		accessCode = accessCode,
		privateServerId = if typeof(privateServerId) == "string" then privateServerId else "",
		createdAt = os.time(),
	}, nil
end

function MatchRoutingService.teleportPlayers(self: any, players: {Player}, reservation: Reservation, rosterUserIds: {number}): (boolean, string?)
	if not Config.canTeleportToMatch() then
		return false, "Match teleport belum aktif."
	end
	if #players == 0 or #players > 4 then
		return false, "Roster teleport harus berisi 1-4 pemain lokal."
	end
	if #rosterUserIds ~= 4 then
		return false, "Roster Match harus tepat empat UserId."
	end
	local seen: {[number]: boolean} = {}
	for _, userId in rosterUserIds do
		if typeof(userId) ~= "number" or userId <= 0 or userId % 1 ~= 0 or seen[userId] then
			return false, "Roster Match tidak valid."
		end
		seen[userId] = true
	end
	for _, player in players do
		if not seen[player.UserId] then
			return false, "Pemain lokal bukan anggota roster Match."
		end
	end

	if not self.registry:registerRoster(reservation.matchId, reservation.accessCode, rosterUserIds) then
		return false, "Gagal mendaftarkan rute reconnect untuk roster Match."
	end

	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = reservation.accessCode
	local teleportData: any = {
		schemaVersion = Config.SchemaVersion,
		matchId = reservation.matchId,
		mode = Config.MatchMode,
		rulesVersion = Config.RulesVersion,
		roster = table.clone(rosterUserIds),
	}
	if typeof(reservation.proposalId) == "string" and #reservation.proposalId >= 8 and #reservation.proposalId <= 80 then
		teleportData.matchmakingProposalId = reservation.proposalId
	end
	options:SetTeleportData(teleportData)

	local ok, err = pcall(function()
		TeleportService:TeleportAsync(Config.MatchPlaceId, players, options)
	end)
	if not ok then
		return false, "Teleport ke Match gagal: " .. tostring(err)
	end
	return true, nil
end

function MatchRoutingService.getReconnectRoute(self: any, userId: number): any
	return self.registry:get(userId)
end

function MatchRoutingService.armReconnect(self: any, userId: number): boolean
	return self.registry:armReconnect(userId)
end

function MatchRoutingService.refreshSession(self: any, userId: number): boolean
	return self.registry:refreshSession(userId)
end

function MatchRoutingService.clearReconnect(self: any, userId: number)
	self.registry:clear(userId)
end

function MatchRoutingService.clearReconnectRoster(self: any, rosterUserIds: {number})
	self.registry:clearRoster(rosterUserIds)
end

function MatchRoutingService.teleportLobby(self: any, player: Player): (boolean, string?)
	if not Config.canReturnToLobby() then
		return false, "Lobby teleport belum aktif: publish experience dan isi LobbyPlaceId."
	end
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(Config.LobbyPlaceId, {player})
	end)
	if not ok then
		return false, "Teleport ke Lobby gagal: " .. tostring(err)
	end
	return true, nil
end

function MatchRoutingService.teleportReconnect(self: any, player: Player, proposalId: string?): (boolean, string?)
	local route = self.registry:get(player.UserId)
	if not route then
		return false, "Tidak ada sesi aktif yang dapat disambungkan kembali."
	end
	if route.expiresAt <= os.time() then
		self.registry:clear(player.UserId)
		return false, "Jendela reconnect sudah berakhir."
	end
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = route.accessCode
	local teleportData: any = {
		schemaVersion = Config.SchemaVersion,
		matchId = route.matchId,
		mode = Config.MatchMode,
		rulesVersion = Config.RulesVersion,
		roster = table.clone(route.roster),
		reconnect = true,
	}
	if typeof(proposalId) == "string" and #proposalId >= 8 and #proposalId <= 80 then
		teleportData.matchmakingProposalId = proposalId
	end
	options:SetTeleportData(teleportData)
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(route.matchPlaceId, {player}, options)
	end)
	if not ok then
		return false, "Reconnect ke Match gagal: " .. tostring(err)
	end
	return true, nil
end

return MatchRoutingService
