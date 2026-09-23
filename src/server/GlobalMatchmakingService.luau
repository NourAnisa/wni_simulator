--!strict
local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")

local configModule = script.Parent:WaitForChild("ExperienceConfig", 5)
assert(configModule and configModule:IsA("ModuleScript"), "ExperienceConfig missing")
local Config = require(configModule)

export type QueueEntry = {
	userId: number,
	name: string,
	jobId: string,
	joinedAt: number,
}

export type Proposal = {
	id: string,
	revision: number,
	roster: {QueueEntry},
	accepted: {[string]: boolean},
	declinedBy: number,
	deadline: number,
	createdAt: number,
	routingOwner: string?,
	routingOwnerExpiresAt: number?,
	route: any?,
	routeFailed: string?,
}

local QUEUE_NAME = "WNI_GlobalQueue_v1"
local LOCK_NAME = "WNI_GlobalQueueLock_v1"
local PROPOSAL_NAME = "WNI_GlobalProposal_v1"
local PLAYER_STATE_NAME = "WNI_GlobalPlayerState_v1"
local QUEUE_TTL = 180
local LOCK_TTL = 5
local PROPOSAL_TTL = 45
local ROUTED_PROPOSAL_TTL = 120
local ACCEPT_SECONDS = 15

local queue: any = nil
local lockMap: any = nil
local proposalMap: any = nil
local playerStateMap: any = nil
local storesOK = pcall(function()
	queue = MemoryStoreService:GetSortedMap(QUEUE_NAME)
	lockMap = MemoryStoreService:GetHashMap(LOCK_NAME)
	proposalMap = MemoryStoreService:GetHashMap(PROPOSAL_NAME)
	playerStateMap = MemoryStoreService:GetHashMap(PLAYER_STATE_NAME)
end)
if not storesOK then
	queue = nil
	lockMap = nil
	proposalMap = nil
	playerStateMap = nil
end

local GlobalMatchmakingService = {}
GlobalMatchmakingService.__index = GlobalMatchmakingService

local function validEntry(value: any): boolean
	return typeof(value) == "table"
		and typeof(value.userId) == "number"
		and value.userId > 0
		and value.userId % 1 == 0
		and typeof(value.name) == "string"
		and #value.name >= 1
		and #value.name <= 64
		and typeof(value.jobId) == "string"
		and #value.jobId <= 128
		and typeof(value.joinedAt) == "number"
end

local function validProposal(value: any): boolean
	if typeof(value) ~= "table" or typeof(value.id) ~= "string" or #value.id < 8 then return false end
	if typeof(value.revision) ~= "number" or value.revision ~= value.revision or value.revision % 1 ~= 0 or value.revision < 0 or value.revision > 1000000000 then return false end
	if typeof(value.roster) ~= "table" or #value.roster ~= 4 then return false end
	if typeof(value.accepted) ~= "table" or typeof(value.deadline) ~= "number" then return false end
	local seen: {[number]: boolean} = {}
	for _, entry in value.roster do
		if not validEntry(entry) or seen[entry.userId] then return false end
		seen[entry.userId] = true
	end
	return true
end

local function revisionForId(id: string): number
	local hash = 0
	for index = 1, #id do
		hash = (hash * 131 + string.byte(id, index)) % 1000000001
	end
	return hash
end

local function enabled(): boolean
	return Config.isPublished() and Config.LobbyPlaceId > 0 and game.PlaceId == Config.LobbyPlaceId
end

local function proposalStoreAvailable(): boolean
	return Config.isPublished() and proposalMap ~= nil and playerStateMap ~= nil
end

function GlobalMatchmakingService.new()
	local self: any = setmetatable({}, GlobalMatchmakingService)
	self.ownerToken = HttpService:GenerateGUID(false)
	self.queueRowsCache = {} :: {any}
	self.queueRowsCacheAt = -math.huge
	return self
end

function GlobalMatchmakingService.isEnabled(_self: any): boolean
	return enabled() and queue ~= nil and lockMap ~= nil and proposalMap ~= nil and playerStateMap ~= nil
end

function GlobalMatchmakingService.enqueue(self: any, player: Player, now: number): (boolean, string)
	if not self:isEnabled() then return false, "Matchmaking global belum aktif." end
	if typeof(now) ~= "number" or now ~= now then return false, "Waktu antrean tidak valid." end
	local entry: QueueEntry = {
		userId = player.UserId,
		name = string.sub(player.DisplayName, 1, 64),
		jobId = string.sub(game.JobId, 1, 128),
		joinedAt = now,
	}
	local ok = pcall(function()
		queue:SetAsync("u_" .. tostring(player.UserId), entry, QUEUE_TTL, now)
	end)
	if not ok then return false, "Gagal masuk antrean matchmaking global." end
	self:invalidateQueueCache()
	return true, "Masuk antrean matchmaking global."
end

function GlobalMatchmakingService.isQueued(self: any, userId: number): boolean
	if not self:isEnabled() then return false end
	local ok, value = pcall(function()
		return queue:GetAsync("u_" .. tostring(userId))
	end)
	return ok and validEntry(value)
end

function GlobalMatchmakingService.remove(self: any, userId: number): boolean
	if not self:isEnabled() then return false end
	if typeof(userId) ~= "number" or userId <= 0 or userId % 1 ~= 0 then return false end
	local ok = pcall(function()
		queue:RemoveAsync("u_" .. tostring(userId))
		playerStateMap:RemoveAsync("u_" .. tostring(userId))
	end)
	if ok then self:invalidateQueueCache() end
	return ok
end

function GlobalMatchmakingService.handlePlayerLeaving(self: any, userId: number, teleportingToMatch: boolean): boolean
	if not self:isEnabled() then return false end
	if typeof(userId) ~= "number" or userId <= 0 or userId % 1 ~= 0 then return false end
	local key = "u_" .. tostring(userId)
	local proposal = self:getPlayerProposal(userId)
	local ok = pcall(function()
		queue:RemoveAsync(key)
		if teleportingToMatch then
			return
		end
		if proposal then
			if proposal.route ~= nil then
				return
			end
			proposalMap:UpdateAsync(proposal.id, function(current: any)
				if not validProposal(current) then return current end
				if current.route ~= nil then return current end
				current.declinedBy = userId
				return current
			end, PROPOSAL_TTL)
		end
		playerStateMap:RemoveAsync(key)
	end)
	if ok then self:invalidateQueueCache() end
	return ok
end

function GlobalMatchmakingService.getPlayerProposal(self: any, userId: number): Proposal?
	if not self:isEnabled() then return nil end
	local okState, state = pcall(function()
		return playerStateMap:GetAsync("u_" .. tostring(userId))
	end)
	if not okState or typeof(state) ~= "table" or typeof(state.proposalId) ~= "string" then return nil end
	local okProposal, proposal = pcall(function()
		return proposalMap:GetAsync(state.proposalId)
	end)
	if not okProposal or not validProposal(proposal) then return nil end
	return proposal :: Proposal
end

function GlobalMatchmakingService.respond(self: any, userId: number, accept: boolean, expectedRevision: number): (boolean, string)
	if not self:isEnabled() then return false, "Matchmaking global belum aktif." end
	local proposal = self:getPlayerProposal(userId)
	if not proposal then return false, "Proposal matchmaking global tidak ditemukan." end
	if proposal.revision ~= expectedRevision then return false, "Konfirmasi match berubah; coba kembali." end
	if os.time() > proposal.deadline then return false, "Waktu konfirmasi matchmaking global habis." end
	local belongs = false
	for _, entry in proposal.roster do
		if entry.userId == userId then belongs = true break end
	end
	if not belongs then return false, "Akun bukan anggota proposal ini." end
	if accept and proposal.accepted[tostring(userId)] == true then
		return false, "Kamu sudah menerima match global ini."
	end
	local proposalId = proposal.id
	local updated: any = nil
	local ok = pcall(function()
		updated = proposalMap:UpdateAsync(proposalId, function(current: any)
			if not validProposal(current) then return nil end
			if current.revision ~= expectedRevision then return current end
			if os.time() > current.deadline then return current end
			local key = tostring(userId)
			if accept then
				current.accepted[key] = true
			else
				current.declinedBy = userId
			end
			return current
		end, PROPOSAL_TTL)
	end)
	if not ok or not validProposal(updated) then return false, "Gagal menyimpan konfirmasi matchmaking global." end
	if not accept then return true, "Match global ditolak." end
	local count = 0
	for _, entry in updated.roster do
		if updated.accepted[tostring(entry.userId)] == true then count += 1 end
	end
	return true, string.format("Match global diterima (%d/4).", count)
end

function GlobalMatchmakingService.tryCreateProposal(self: any): (Proposal?, string?)
	if not self:isEnabled() then return nil, nil end
	local now = os.time()
	local acquired = false
	local okLock, lockValue = pcall(function()
		return lockMap:UpdateAsync("coordinator", function(current: any)
			if typeof(current) == "table" and typeof(current.expiresAt) == "number" and current.expiresAt > now and current.owner ~= self.ownerToken then
				return current
			end
			return {owner = self.ownerToken, expiresAt = now + LOCK_TTL}
		end, LOCK_TTL)
	end)
	if okLock and typeof(lockValue) == "table" and lockValue.owner == self.ownerToken then acquired = true end
	if not acquired then return nil, nil end

	local proposal: Proposal? = nil
	local failure: string? = nil
	local okWork, workError = pcall(function()
		local rows = queue:GetRangeAsync(Enum.SortDirection.Ascending, 12)
		local roster: {QueueEntry} = {}
		local keys: {string} = {}
		local seen: {[number]: boolean} = {}
		for _, row in rows do
			local value = row.value
			if validEntry(value) and not seen[value.userId] then
				table.insert(roster, value)
				table.insert(keys, row.key)
				seen[value.userId] = true
				if #roster == 4 then break end
			end
		end
		if #roster < 4 then return end

		local proposalId = HttpService:GenerateGUID(false)
		local created: Proposal = {
			id = proposalId,
			revision = revisionForId(proposalId),
			roster = roster,
			accepted = {},
			declinedBy = 0,
			deadline = now + ACCEPT_SECONDS,
			createdAt = now,
		}
		proposalMap:SetAsync(proposalId, created, PROPOSAL_TTL)
		for index, entry in roster do
			queue:RemoveAsync(keys[index])
			playerStateMap:SetAsync("u_" .. tostring(entry.userId), {proposalId = proposalId}, PROPOSAL_TTL)
		end
		proposal = created
		self:invalidateQueueCache()
	end)
	if not okWork then failure = "Gagal membentuk proposal matchmaking global: " .. tostring(workError) end
	pcall(function()
		local current = lockMap:GetAsync("coordinator")
		if typeof(current) == "table" and current.owner == self.ownerToken then lockMap:RemoveAsync("coordinator") end
	end)
	return proposal, failure
end

function GlobalMatchmakingService.getQueueRows(self: any): {any}
	if not self:isEnabled() then return {} end
	local now = os.clock()
	if now - self.queueRowsCacheAt < 1 then return self.queueRowsCache end
	local okRows, rows = pcall(function()
		return queue:GetRangeAsync(Enum.SortDirection.Ascending, 100)
	end)
	if okRows and typeof(rows) == "table" then
		self.queueRowsCache = rows
		self.queueRowsCacheAt = now
	end
	return self.queueRowsCache
end

function GlobalMatchmakingService.invalidateQueueCache(self: any)
	self.queueRowsCacheAt = -math.huge
end

function GlobalMatchmakingService.snapshot(self: any, userId: number): any
	local result = {
		revision = 0,
		queued = false,
		position = 0,
		count = 0,
		needed = 4,
		localServerOnly = false,
		global = true,
		matchFound = false,
		accepted = false,
		acceptedCount = 0,
		deadline = 0,
	}
	if not self:isEnabled() then return result end
	local rows = self:getQueueRows()
	result.count = #rows
	result.needed = math.max(0, 4 - #rows)
	for index, row in rows do
		local value = row.value
		if validEntry(value) and value.userId == userId then
			result.queued = true
			result.position = index
			break
		end
	end
	local proposal = self:getPlayerProposal(userId)
	if proposal then
		result.revision = proposal.revision
		result.queued = false
		result.position = 0
		result.matchFound = true
		result.accepted = proposal.accepted[tostring(userId)] == true
		result.deadline = proposal.deadline
		for _, entry in proposal.roster do
			if proposal.accepted[tostring(entry.userId)] == true then result.acceptedCount += 1 end
		end
	end
	return result
end

function GlobalMatchmakingService.claimRouting(self: any, proposalId: string): boolean
	if not self:isEnabled() then return false end
	local now = os.time()
	local updated: any = nil
	local ok = pcall(function()
		updated = proposalMap:UpdateAsync(proposalId, function(current: any)
			if not validProposal(current) or current.declinedBy ~= 0 or current.route ~= nil then return current end
			local acceptedCount = 0
			for _, entry in current.roster do
				if current.accepted[tostring(entry.userId)] == true then acceptedCount += 1 end
			end
			if acceptedCount ~= 4 then return current end
			if typeof(current.routingOwner) == "string" and current.routingOwner ~= self.ownerToken and typeof(current.routingOwnerExpiresAt) == "number" and current.routingOwnerExpiresAt > now then
				return current
			end
			current.routingOwner = self.ownerToken
			current.routingOwnerExpiresAt = now + 10
			return current
		end, PROPOSAL_TTL)
	end)
	return ok and validProposal(updated) and updated.routingOwner == self.ownerToken and updated.route == nil
end

function GlobalMatchmakingService.publishRoute(self: any, proposalId: string, reservation: any): boolean
	if not self:isEnabled() then return false end
	if typeof(reservation) ~= "table" or typeof(reservation.matchId) ~= "string" or typeof(reservation.accessCode) ~= "string" or reservation.matchId == "" or reservation.accessCode == "" then return false end
	local updated: any = nil
	local ok = pcall(function()
		updated = proposalMap:UpdateAsync(proposalId, function(current: any)
			if not validProposal(current) or current.routingOwner ~= self.ownerToken or current.route ~= nil then return current end
			current.route = {
				matchId = reservation.matchId,
				accessCode = reservation.accessCode,
				privateServerId = if typeof(reservation.privateServerId) == "string" then reservation.privateServerId else "",
				createdAt = if typeof(reservation.createdAt) == "number" then reservation.createdAt else os.time(),
			}
			return current
		end, ROUTED_PROPOSAL_TTL)
		if validProposal(updated) and typeof(updated.route) == "table" and updated.route.matchId == reservation.matchId then
			for _, entry in updated.roster do
				playerStateMap:SetAsync("u_" .. tostring(entry.userId), {proposalId = proposalId}, ROUTED_PROPOSAL_TTL)
			end
		end
	end)
	return ok and validProposal(updated) and typeof(updated.route) == "table" and updated.route.matchId == reservation.matchId
end

function GlobalMatchmakingService.releaseRoutingClaim(self: any, proposalId: string)
	if not self:isEnabled() then return end
	pcall(function()
		proposalMap:UpdateAsync(proposalId, function(current: any)
			if not validProposal(current) then return current end
			if current.routingOwner == self.ownerToken and current.route == nil then
				current.routingOwner = nil
				current.routingOwnerExpiresAt = nil
			end
			return current
		end, PROPOSAL_TTL)
	end)
end

function GlobalMatchmakingService.markRouteFailed(self: any, proposalId: string, reason: string): boolean
	if not proposalStoreAvailable() then return false end
	if typeof(proposalId) ~= "string" or #proposalId < 8 or #proposalId > 80 then return false end
	if typeof(reason) ~= "string" then return false end
	local safeReason = string.sub(reason, 1, 180)
	local updated: any = nil
	local ok = pcall(function()
		updated = proposalMap:UpdateAsync(proposalId, function(current: any)
			if not validProposal(current) or current.route == nil then return current end
			current.routeFailed = if #safeReason > 0 then safeReason else "Teleport roster ke Match server gagal."
			return current
		end, ROUTED_PROPOSAL_TTL)
	end)
	return ok and validProposal(updated) and typeof(updated.routeFailed) == "string"
end

function GlobalMatchmakingService.resolveProposal(self: any, proposalId: string): (string, Proposal?)
	if not self:isEnabled() then return "disabled", nil end
	local ok, proposal = pcall(function()
		return proposalMap:GetAsync(proposalId)
	end)
	if not ok or not validProposal(proposal) then return "missing", nil end
	if proposal.declinedBy and proposal.declinedBy ~= 0 then return "declined", proposal end
	if typeof(proposal.routeFailed) == "string" and #proposal.routeFailed > 0 then return "route_failed", proposal end
	local acceptedCount = 0
	for _, entry in proposal.roster do
		if proposal.accepted[tostring(entry.userId)] == true then acceptedCount += 1 end
	end
	if acceptedCount == 4 then return "accepted", proposal end
	if os.time() > proposal.deadline then return "expired", proposal end
	return "pending", proposal
end

function GlobalMatchmakingService.clearProposal(self: any, proposal: Proposal)
	if not self:isEnabled() then return end
	pcall(function()
		proposalMap:RemoveAsync(proposal.id)
		for _, entry in proposal.roster do
			playerStateMap:RemoveAsync("u_" .. tostring(entry.userId))
		end
	end)
	self:invalidateQueueCache()
end

function GlobalMatchmakingService.requeue(self: any, proposal: Proposal, excludedUserId: number?, acceptedOnly: boolean)
	if not self:isEnabled() then return end
	local now = os.time()
	pcall(function()
		for _, entry in proposal.roster do
			local accepted = proposal.accepted[tostring(entry.userId)] == true
			if entry.userId ~= excludedUserId and (not acceptedOnly or accepted) then
				local restored: QueueEntry = {
					userId = entry.userId,
					name = entry.name,
					jobId = entry.jobId,
					joinedAt = math.min(entry.joinedAt, now),
				}
				queue:SetAsync("u_" .. tostring(entry.userId), restored, QUEUE_TTL, restored.joinedAt)
			end
			playerStateMap:RemoveAsync("u_" .. tostring(entry.userId))
		end
		proposalMap:RemoveAsync(proposal.id)
	end)
	self:invalidateQueueCache()
end

return GlobalMatchmakingService
