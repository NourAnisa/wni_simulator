--!strict
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

export type QueueEntry = {
	userId: number,
	name: string,
	joinedAt: number,
}

local MatchmakingService = {}
MatchmakingService.__index = MatchmakingService

local function proposalContains(proposal: any, userId: number): boolean
	if not proposal then return false end
	for _, entry in proposal.roster do
		if entry.userId == userId then return true end
	end
	return false
end

function MatchmakingService.new(roomService: any, routeAccepted: (({QueueEntry}) -> (string, string?))?, botAI: any?)
	local self: any = setmetatable({}, MatchmakingService)
	self.rooms = roomService
	self.routeAccepted = routeAccepted
	self.botAI = botAI
	self.entries = {} :: {QueueEntry}
	self.queued = {} :: {[number]: QueueEntry}
	self.revision = 0
	self.proposal = nil
	self.acceptSeconds = 15
	return self
end

function MatchmakingService.isQueued(self: any, userId: number): boolean
	return self.queued[userId] ~= nil
end

function MatchmakingService.isPending(self: any, userId: number): boolean
	return proposalContains(self.proposal, userId)
end

function MatchmakingService.hasProposal(self: any): boolean
	return self.proposal ~= nil
end

function MatchmakingService.count(self: any): number
	return #self.entries
end

function MatchmakingService.join(self: any, player: Player, now: number): (boolean, string)
	if self.rooms.members[player.UserId] then return false, "Kamu sudah berada dalam room." end
	if self.rooms.code ~= nil or self.rooms:count() > 0 then return false, "Server ini sedang memiliki room aktif." end
	if proposalContains(self.proposal, player.UserId) then return false, "Kamu sedang mengonfirmasi match yang ditemukan." end
	if self.queued[player.UserId] then return false, "Kamu sudah berada dalam antrean." end
	local entry: QueueEntry = {
		userId = player.UserId,
		name = string.sub(player.DisplayName, 1, 64),
		joinedAt = now,
	}
	table.insert(self.entries, entry)
	self.queued[player.UserId] = entry
	self.revision += 1
	return true, "Masuk antrean matchmaking."
end

function MatchmakingService.leave(self: any, userId: number): (boolean, string)
	local entry = self.queued[userId]
	if not entry then return false, "Kamu tidak berada dalam antrean." end
	self.queued[userId] = nil
	for index, candidate in self.entries do
		if candidate.userId == userId then
			table.remove(self.entries, index)
			break
		end
	end
	self.revision += 1
	return true, "Keluar dari antrean matchmaking."
end

function MatchmakingService.removePlayer(self: any, userId: number): boolean
	if self.queued[userId] then
		self:leave(userId)
		return true
	end
	local proposal = self.proposal
	if not proposal or not proposalContains(proposal, userId) then return false end
	for _, entry in proposal.roster do
		if entry.userId ~= userId and Players:GetPlayerByUserId(entry.userId) and not self.queued[entry.userId] then
			local restored: QueueEntry = {userId = entry.userId, name = entry.name, joinedAt = entry.joinedAt}
			table.insert(self.entries, restored)
			self.queued[entry.userId] = restored
		end
	end
	self.proposal = nil
	self.revision += 1
	return true
end

function MatchmakingService.tryFormMatch(self: any, now: number): (boolean, string)
	if self.proposal ~= nil then return false, "" end
	if #self.entries < 4 then return false, "" end
	if self.rooms.code ~= nil or self.rooms:count() > 0 then return false, "Room aktif menghalangi matchmaking lokal." end

	local roster: {any} = {}
	for index = 1, 4 do
		local entry = self.entries[index]
		local player = Players:GetPlayerByUserId(entry.userId)
		if not player then
			self:removePlayer(entry.userId)
			return false, "Roster berubah karena pemain keluar."
		end
		roster[index] = {userId = entry.userId, name = entry.name, joinedAt = entry.joinedAt}
	end

	for index = 4, 1, -1 do
		local entry = self.entries[index]
		self.queued[entry.userId] = nil
		table.remove(self.entries, index)
	end
	self.proposal = {
		id = HttpService:GenerateGUID(false),
		roster = roster,
		accepted = {},
		deadline = now + self.acceptSeconds,
	}
	self.revision += 1
	return true, "Match ditemukan. Konfirmasi dalam 15 detik."
end

function MatchmakingService.respond(self: any, userId: number, accept: boolean, now: number): (boolean, string)
	local proposal = self.proposal
	if not proposal or not proposalContains(proposal, userId) then return false, "Tidak ada konfirmasi match aktif." end
	if now > proposal.deadline then
		return false, "Waktu konfirmasi match telah habis."
	end
	if accept then
		if proposal.accepted[userId] then return false, "Kamu sudah menerima match ini." end
		proposal.accepted[userId] = true
		self.revision += 1
		local acceptedCount = 0
		for _, entry in proposal.roster do
			if proposal.accepted[entry.userId] then acceptedCount += 1 end
		end
		if acceptedCount < 4 then
			return true, string.format("Match diterima (%d/4).", acceptedCount)
		end
		if self.routeAccepted then
			local routeResult, routeMessage = self.routeAccepted(proposal.roster)
			if routeResult == "routed" then
				self.proposal = nil
				self.revision += 1
				return true, routeMessage or "Semua pemain menerima. Memindahkan ke Match server..."
			elseif routeResult == "failed" then
				for _, entry in proposal.roster do
					if Players:GetPlayerByUserId(entry.userId) and not self.queued[entry.userId] then
						local restored: QueueEntry = {userId = entry.userId, name = entry.name, joinedAt = entry.joinedAt}
						table.insert(self.entries, restored)
						self.queued[entry.userId] = restored
					end
				end
				self.proposal = nil
				self.revision += 1
				return false, routeMessage or "Gagal memindahkan pemain ke Match server."
			end
		end
		local roster = {}
		for index, entry in proposal.roster do
			roster[index] = {userId = entry.userId, name = entry.name}
		end
		local ok, message = self.rooms:createMatchmadeRoster(roster)
		if not ok then
			for _, entry in proposal.roster do
				if Players:GetPlayerByUserId(entry.userId) and not self.queued[entry.userId] then
					local restored: QueueEntry = {userId = entry.userId, name = entry.name, joinedAt = entry.joinedAt}
					table.insert(self.entries, restored)
					self.queued[entry.userId] = restored
				end
			end
			self.proposal = nil
			self.revision += 1
			return false, message
		end
		self.proposal = nil
		self.revision += 1
		return true, "Semua pemain menerima. Masuk room persiapan."
	end

	for _, entry in proposal.roster do
		if entry.userId ~= userId and Players:GetPlayerByUserId(entry.userId) and not self.queued[entry.userId] then
			local restored: QueueEntry = {userId = entry.userId, name = entry.name, joinedAt = entry.joinedAt}
			table.insert(self.entries, restored)
			self.queued[entry.userId] = restored
		end
	end
	self.proposal = nil
	self.revision += 1
	return true, "Match ditolak. Pemain lain dikembalikan ke antrean."
end

function MatchmakingService.tick(self: any, now: number): boolean
	local proposal = self.proposal
	if proposal then
		if now <= proposal.deadline then return false end
		for _, entry in proposal.roster do
			if proposal.accepted[entry.userId] and Players:GetPlayerByUserId(entry.userId) and not self.queued[entry.userId] then
				local restored: QueueEntry = {userId = entry.userId, name = entry.name, joinedAt = entry.joinedAt}
				table.insert(self.entries, restored)
				self.queued[entry.userId] = restored
			end
		end
		self.proposal = nil
		self.revision += 1
		return true
	end

	if #self.entries == 1 and self.botAI then
		local entry = self.entries[1]
		if now - entry.joinedAt >= 15 then
			local player = Players:GetPlayerByUserId(entry.userId)
			if not player then
				self:removePlayer(entry.userId)
				return true
			end
			if self.rooms.code ~= nil or self.rooms:count() > 0 then return false end

			self.queued[entry.userId] = nil
			table.remove(self.entries, 1)
			self.revision += 1

			local created, createMessage = self.rooms:handle(entry.userId, entry.name, "CreateRoom", self.rooms.revision, nil, now)
			if not created then
				local restored: QueueEntry = {userId = entry.userId, name = entry.name, joinedAt = now}
				table.insert(self.entries, restored)
				self.queued[entry.userId] = restored
				self.revision += 1
				warn("[MatchmakingService] Auto-start bot gagal membuat room: " .. tostring(createMessage))
				return true
			end

			self.botAI:fillEmptySeats(self.rooms, now)
			self.botAI:readyWaitingBots(self.rooms, now)
			local engine = self.rooms.engine
			local readyOk, readyMessage = engine:handle(entry.userId, "Ready", engine.revision, now, nil)
			if not readyOk then
				engine:addLog("Auto-start solo gagal menyiapkan pemain: " .. tostring(readyMessage))
				engine.revision += 1
			else
				engine:addLog("Matchmaking solo: 15 detik tanpa lawan, 3 Bot AI ditambahkan otomatis.")
				engine.revision += 1
			end
			return true
		end
	end
	return false
end

function MatchmakingService.snapshot(self: any, userId: number): any
	local entry = self.queued[userId]
	local position = 0
	if entry then
		for index, candidate in self.entries do
			if candidate.userId == userId then
				position = index
				break
			end
		end
	end
	local proposal = self.proposal
	local inProposal = proposalContains(proposal, userId)
	local acceptedCount = 0
	local accepted = false
	local deadline = 0
	if proposal and inProposal then
		deadline = proposal.deadline
		accepted = proposal.accepted[userId] == true
		for _, candidate in proposal.roster do
			if proposal.accepted[candidate.userId] then acceptedCount += 1 end
		end
	end
	return {
		revision = self.revision,
		queued = entry ~= nil,
		position = position,
		count = #self.entries,
		needed = math.max(0, 4 - #self.entries),
		localServerOnly = true,
		matchFound = inProposal,
		accepted = accepted,
		acceptedCount = acceptedCount,
		deadline = deadline,
	}
end

return MatchmakingService
