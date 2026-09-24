--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("WNI", 5)
assert(shared, "WNI missing")
local rulesModule = shared:WaitForChild("PrototypeRules", 5)
local tarifModule = shared:WaitForChild("TarifData", 5)
assert(rulesModule and rulesModule:IsA("ModuleScript"), "PrototypeRules missing")
assert(tarifModule and tarifModule:IsA("ModuleScript"), "TarifData missing")

local Rules = require(rulesModule)
local Tarif = require(tarifModule)

local BotAIService = {}
BotAIService.__index = BotAIService

local BOT_NAMES = {"Bot Budi", "Bot Siti", "Bot Joko", "Bot Rina", "Bot Agus", "Bot Dewi"}
local BOT_ID_BASE = -910000
local CASH_RESERVE = 1000000
local THINK_MIN = 0.25
local THINK_MAX = 0.45

function BotAIService.new()
	local self: any = setmetatable({}, BotAIService)
	self.random = Random.new()
	self.pendingKey = nil
	self.executeAt = 0
	return self
end

function BotAIService.isBotParticipant(_self: any, participant: any): boolean
	return typeof(participant) == "table" and participant.isBot == true
end

function BotAIService.fillEmptySeats(self: any, rooms: any, now: number): boolean
	local engine = rooms.engine
	if engine.phase ~= "Waiting" then return false end
	local changed = false
	local ordinal = 1
	for _, participant in engine.players do
		if participant.isBot == true then ordinal += 1 end
	end
	while #engine.players < Rules.PlayerCount do
		local userId = BOT_ID_BASE - ordinal
		while engine:seatFor(userId) do
			ordinal += 1
			userId = BOT_ID_BASE - ordinal
		end
		local name = BOT_NAMES[((ordinal - 1) % #BOT_NAMES) + 1]
		if not engine:join(userId, name) then break end
		local seat = engine:seatFor(userId)
		if not seat then break end
		local participant = engine.players[seat]
		participant.isBot = true
		rooms.members[userId] = true
		changed = true
		ordinal += 1
	end
	if changed then
		rooms.revision += 1
		engine:addLog("Auto-Fill Bot mengisi kursi kosong. Bot bermain sepenuhnya di server.")
		self.pendingKey = nil
		self.executeAt = now
	end
	return changed
end

function BotAIService.readyWaitingBots(self: any, rooms: any, now: number): boolean
	local engine = rooms.engine
	if engine.phase ~= "Waiting" then return false end
	local changed = false
	for _, participant in engine.players do
		if participant.isBot == true and not participant.ready then
			local ok = engine:handle(participant.userId, "Ready", engine.revision, now, nil)
			if ok then changed = true end
			if engine.phase ~= "Waiting" then break end
		end
	end
	if changed then self.pendingKey = nil end
	return changed
end

type BotProfile = {
	reserve: number,
	riskTolerance: number,
	prefersBail: boolean,
	aggression: string,
}

local BOT_PROFILES: {[string]: BotProfile} = {
	["Bot Budi"] = {reserve = 500000, riskTolerance = 0.9, prefersBail = true, aggression = "Aggressive"},
	["Bot Agus"] = {reserve = 400000, riskTolerance = 0.85, prefersBail = true, aggression = "Aggressive"},
	["Bot Siti"] = {reserve = 1000000, riskTolerance = 0.6, prefersBail = true, aggression = "Balanced"},
	["Bot Rina"] = {reserve = 1200000, riskTolerance = 0.65, prefersBail = false, aggression = "Balanced"},
	["Bot Joko"] = {reserve = 2000000, riskTolerance = 0.35, prefersBail = false, aggression = "Conservative"},
	["Bot Dewi"] = {reserve = 2200000, riskTolerance = 0.3, prefersBail = false, aggression = "Conservative"},
}

local DEFAULT_PROFILE: BotProfile = {reserve = 1000000, riskTolerance = 0.5, prefersBail = true, aggression = "Balanced"}

local function getBotProfile(name: string): BotProfile
	return BOT_PROFILES[name] or DEFAULT_PROFILE
end

local function chooseBuildTarget(engine: any, seat: number, participant: any, profile: BotProfile): number?
	local bestTile: number? = nil
	local bestScore = -math.huge
	for tileIndex, ownerSeat in engine.owners do
		if ownerSeat == seat and engine.tiles[tileIndex].kind == "Property" then
			local level = (engine.buildings and engine.buildings[tileIndex]) or 0
			if level < 3 then
				local cost = engine:upgradeCost(tileIndex)
				if cost and (participant.cash - cost >= profile.reserve) then
					local tariff = Tarif.get(tileIndex)
					local nextRent = tariff.rents[level + 2] or 0
					local currRent = tariff.rents[level + 1] or 0
					local rentGain = nextRent - currRent
					local roiScore = (rentGain / math.max(cost, 1)) * 1000 + (level * 2)
					if roiScore > bestScore then
						bestScore = roiScore
						bestTile = tileIndex
					end
				end
			end
		end
	end
	return bestTile
end

local function chooseCardPlay(engine: any, seat: number, participant: any, profile: BotProfile): (string?, any?)
	local hand = participant.hand
	if typeof(hand) ~= "table" or #hand == 0 then return nil, nil end

	-- 1. OrangDalam: bot selalu menyiapkannya dengan dadu tertinggi (6) agar aman
	if table.find(hand, "OrangDalam") and not participant.insiderDie then
		return "PlayCard", {cardId = "OrangDalam", choice = 6}
	end

	-- 2. KaburAjaDulu: teleport taktis
	if table.find(hand, "KaburAjaDulu") then
		-- Jika kas kritis, teleport ke START (index 1) untuk ambil gaji
		if participant.cash < profile.reserve and participant.position ~= 1 then
			return "PlayCard", {cardId = "KaburAjaDulu", choice = 1}
		end

		-- Cari tanah kosong bernilai tinggi yang belum dibeli
		local bestUnowned: number? = nil
		local bestPrice = 0
		for index, tile in engine.tiles do
			if tile.kind == "Property" and (engine.owners[index] or 0) == 0 then
				local tariff = Tarif.get(index)
				if tariff and participant.cash - tariff.price >= profile.reserve and tariff.price > bestPrice then
					bestPrice = tariff.price
					bestUnowned = index
				end
			end
		end
		if bestUnowned then
			return "PlayCard", {cardId = "KaburAjaDulu", choice = bestUnowned}
		end
	end

	-- 3. DoaOrangTua: bot selalu memilih tier "high" (5-6) agar paling aman saat kena Musibah
	if table.find(hand, "DoaOrangTua") and not participant.doaTier then
		return "PlayCard", {cardId = "DoaOrangTua", choice = "high"}
	end

	return nil, nil
end

function BotAIService.decide(self: any, engine: any): (string?, any?)
	local seat = engine.activeSeat
	local participant = engine.players[seat]
	if not participant or participant.isBot ~= true or participant.eliminated then return nil, nil end

	local profile = getBotProfile(participant.name)

	if engine.phase == "AwaitRoll" then
		-- Pertimbangkan kartu simpanan terlebih dahulu
		local cardAction, cardPayload = chooseCardPlay(engine, seat, participant, profile)
		if cardAction then
			return cardAction, cardPayload
		end

		if participant.inJail then
			local canPay = participant.cash >= Rules.JailBailAmount + (if profile.prefersBail then 200000 else profile.reserve)
			if canPay then
				return "Bail", nil
			end
		end
		return "Roll", nil
	elseif engine.phase == "AwaitBuy" then
		local tileIndex = participant.position
		local tariff = Tarif.get(tileIndex)
		if not participant.buyBanned and tariff then
			local buffer = if profile.aggression == "Aggressive" then 200000 else profile.reserve
			if participant.cash - tariff.price >= buffer then
				return "Buy", nil
			end
		end
		return "Skip", nil
	elseif engine.phase == "AwaitBuild" then
		local target = chooseBuildTarget(engine, seat, participant, profile)
		if target then return "Build", target end
		return "SkipBuild", nil
	elseif engine.phase == "AwaitCardChoice" then
		local pending = engine.pendingCardChoice
		if not pending or pending.seat ~= seat then return nil, nil end
		local choices = engine:cardLandChoices(seat, pending.id)
		if #choices > 0 then
			-- Pilih petak lawan dengan level tertinggi untuk efek musibah/hancurkan
			local bestChoice = choices[1]
			local highestLevel = -1
			for _, choiceIndex in choices do
				local lvl = (engine.buildings and engine.buildings[choiceIndex]) or 0
				if lvl > highestLevel then
					highestLevel = lvl
					bestChoice = choiceIndex
				end
			end
			return "SelectCardLand", bestChoice
		end
		if pending.id == "PembebasanLahan" then return "SkipCardChoice", nil end
	end
	return nil, nil
end

function BotAIService.tick(self: any, rooms: any, now: number): boolean
	local engine = rooms.engine
	if engine.phase == "Waiting" or engine.phase == "Finished" or engine.phase == "Cancelled" then
		self.pendingKey = nil
		return false
	end
	local participant = engine.players[engine.activeSeat]
	if not participant or participant.isBot ~= true or participant.eliminated then
		self.pendingKey = nil
		return false
	end
	local action, target = self:decide(engine)
	if not action then
		self.pendingKey = nil
		return false
	end
	local key = table.concat({tostring(engine.matchId), tostring(engine.revision), tostring(engine.activeSeat), engine.phase, action}, "|")
	if self.pendingKey ~= key then
		self.pendingKey = key
		self.executeAt = now + self.random:NextNumber(THINK_MIN, THINK_MAX)
		return false
	end
	if now < self.executeAt then return false end

	self.pendingKey = nil
	local ok, message = engine:handle(participant.userId, action, engine.revision, now, target)
	if not ok then
		engine:addLog(participant.name .. " gagal memilih aksi AI: " .. tostring(message))
		engine.revision += 1
		return true
	end
	return true
end

return BotAIService
