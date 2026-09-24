--!strict
local HttpService = game:GetService("HttpService")
local RoomService = {}
RoomService.__index = RoomService

function RoomService.new(engineFactory: () -> any)
	local self: any = setmetatable({}, RoomService)
	self.factory = engineFactory
	self.engine = engineFactory()
	self.code = nil
	self.leaderId = nil
	self.members = {} :: {[number]: boolean}
	self.revision = 0
	self.joinAttempts = {} :: {[number]: {count: number, started: number}}
	self.disconnected = {} :: {[number]: number}
	self.pauseStarted = nil
	return self
end

function RoomService.count(self: any): number
	local count = 0
	for _ in self.members do count += 1 end
	return count
end

function RoomService.closeIfEmpty(self: any)
	if self:count() > 0 then return end
	local previousRevision = self.engine.revision
	self.engine = self.factory()
	self.engine.revision = previousRevision + 1
	self.code = nil
	self.leaderId = nil
end

function RoomService.depart(self: any, userId: number): boolean
	self.joinAttempts[userId] = nil
	self.disconnected[userId] = nil
	if not self.members[userId] then return false end
	self.engine:leave(userId)
	self.members[userId] = nil
	if self.leaderId == userId then
		self.leaderId = nil
		for _, participant in self.engine.players do
			if self.members[participant.userId] then
				self.leaderId = participant.userId
				break
			end
		end
	end
	self:closeIfEmpty()
	self.revision += 1
	return true
end

function RoomService.markDisconnected(self: any, userId: number, now: number, graceSeconds: number): (boolean, boolean)
	if not self.members[userId] then return false, false end
	local phase = self.engine.phase
	local active = phase ~= "Waiting" and phase ~= "Finished" and phase ~= "Cancelled"
	if not active then
		return self:depart(userId), false
	end
	if self.disconnected[userId] then return false, true end
	if next(self.disconnected) == nil then self.pauseStarted = now end
	self.disconnected[userId] = now + graceSeconds
	self.engine.revision += 1
	self.revision += 1
	local seat = self.engine:seatFor(userId)
	local participant = if seat then self.engine.players[seat] else nil
	if participant then self.engine:addLog(participant.name .. " terputus; menunggu reconnect.") end
	return true, true
end

function RoomService.reconnect(self: any, userId: number, now: number): boolean
	if not self.members[userId] or not self.disconnected[userId] then return false end
	local phase = self.engine.phase
	if phase == "Waiting" or phase == "Finished" or phase == "Cancelled" then return false end
	local userExpiry = self.disconnected[userId]
	if not userExpiry or now >= userExpiry then return false end
	self.disconnected[userId] = nil
	self.engine.revision += 1
	if next(self.disconnected) == nil and self.pauseStarted then
		if self.engine.deadline and self.engine.deadline > 0 then
			self.engine.deadline += math.max(0, now - self.pauseStarted)
		end
		self.pauseStarted = nil
	end
	self.revision += 1
	local seat = self.engine:seatFor(userId)
	local participant = if seat then self.engine.players[seat] else nil
	if participant then self.engine:addLog(participant.name .. " tersambung kembali.") end
	return true
end

function RoomService.hasReconnectGrace(self: any): boolean
	return next(self.disconnected) ~= nil
end

function RoomService.expireReconnects(self: any, now: number): (boolean, {number})
	local expired: {number} = {}
	for userId, expiresAt in self.disconnected do
		if now >= expiresAt then table.insert(expired, userId) end
	end
	if #expired == 0 then return false, expired end
	for _, userId in expired do
		self.disconnected[userId] = nil
		if self.members[userId] then self:depart(userId) end
	end
	if next(self.disconnected) == nil then self.pauseStarted = nil end
	return true, expired
end

function RoomService.createMatchmadeRoster(self: any, roster: {any}): (boolean, string)
	if self.code or self:count() > 0 or self.engine.phase ~= "Waiting" or #self.engine.players > 0 then
		return false, "Server ini sedang memiliki room aktif."
	end
	if #roster ~= 4 then return false, "Matchmaking memerlukan tepat empat pemain." end
	local seen: {[number]: boolean} = {}
	for _, entry in roster do
		if typeof(entry.userId) ~= "number" or entry.userId <= 0 or entry.userId % 1 ~= 0 or seen[entry.userId] then
			return false, "Roster matchmaking tidak valid."
		end
		if typeof(entry.name) ~= "string" or entry.name == "" or #entry.name > 64 then
			return false, "Nama pemain matchmaking tidak valid."
		end
		seen[entry.userId] = true
	end

	for _, entry in roster do
		if not self.engine:join(entry.userId, entry.name) then
			self.engine = self.factory()
			self.members = {}
			self.code = nil
			self.leaderId = nil
			self.revision += 1
			return false, "Gagal membentuk roster matchmaking."
		end
		self.members[entry.userId] = true
	end
	self.code = string.upper(string.sub(HttpService:GenerateGUID(false), 1, 6))
	self.leaderId = roster[1].userId
	self.revision += 1
	return true, ""
end

function RoomService.handle(self: any, userId: number, name: string, action: string, expectedRevision: number, code: any, now: number): (boolean, string)
	if expectedRevision ~= self.revision then return false, "Room berubah; coba kembali." end
	if action == "CreateRoom" then
		if self.code then return false, "Server ini sudah memiliki room. Gunakan kode dari teman." end
		if not self.engine:join(userId, name) then return false, "Room belum dapat dibuat." end
		self.code = string.upper(string.sub(HttpService:GenerateGUID(false), 1, 6))
		self.members[userId] = true
		self.leaderId = userId
	elseif action == "JoinRoom" then
		if self.members[userId] then return false, "Kamu sudah berada dalam room." end
		local attempts = self.joinAttempts[userId]
		if not attempts or now - attempts.started >= 30 then
			attempts = {count = 0, started = now}
			self.joinAttempts[userId] = attempts
		end
		if attempts.count >= 5 then return false, "Terlalu banyak percobaan kode. Tunggu 30 detik." end
		attempts.count += 1
		if typeof(code) ~= "string" or #code ~= 6 or not string.match(code, "^%x%x%x%x%x%x$") then
			return false, "Kode harus berisi 6 karakter sesuai kode room teman."
		end
		if not self.code or string.upper(code) ~= self.code then return false, "Kode room tidak ditemukan di server ini." end
		if self.engine.phase ~= "Waiting" then return false, "Pertandingan sudah dimulai atau berakhir." end
		if self:count() >= 4 then return false, "Room sudah penuh." end
		if not self.engine:join(userId, name) then return false, "Tidak dapat bergabung." end
		self.members[userId] = true
		self.joinAttempts[userId] = nil
	elseif action == "LeaveRoom" then
		if not self.members[userId] then return false, "Kamu tidak berada dalam room." end
		local phase = self.engine.phase
		if phase ~= "Waiting" and phase ~= "Finished" and phase ~= "Cancelled" then
			return false, "Keluar room tersedia saat persiapan atau setelah pertandingan berakhir."
		end
		self:depart(userId)
		return true, ""
	else
		return false, "Aksi room tidak dikenal."
	end
	self.revision += 1
	return true, ""
end

function RoomService.snapshot(self: any, userId: number)
	local snapshot = self.engine:snapshot()
	local member = self.members[userId] == true
	if member then
		-- Retained cards are private; disclose only the viewer's hand.
		for _, participant in snapshot.players do
			local hand = participant.hand or {}
			participant.handCount = #hand
			participant.hand = if participant.userId == userId then table.clone(hand) else {}
		end
	else
		snapshot.players = {}
		snapshot.owners = {}
		snapshot.buildings = {}
		snapshot.tolls = {}
		snapshot.tolls = {}
		snapshot.logs = {}
		snapshot.result = ""
		snapshot.phase = "Waiting"
		snapshot.activeSeat = 0
		snapshot.round = 0
		snapshot.deadline = 0
		snapshot.dice = {0, 0}
		snapshot.matchId = ""
		snapshot.rematchVotes = {false, false, false, false}
		snapshot.rematchUnavailable = true
		snapshot.cardChoice = nil
		snapshot.teamSwap = nil
	end
	for _, participant in snapshot.players do
		local reconnectUntil = self.disconnected[participant.userId]
		participant.connected = reconnectUntil == nil
		participant.reconnectUntil = reconnectUntil or 0
	end
	snapshot.room = {
		revision = self.revision,
		exists = self.code ~= nil,
		member = member,
		code = if member then self.code else nil,
		leaderId = if member then self.leaderId else nil,
		count = self:count(),
		capacity = 4,
		phase = self.engine.phase,
		localServerOnly = true,
		pausedForReconnect = self:hasReconnectGrace(),
	}

	return snapshot
end

return RoomService
