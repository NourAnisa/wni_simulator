--!strict
-- Resolver efek kartu: kartu menghasilkan aksi terstruktur, dieksekusi MatchEngine (README 6).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("WNI", 5)
local Rules = require(shared:WaitForChild("PrototypeRules", 5))
local CardData = require(shared:WaitForChild("CardData", 5))
export type CardEffect = {id: string, deck: string, name: string, status: string, note: string, dice: {number}, actions: {any}}
local CardEngine = {}
CardEngine.__index = CardEngine
function CardEngine.new()
	local self: any = setmetatable({}, CardEngine)
	self.fateDeck = {}
	self.disasterDeck = {}
	self.discard = {Fate = {}, Disaster = {}}
	self.random = Random.new()
	for _id, card in pairs(CardData.all()) do
		if card.deck == "Fate" then
			table.insert(self.fateDeck, card.id)
		else
			table.insert(self.disasterDeck, card.id)
		end
	end
	return self
end
function CardEngine.draw(self: any, deckName: string): string
	local deck = if deckName == "Fate" then self.fateDeck else self.disasterDeck
	if #deck == 0 then
		local pile = self.discard[deckName]
		while #pile > 0 do table.insert(deck, table.remove(pile)) end
		self.random:Shuffle(deck)
	end
	return table.remove(deck) or "KPK"
end
function CardEngine.discardCard(self: any, deckName: string, id: string)
	table.insert(self.discard[deckName], id)
end
function CardEngine.resolve(self: any, id: string, ctx: any): CardEffect
	local card = CardData.get(id)
	assert(card, "unknown card " .. tostring(id))
	local actions: {any} = {}
	local d: number = ctx.die or 0
	if id == "KPK" then
		if d >= 5 then
			table.insert(actions, {type = "pay", seat = ctx.seat, amount = 300000, to = nil, reason = "admin KPK"})
		elseif d >= 3 then
			table.insert(actions, {type = "suppressRent", seat = ctx.seat})
		else
			table.insert(actions, {type = "pay", seat = ctx.seat, amount = 500000, to = nil, reason = "denda KPK"})
			table.insert(actions, {type = "jail", seat = ctx.seat})
		end
	elseif id == "BateraiSekarat" then
		if d < 5 then
			local amount = if d >= 3 then 500000 else 1000000
			table.insert(actions, {type = "pay", seat = ctx.seat, amount = amount, to = nil, reason = "baterai (adaptasi dadu)"})
		end
	elseif id == "SubsidiBBM" then
		local own = if d >= 5 then 0 elseif d >= 3 then 400000 else 600000
		local others = if d >= 5 then 0 elseif d >= 3 then 200000 else 400000
		if own > 0 then table.insert(actions, {type = "pay", seat = ctx.seat, amount = own, to = nil, reason = "Subsidi BBM"}) end
		if others > 0 then
			for other = 1, #ctx.players do
				if other ~= ctx.seat and not ctx.players[other].eliminated then
					table.insert(actions, {type = "pay", seat = other, amount = others, to = nil, reason = "Subsidi BBM (pemain lain)"})
				end
			end
		end
	elseif id == "PengalihanIsu" then
		table.insert(actions, {type = "jail", seat = ctx.seat})
	elseif id == "Begal" then
		table.insert(actions, {type = "pay", seat = ctx.seat, amount = 400000, to = nil, reason = "korban begal"})
		table.insert(actions, {type = "skipTurn", seat = ctx.seat, turns = 1})
	elseif id == "MafiaTanah" then
		if ctx.freeLandIndex and not ctx.owners[ctx.freeLandIndex] then
			table.insert(actions, {type = "grantLand", seat = ctx.seat, tile = ctx.freeLandIndex})
		end
	elseif id == "WIBU" then
		if d % 2 == 0 then
			table.insert(actions, {type = "teleport", seat = ctx.seat, tile = 37})
		else
			table.insert(actions, {type = "pay", seat = ctx.seat, amount = 500000, to = nil, reason = "WIBU"})
			table.insert(actions, {type = "skipTurn", seat = ctx.seat, turns = 1})
		end
	elseif id == "Buzzer" then
		if d % 2 == 0 then
			table.insert(actions, {type = "credit", seat = ctx.seat, amount = 800000, reason = "Buzzer"})
		else
			table.insert(actions, {type = "pay", seat = ctx.seat, amount = 400000, to = nil, reason = "Buzzer ganjil (adaptasi)"})
		end
	elseif id == "BanjirBandang" then
		table.insert(actions, {type = "pay", seat = ctx.seat, amount = 400000, to = nil, reason = "banjir (adaptasi)"})
		table.insert(actions, {type = "toBekasi", seat = ctx.seat})
		table.insert(actions, {type = "skipTurn", seat = ctx.seat, turns = 1})
	elseif id == "Sandwich" then
		local young = ctx.youngestSeat or ctx.seat
		if d >= 5 then
			table.insert(actions, {type = "pay", seat = ctx.seat, amount = 200000, to = young, reason = "Sandwich"})
			local old = ctx.oldestSeat or ctx.seat
			if old ~= ctx.seat then
				table.insert(actions, {type = "pay", seat = old, amount = 200000, to = young, reason = "Sandwich (tertua)"})
			end
		elseif d >= 3 then
			table.insert(actions, {type = "pay", seat = ctx.seat, amount = 700000, to = young, reason = "Sandwich"})
		else
			table.insert(actions, {type = "giveLand", seat = ctx.seat, to = young, tile = ctx.mostExpensive or 0, fallback = 2000000})
		end
	elseif id == "Boomers" then
		local old = ctx.oldestSeat or ctx.seat
		if d >= 5 then
			table.insert(actions, {type = "globalBan", kind = "buy", reason = "Boomers"})
		elseif d >= 3 then
			table.insert(actions, {type = "pay", seat = ctx.seat, amount = 500000, to = old, reason = "Boomers"})
		else
			table.insert(actions, {type = "giveLand", seat = ctx.seat, to = old, tile = ctx.mostExpensive or 0, fallback = 3500000})
		end
	elseif id == "PHK" then
		if d >= 5 then
			table.insert(actions, {type = "globalBan", kind = "salary", reason = "PHK"})
		elseif d >= 3 then
			table.insert(actions, {type = "globalBan", kind = "buy", reason = "PHK"})
		else
			table.insert(actions, {type = "globalTeleport", tile = 25, reason = "PHK"})
		end
	elseif id == "TambangIlegal" then
		if d % 2 == 0 then
			if ctx.enemyLandIndex then table.insert(actions, {type = "returnLand", seat = ctx.seat, tile = ctx.enemyLandIndex}) end
		elseif ctx.mostExpensive then
			table.insert(actions, {type = "toToll", seat = ctx.seat, tile = ctx.mostExpensive})
		end
	elseif id == "PembebasanLahan" then
		if ctx.enemyLandIndex and ctx.owners[ctx.enemyLandIndex] and ctx.owners[ctx.enemyLandIndex] ~= ctx.seat then
			table.insert(actions, {type = "toToll", seat = ctx.seat, tile = ctx.enemyLandIndex})
		end
	elseif id == "TukarNasib" then
		local richest, poorest
		for candidate = 1, #ctx.players do
			local q = ctx.players[candidate]
			if not q.eliminated then
				if not richest or q.cash > ctx.players[richest].cash then richest = candidate end
				if not poorest or q.cash < ctx.players[poorest].cash then poorest = candidate end
			end
		end
		if richest and poorest and richest ~= poorest then
			table.insert(actions, {type = "swapCash", seat = richest, with = poorest})
		else
			table.insert(actions, {type = "noOp", reason = "Kas semua pemain sama; tidak ada pertukaran."})
		end
	elseif id == "Sengketa" then
		local target, bestValue = nil, -1
		for index, owner in ctx.owners do
			if owner ~= ctx.seat and ctx.players[owner].team ~= ctx.players[ctx.seat].team and not (ctx.tolls and ctx.tolls[index]) then
				local value = if ctx.assetInvestment then ctx.assetInvestment(index, ctx.buildings or {}) else ctx.tarif(index).price
				if value > bestValue then
					bestValue = value
					target = index
				end
			end
		end
		if target then
			table.insert(actions, {type = "seizeLand", seat = ctx.seat, tile = target})
		end
	elseif id == "KaburAjaDulu" or id == "OrangDalam" then
		-- Kartu tangan: tidak dieksekusi saat ditarik; masuk hand pemain.
		table.insert(actions, {type = "toHand", seat = ctx.seat, card = id})
	end
	return {id = id, deck = card.deck, name = card.name, status = card.status, note = card.note, dice = {d}, actions = actions}
end

return CardEngine
