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

local BotStrategyService = {}

local PERSONALITIES = {
	Aggressive = {
		label = "Agresif",
		baseReserve = 650000,
		threatWeight = 0.55,
		buyThreshold = 1.05,
		buildThreshold = 0.95,
		groupWeight = 1.35,
		blockWeight = 0.80,
		lateGameBonus = 0.45,
	},
	Balanced = {
		label = "Seimbang",
		baseReserve = 1250000,
		threatWeight = 0.80,
		buyThreshold = 1.20,
		buildThreshold = 1.10,
		groupWeight = 1.10,
		blockWeight = 0.65,
		lateGameBonus = 0.25,
	},
	Conservative = {
		label = "Hemat",
		baseReserve = 2100000,
		threatWeight = 1.10,
		buyThreshold = 1.38,
		buildThreshold = 1.28,
		groupWeight = 0.85,
		blockWeight = 0.45,
		lateGameBonus = 0.10,
	},
}

local NAME_PERSONALITY = {
	["Bot Budi"] = "Aggressive",
	["Bot Siti"] = "Conservative",
	["Bot Joko"] = "Balanced",
	["Bot Rina"] = "Aggressive",
	["Bot Agus"] = "Conservative",
	["Bot Dewi"] = "Balanced",
}

local function propertyBand(index: number)
	if index >= 2 and index <= 8 then return 2, 8 end
	if index >= 10 and index <= 16 then return 10, 16 end
	if index >= 18 and index <= 24 then return 18, 24 end
	if index >= 26 and index <= 32 then return 26, 32 end
	if index >= 34 and index <= 40 then return 34, 40 end
	return nil
end

function BotStrategyService.profileFor(participant: any): (string, any)
	local key = NAME_PERSONALITY[participant.name]
	if not key then
		local n = math.abs(tonumber(participant.userId) or 0) % 3
		key = if n == 0 then "Aggressive" elseif n == 1 then "Balanced" else "Conservative"
	end
	return key, PERSONALITIES[key]
end

local function enemyRentThreat(engine: any, seat: number): number
	local participant = engine.players[seat]
	local highest = 0
	local second = 0
	for tileIndex, ownerSeat in engine.owners do
		local owner = engine.players[ownerSeat]
		if owner and not owner.eliminated and owner.team ~= participant.team and not (engine.tolls and engine.tolls[tileIndex]) then
			local level = engine.buildings[tileIndex] or 0
			local rents = Tarif.get(tileIndex).rents
			local rent = rents[math.clamp(level + 1, 1, #rents)] or 0
			if rent > highest then
				second = highest
				highest = rent
			elseif rent > second then
				second = rent
			end
		end
	end
	return highest + math.floor(second * 0.35)
end

local function groupState(engine: any, seat: number, tileIndex: number): (number, number, number, number)
	local first, last = propertyBand(tileIndex)
	if not first or not last then return 0, 0, 0, 0 end
	local participant = engine.players[seat]
	local teamOwned, enemyOwned, free, total = 0, 0, 0, 0
	for index = first, last do
		if engine.tiles[index] and engine.tiles[index].kind == "Property" and not (engine.tolls and engine.tolls[index]) then
			total += 1
			local ownerSeat = engine.owners[index]
			if not ownerSeat then
				free += 1
			else
				local owner = engine.players[ownerSeat]
				if owner and owner.team == participant.team then teamOwned += 1 else enemyOwned += 1 end
			end
		end
	end
	return teamOwned, enemyOwned, free, total
end

function BotStrategyService.reserveFor(engine: any, seat: number): number
	local participant = engine.players[seat]
	local _, profile = BotStrategyService.profileFor(participant)
	local threat = enemyRentThreat(engine, seat)
	local reserve = profile.baseReserve + math.floor(threat * profile.threatWeight)
	if participant.inJail then reserve += math.floor((Rules.JailBailAmount or 0) * 0.5) end
	return reserve
end

function BotStrategyService.shouldBail(engine: any, seat: number): boolean
	local participant = engine.players[seat]
	if not participant.inJail or participant.cash < Rules.JailBailAmount then return false end
	local reserve = BotStrategyService.reserveFor(engine, seat)
	local after = participant.cash - Rules.JailBailAmount
	local key = BotStrategyService.profileFor(participant)
	if key == "Aggressive" then return after >= reserve * 0.65 end
	if key == "Balanced" then return participant.jailTries >= 1 and after >= reserve * 0.85 end
	return participant.jailTries >= 2 and after >= reserve
end

function BotStrategyService.shouldBuy(engine: any, seat: number, tileIndex: number): (boolean, any)
	local participant = engine.players[seat]
	local key, profile = BotStrategyService.profileFor(participant)
	local tariff = Tarif.get(tileIndex)
	local reserve = BotStrategyService.reserveFor(engine, seat)
	local cashAfter = participant.cash - tariff.price
	if participant.buyBanned or cashAfter < reserve then
		return false, {personality = key, score = -math.huge, reserve = reserve, cashAfter = cashAfter}
	end

	local teamOwned, enemyOwned, free, total = groupState(engine, seat, tileIndex)
	local ownAfter = teamOwned + 1
	local groupRatio = if total > 0 then ownAfter / total else 0
	local completesGroup = total > 0 and ownAfter == total
	local blocksEnemy = enemyOwned > 0 and free <= 1
	local rentEfficiency = (tariff.rents[1] or 0) / math.max(tariff.price, 1)
	local liquidity = cashAfter / math.max(participant.cash, 1)
	local roundRatio = math.clamp((engine.round or 0) / math.max(Rules.MaxRounds, 1), 0, 1)

	local score = 0.55
	score += math.clamp(rentEfficiency * 3.0, 0, 1.10)
	score += groupRatio * profile.groupWeight
	score += liquidity * 0.55
	if completesGroup then score += 0.85 end
	if blocksEnemy then score += profile.blockWeight end
	score += roundRatio * profile.lateGameBonus
	if tariff.verified == false then score -= 0.04 end

	return score >= profile.buyThreshold, {
		personality = key,
		score = score,
		reserve = reserve,
		cashAfter = cashAfter,
		groupRatio = groupRatio,
		completesGroup = completesGroup,
		blocksEnemy = blocksEnemy,
	}
end

function BotStrategyService.chooseBuildTarget(engine: any, seat: number): (number?, any?)
	local participant = engine.players[seat]
	local key, profile = BotStrategyService.profileFor(participant)
	local reserve = BotStrategyService.reserveFor(engine, seat)
	local bestTile: number? = nil
	local bestScore = -math.huge
	local bestInfo: any = nil

	for tileIndex, ownerSeat in engine.owners do
		if ownerSeat ~= seat or engine.tiles[tileIndex].kind ~= "Property" or (engine.tolls and engine.tolls[tileIndex]) then continue end
		local cost = engine:upgradeCost(tileIndex)
		if not cost then continue end
		local cashAfter = participant.cash - cost
		if cashAfter < reserve then continue end

		local tariff = Tarif.get(tileIndex)
		local level = engine.buildings[tileIndex] or 0
		local currentRent = tariff.rents[level + 1] or 0
		local nextRent = tariff.rents[math.min(level + 2, #tariff.rents)] or currentRent
		local gain = math.max(0, nextRent - currentRent)
		local efficiency = gain / math.max(cost, 1)
		local teamOwned, _, _, total = groupState(engine, seat, tileIndex)
		local groupRatio = if total > 0 then teamOwned / total else 0
		local liquidity = cashAfter / math.max(participant.cash, 1)
		local roundRatio = math.clamp((engine.round or 0) / math.max(Rules.MaxRounds, 1), 0, 1)

		local score = math.clamp(efficiency, 0, 3.0) * 0.65
		score += groupRatio * profile.groupWeight
		score += (level + 1) * 0.16
		score += liquidity * 0.35
		score += roundRatio * profile.lateGameBonus
		if tariff.verified == false then score -= 0.03 end

		if score > bestScore then
			bestScore = score
			bestTile = tileIndex
			bestInfo = {personality = key, score = score, reserve = reserve, cashAfter = cashAfter, level = level}
		end
	end

	if bestTile and bestScore >= profile.buildThreshold then return bestTile, bestInfo end
	return nil, {personality = key, score = bestScore, reserve = reserve}
end

function BotStrategyService.chooseCardTarget(engine: any, seat: number, cardId: string, choices: {number}): number?
	if #choices == 0 then return nil end
	local participant = engine.players[seat]
	local _, profile = BotStrategyService.profileFor(participant)
	local bestTile = choices[1]
	local bestScore = -math.huge
	for _, tileIndex in choices do
		local tariff = Tarif.get(tileIndex)
		local teamOwned, enemyOwned, _, total = groupState(engine, seat, tileIndex)
		local level = engine.buildings[tileIndex] or 0
		local score = tariff.price / 1000000
		if cardId == "MafiaTanah" then
			local ratio = if total > 0 then (teamOwned + 1) / total else 0
			score += ratio * profile.groupWeight * 2
			score += (tariff.rents[1] or 0) / 500000
		else
			local currentRent = tariff.rents[level + 1] or 0
			score += currentRent / 500000
			score += level * 1.2
			score += enemyOwned * 0.20
		end
		if score > bestScore then
			bestScore = score
			bestTile = tileIndex
		end
	end
	return bestTile
end

return table.freeze(BotStrategyService)
