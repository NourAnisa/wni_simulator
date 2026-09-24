--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("WNI", 5)
assert(shared, "WNI missing")
local rulesModule = shared:WaitForChild("PrototypeRules", 5)
assert(rulesModule and rulesModule:IsA("ModuleScript"), "PrototypeRules missing")
local Rules = require(rulesModule)
local tarifModule = shared:WaitForChild("TarifData", 5)
assert(tarifModule and tarifModule:IsA("ModuleScript"), "TarifData missing")
local Tarif = require(tarifModule)

export type Participant = {
	userId: number,
	name: string,
	team: string,
	cash: number,
	position: number,
	ready: boolean,
	eliminated: boolean,
	inJail: boolean,
	jailTries: number,
	jailRentToState: boolean,
	rentSuppressed: boolean,
	inBekasi: boolean,
	bekasiReturnPosition: number?,
}
export type Ownership = {[number]: number}
export type Buildings = {[number]: number}
export type PaymentResult = {paid: number, bankrupt: boolean, sold: {number}}
local Economy = {}

local function validAmount(value: number): boolean
	return value == value and value >= 0 and value <= 1000000000 and value % 1 == 0
end

function Economy.buy(participants: {Participant}, owners: Ownership, seat: number, tile: number): (boolean, string)
	local participant = participants[seat]
	if not participant or participant.eliminated then return false, "Pemain tidak aktif" end
	if tile % 1 ~= 0 or tile < 1 or tile > Rules.TileCount then return false, "Petak tidak sah" end
	if owners[tile] then return false, "Tanah sudah dimiliki" end
	local price = Tarif.get(tile).price
	if participant.cash < price then return false, "Uang tidak cukup" end
	participant.cash -= price
	owners[tile] = seat
	return true, "Pembelian berhasil"
end

local function buildingInvestment(tile: number, level: number): number
	if level <= 0 then return 0 end
	local tariff = Tarif.get(tile)
	local value = tariff.buildSubsidi
	if level >= 2 then value += tariff.buildSubsidi end
	if level >= 3 then value += tariff.buildOKB end
	return value
end

function Economy.assetInvestment(tile: number, buildings: Buildings): number
	local tariff = Tarif.get(tile)
	return tariff.price + buildingInvestment(tile, buildings[tile] or 0)
end

local function liquidationValue(tile: number, buildings: Buildings): number
	return math.floor(Economy.assetInvestment(tile, buildings) / 2)
end

function Economy.charge(participants: {Participant}, owners: Ownership, buildings: Buildings, seat: number, amount: number, recipientSeat: number?): PaymentResult
	assert(validAmount(amount), "Invalid server payment amount")
	local payer = participants[seat]
	assert(payer and not payer.eliminated, "Invalid payer")
	local receiver: Participant? = nil
	if recipientSeat then
		receiver = participants[recipientSeat]
		assert(receiver and not receiver.eliminated, "Invalid recipient")
	end
	if recipientSeat == seat then
		return {paid = 0, bankrupt = false, sold = {}}
	end
	local sold: {number} = {}
	-- Explicit prototype policy: liquidate in ascending tile order, only as needed.
	-- Land plus building investment is returned at 50% of total invested value.
	if payer.cash < amount then
		for tile = 1, Rules.TileCount do
			if owners[tile] == seat then
				payer.cash += liquidationValue(tile, buildings)
				owners[tile] = nil
				buildings[tile] = nil
				table.insert(sold, tile)
				if payer.cash >= amount then break end
			end
		end
	end
	local paid = math.min(payer.cash, amount)
	payer.cash -= paid
	if receiver then receiver.cash += paid end
	local bankrupt = paid < amount
	if bankrupt then
		payer.eliminated = true
		payer.inBekasi = false
		payer.bekasiReturnPosition = nil
		payer.inJail = false
		payer.jailTries = 0
		payer.jailRentToState = false
		payer.rentSuppressed = false
		for tile = 1, Rules.TileCount do
			if owners[tile] == seat then
				owners[tile] = nil
				buildings[tile] = nil
			end
		end
	end
	return {paid = paid, bankrupt = bankrupt, sold = sold}
end

function Economy.credit(participant: Participant, amount: number)
	assert(validAmount(amount), "Invalid server credit amount")
	assert(not participant.eliminated, "Cannot credit eliminated participant")
	participant.cash += amount
end

function Economy.teamScores(participants: {Participant}, owners: Ownership, buildings: Buildings): {[string]: number}
	local scores: {[string]: number} = {A = 0, B = 0}
	for seat, participant in participants do
		local value = participant.cash
		for tileIndex, owner in owners do
			if owner == seat then
				value += liquidationValue(tileIndex, buildings)
			end
		end
		scores[participant.team] = (scores[participant.team] or 0) + value
	end
	return scores
end

return table.freeze(Economy)
