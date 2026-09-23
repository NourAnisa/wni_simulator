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
local THINK_MIN = 1.0
local THINK_MAX = 1.5

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

local function chooseBuildTarget(engine: any, seat: number, participant: any): number?
	local bestTile: number? = nil
	local bestCost = math.huge
	for tileIndex, ownerSeat in engine.owners do
		if ownerSeat == seat and engine.tiles[tileIndex].kind == "Property" then
			local cost = engine:upgradeCost(tileIndex)
			if cost and participant.cash - cost > CASH_RESERVE and cost < bestCost then
				bestCost = cost
				bestTile = tileIndex
			end
		end
	end
	return bestTile
end

function BotAIService.decide(self: any, engine: any): (string?, any?)
	local seat = engine.activeSeat
	local participant = engine.players[seat]
	if not participant or participant.isBot ~= true or participant.eliminated then return nil, nil end

	if engine.phase == "AwaitRoll" then
		if participant.inJail and participant.cash >= Rules.JailBailAmount then
			return "Bail", nil
		end
		return "Roll", nil
	elseif engine.phase == "AwaitBuy" then
		local tileIndex = participant.position
		local tariff = Tarif.get(tileIndex)
		if not participant.buyBanned and tariff and participant.cash - tariff.price > CASH_RESERVE then
			return "Buy", nil
		end
		return "Skip", nil
	elseif engine.phase == "AwaitBuild" then
		local target = chooseBuildTarget(engine, seat, participant)
		if target then return "Build", target end
		return "SkipBuild", nil
	elseif engine.phase == "AwaitCardChoice" then
		local pending = engine.pendingCardChoice
		if not pending or pending.seat ~= seat then return nil, nil end
		local choices = engine:cardLandChoices(seat, pending.id)
		if #choices > 0 then return "SelectCardLand", choices[1] end
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
