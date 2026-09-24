--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local shared = ReplicatedStorage:WaitForChild("WNI", 5)
assert(shared, "WNI missing")
local rulesModule = shared:WaitForChild("PrototypeRules", 5)
local economyModule = script.Parent:WaitForChild("EconomyService", 5)
assert(rulesModule and rulesModule:IsA("ModuleScript"), "Rules missing")
assert(economyModule and economyModule:IsA("ModuleScript"), "Economy missing")
local Rules = require(rulesModule)
local Economy = require(economyModule)
local tarifModule = shared:WaitForChild("TarifData", 5)
assert(tarifModule and tarifModule:IsA("ModuleScript"), "TarifData missing")
local Tarif = require(tarifModule)
local roleConfigModule = shared:WaitForChild("RoleConfig", 5)
local RoleConfig = if roleConfigModule and roleConfigModule:IsA("ModuleScript") then require(roleConfigModule) else nil
local stockMarketModule = shared:WaitForChild("StockMarketConfig", 5)
local StockMarket = if stockMarketModule and stockMarketModule:IsA("ModuleScript") then require(stockMarketModule) else nil
type Participant = Economy.Participant
export type Tile = {name: string, kind: string}

local ISLAND_TILES: {[string]: {number}} = {
	SUMATERA = {2, 3, 5, 6, 8},
	KALIMANTAN = {10, 11, 13, 14, 16},
	SULAWESI = {18, 19, 21, 22, 24},
	PAPUA = {26, 27, 29, 30, 32},
	JAWA = {34, 35, 37, 38, 40},
}

local ISLAND_NAMES: {[string]: string} = {
	SUMATERA = "Sumatera",
	KALIMANTAN = "Kalimantan",
	SULAWESI = "Sulawesi",
	PAPUA = "Papua",
	JAWA = "Jawa",
}

local Engine = {}
Engine.__index = Engine

function Engine.isTileMonopolized(self: any, tileIndex: number): (boolean, string?)
	local owner = self.owners[tileIndex]
	if not owner or not self.players[owner] then return false, nil end
	local team = self.players[owner].team
	for islandKey, tileList in pairs(ISLAND_TILES) do
		if table.find(tileList, tileIndex) then
			for _, idx in ipairs(tileList) do
				local o = self.owners[idx]
				if not o or not self.players[o] or self.players[o].team ~= team then
					return false, nil
				end
			end
			return true, ISLAND_NAMES[islandKey] or islandKey
		end
	end
	return false, nil
end

function Engine.getIslandMonopolies(self: any): {[string]: {string}}
	local res: {[string]: {string}} = {A = {}, B = {}}
	for _, team in ipairs({"A", "B"}) do
		for islandKey, tileList in pairs(ISLAND_TILES) do
			local ownedAll = true
			for _, idx in ipairs(tileList) do
				local o = self.owners[idx]
				if not o or not self.players[o] or self.players[o].team ~= team then
					ownedAll = false
					break
				end
			end
			if ownedAll then
				table.insert(res[team], islandKey)
			end
		end
	end
	return res
end

function Engine.new(tiles: {Tile})
	assert(#tiles == Rules.TileCount, "Expected complete prototype board")
	local self: any = setmetatable({}, Engine)
	self.tiles = tiles
	self.players = {} :: {Participant}
	self.owners = {} :: {[number]: number}
	self.phase = "Waiting"
	self.revision = 0
	self.activeSeat = 0
	self.round = 0
	self.deadline = 0
	self.dice = {0, 0}
	self.buildings = {} :: {[number]: number}
	self.logs = {} :: {string}
	self.result = ""
	self.random = Random.new()
	self.matchId = HttpService:GenerateGUID(false)
	self.rematchVotes = {false, false, false, false}
	self.rematchUnavailable = false
	self.buyBanReleaseSeat = nil
	self.activeEvent = nil
	self.gameMode = "Team2v2"
	self.activeHazards = {} :: {[number]: {kind: string, name: string, roundsLeft: number}}
	self.stockPrices = {BBUMN = 500000, KRIPTO = 250000}
	self.stockNews = "Bursa Efek Nusantara: Pasar dibuka dengan optimisme tinggi."
	self:addLog("Mode prototipe: 4 pemain, tim 2v2, batas 8 ronde.")
	return self
end

function Engine.addLog(self: any, message: string)
	table.insert(self.logs, 1, message)
	while #self.logs > 8 do table.remove(self.logs) end
end

function Engine.seatFor(self: any, userId: number): number?
	for seat, participant in self.players do
		if participant.userId == userId then return seat end
	end
	return nil
end

function Engine.join(self: any, userId: number, name: string): boolean
	if self.phase ~= "Waiting" or #self.players >= Rules.PlayerCount or self:seatFor(userId) then return false end
	self.teamSwap = nil
	local counts = {A = 0, B = 0}
	for _, member in self.players do counts[member.team] += 1 end
	local assignedTeam = if counts.A <= counts.B then "A" else "B"
	local assignedRole = if RoleConfig then RoleConfig.assignRole(#self.players + 1) else "PNS"
	table.insert(self.players, {
		userId = userId, name = name, team = assignedTeam,
		cash = Rules.StartingCash, position = 1, ready = false, eliminated = false,
		inJail = false, jailTries = 0, jailRentToState = false, rentSuppressed = false,
		inBekasi = false, bekasiReturnPosition = nil,
		hand = {}, extraTurn = false, doaTier = nil,
		role = assignedRole,
		portfolio = {BBUMN = 0, KRIPTO = 0},
		isBot = (userId < 0),
	})
	for _, participant in self.players do
		participant.ready = false
	end
	self.revision += 1
	self:addLog(name .. " (" .. assignedRole .. ") bergabung. Semua peserta perlu menyatakan siap.")
	return true
end

function Engine.leave(self: any, userId: number): boolean
	local seat = self:seatFor(userId)
	if not seat then return false end
	if self.phase == "Waiting" then
		self.teamSwap = nil
		table.remove(self.players, seat)
		for _, participant in self.players do
			participant.ready = false
		end
	elseif self.phase == "Finished" then
		self.rematchUnavailable = true
		self.rematchVotes = {false, false, false, false}
		self:addLog("Peserta keluar; main ulang dengan roster yang sama tidak tersedia.")
	elseif self.phase ~= "Cancelled" then
		self.phase = "Cancelled"
		self.deadline = 0
		self.result = "Sesi dibatalkan: peserta terputus. Tidak ada hasil akun yang disimpan."
		self:addLog(self.result)
	else
		return false
	end
	self.revision += 1
	return true
end

function Engine.checkEnd(self: any): boolean
	if self.gameMode == "SoloFFA" then
		local aliveCount = 0
		local lastStanding = nil
		for _, participant in self.players do
			if not participant.eliminated then
				aliveCount += 1
				lastStanding = participant
			end
		end
		if aliveCount <= 1 then
			self.phase = "Finished"
			self.deadline = 0
			self.result = if lastStanding then "👑 SULTAN TUNGGAL MENANG: " .. lastStanding.name .. "!" else "SEMUA PEMAIN TELAH BANGKRUT"
			self:addLog(self.result)
			return true
		end
		return false
	end
	local alive = {A = false, B = false}
	for _, participant in self.players do
		if not participant.eliminated then alive[participant.team] = true end
	end
	if alive.A and alive.B then return false end
	self.phase = "Finished"
	self.deadline = 0
	self.result = if alive.A then "TIM A MENANG" elseif alive.B then "TIM B MENANG" else "HASIL SERI"
	self:addLog(self.result)
	return true
end

function Engine.processRoundEvent(self: any, now: number)
	if self.round == 3 then
		self.activeEvent = {
			id = "MusimMudik",
			name = "MUSIM MUDIK LEBARAN",
			desc = "Sewa jalur Transportasi naik 2X lipat selama putaran ini!",
			icon = "🚗",
			round = 3,
		}
		self:addLog("📢 EVENT NASIONAL: MUSIM MUDIK! Sewa seluruh jalur transportasi naik 2X lipat!")
	elseif self.round == 5 then
		local lowestSeat = nil
		local lowestCash = math.huge
		for seat, p in self.players do
			if not p.eliminated and p.cash < lowestCash then
				lowestCash = p.cash
				lowestSeat = seat
			end
		end
		self.activeEvent = {
			id = "BansosNasional",
			name = "BANSOS SEMBAKO CAIR",
			desc = "Suntikan dana Rp 2.500.000 untuk warga paling membutuhkan!",
			icon = "🍚",
			round = 5,
		}
		if lowestSeat then
			local luckyP = self.players[lowestSeat]
			local amount = 2500000
			Economy.credit(luckyP, amount)
			self:addLog("📢 EVENT NASIONAL: BANSOS CAIR! " .. luckyP.name .. " menerima " .. Rules.formatMoney(amount) .. " dari kas negara!")
		else
			self:addLog("📢 EVENT NASIONAL: BANSOS SEMBAKO CAIR!")
		end
	elseif self.round == 7 then
		local highestSeat = nil
		local highestCash = -1
		for seat, p in self.players do
			if not p.eliminated and p.cash > highestCash then
				highestCash = p.cash
				highestSeat = seat
			end
		end
		self.activeEvent = {
			id = "AuditPajak",
			name = "AUDIT PAJAK & OTT",
			desc = "Pemeriksaan aset konglomerat terkaya!",
			icon = "📑",
			round = 7,
		}
		if highestSeat and highestCash > 2000000 then
			local richP = self.players[highestSeat]
			local tax = math.floor(highestCash * 0.1)
			self:pay(highestSeat, tax, nil, "pajak darurat kekayaan ronde 7")
			self:addLog("📢 EVENT NASIONAL: OTT & AUDIT PAJAK! " .. richP.name .. " menyetorkan " .. Rules.formatMoney(tax) .. " pajak kekayaan!")
		else
			self:addLog("📢 EVENT NASIONAL: AUDIT PAJAK! Seluruh warga tertib membayar pajak.")
		end
	else
		if self.activeEvent then
			self:addLog("Event nasional " .. self.activeEvent.name .. " telah selesai.")
			self.activeEvent = nil
		end
	end
end

function Engine.processHazards(self: any, now: number)
	-- Kurangi durasi hazard yang ada
	for tileIndex, h in pairs(self.activeHazards) do
		h.roundsLeft -= 1
		if h.roundsLeft <= 0 then
			self.activeHazards[tileIndex] = nil
			self:addLog("Cuaca kembali normal di " .. self.tiles[tileIndex].name .. ".")
		end
	end

	-- Munculkan Hazard baru di Ronde 2, 4, 6
	if self.round == 2 or self.round == 4 or self.round == 6 then
		local candidates = {}
		for idx = 1, Rules.TileCount do
			if self.tiles[idx].kind == "Property" and not self.activeHazards[idx] then
				table.insert(candidates, idx)
			end
		end
		if #candidates > 0 then
			local target = candidates[self.random:NextInteger(1, #candidates)]
			local isBanjir = (self.random:NextInteger(1, 2) == 1)
			local hKind = if isBanjir then "Banjir" else "Macet"
			local hName = if isBanjir then "Banjir Musiman 🌊" else "Macet Horor Pantura 🚗"
			self.activeHazards[target] = {
				kind = hKind,
				name = hName,
				roundsLeft = 2,
			}
			self:addLog("📢 PERINGATAN BENCANA: " .. hName .. " melanda " .. self.tiles[target].name .. " selama 2 ronde!")
		end
	end
end

function Engine.processStockMarket(self: any, now: number)
	if not StockMarket then return end
	local bumnPrice = self.stockPrices.BBUMN or 500000
	-- 1. Pembagian dividen BBUMN untuk semua pemegang saham
	for _, p in ipairs(self.players) do
		if not p.eliminated and p.portfolio and p.portfolio.BBUMN and p.portfolio.BBUMN > 0 then
			local dividend = math.floor(p.portfolio.BBUMN * bumnPrice * 0.08)
			if dividend > 0 then
				Economy.credit(p, dividend)
				self:addLog("💰 DIVIDEN BUMN: " .. p.name .. " menerima dividen " .. Rules.formatMoney(dividend) .. " (" .. p.portfolio.BBUMN .. " lot)!")
			end
		end
	end

	-- 2. Fluktuasi harga bursa yang lebih stabil dan terkendali
	local bumnDelta = (self.random:NextInteger(-10, 15)) / 100
	local kriptoDelta = (self.random:NextInteger(-25, 35)) / 100

	local newBumn = math.clamp(math.floor(bumnPrice * (1 + bumnDelta)), 250000, 1200000)
	local oldKripto = self.stockPrices.KRIPTO or 250000
	local newKripto = math.clamp(math.floor(oldKripto * (1 + kriptoDelta)), 50000, 2000000)

	self.stockPrices.BBUMN = newBumn
	self.stockPrices.KRIPTO = newKripto

	local bumnTrend = if bumnDelta >= 0 then "+" .. tostring(math.floor(bumnDelta * 100)) .. "%" else tostring(math.floor(bumnDelta * 100)) .. "%"
	local kriptoTrend = if kriptoDelta >= 0 then "+" .. tostring(math.floor(kriptoDelta * 100)) .. "%" else tostring(math.floor(kriptoDelta * 100)) .. "%"

	self.stockNews = string.format("Bursa Saham R%d: BBUMN %s (%s) | GAJAH %s (%s)", 
		self.round, Rules.formatMoney(newBumn), bumnTrend, Rules.formatMoney(newKripto), kriptoTrend)
	self:addLog("📈 " .. self.stockNews)
end

function Engine.advance(self: any, now: number)
	if self:checkEnd() then return end
	-- Cek apakah pemain aktif mendapat giliran ekstra (dari dadu kembar)
	local currentP = self.players[self.activeSeat]
	if currentP and currentP.extraTurn and not currentP.eliminated then
		currentP.extraTurn = false
		self.phase = "AwaitRoll"
		self.deadline = now + Rules.DecisionSeconds
		self:addLog(currentP.name .. " bermain lagi karena dadu kembar! 🎲")
		return
	end

	local maxIterations = Rules.PlayerCount * (Rules.MaxRounds + 2)
	local iterations = 0
	while iterations < maxIterations do
		iterations += 1
		self.activeSeat += 1
		if self.activeSeat > Rules.PlayerCount then
			self.activeSeat = 1
			self.round += 1
			self:processRoundEvent(now)
			self:processHazards(now)
			self:processStockMarket(now)
			if self.round > Rules.MaxRounds then
				self.round = Rules.MaxRounds
				if self.gameMode == "SoloFFA" then
					local ranked = {}
					for seat, p in ipairs(self.players) do
						local netWorth = p.cash
						for tIdx, o in pairs(self.owners) do
							if o == seat then netWorth += Tarif.get(tIdx).liquidationValue end
						end
						if p.portfolio then
							for sId, shares in pairs(p.portfolio) do
								netWorth += shares * (self.stockPrices[sId] or 0)
							end
						end
						table.insert(ranked, {name = p.name, score = netWorth})
					end
					table.sort(ranked, function(a, b) return a.score > b.score end)
					self.result = string.format("👑 SULTAN MENANG: %s (%s)!", ranked[1].name, Rules.formatMoney(ranked[1].score))
				else
					local scores = Economy.teamScores(self.players, self.owners, self.buildings)
					self.result = if scores.A > scores.B then "TIM A MENANG" elseif scores.B > scores.A then "TIM B MENANG" else "HASIL SERI"
					self.result ..= " | A " .. Rules.formatMoney(scores.A) .. " | B " .. Rules.formatMoney(scores.B)
				end
				self.phase = "Finished"
				self.deadline = 0
				self:addLog(self.result)
				return
			end
		end
		if self.buyBanReleaseSeat and self.activeSeat == self.buyBanReleaseSeat then
			for _, q in self.players do q.buyBanned = false end
			self.buyBanReleaseSeat = nil
			self:addLog("Larangan pembelian satu putaran telah berakhir.")
		end
		local p = self.players[self.activeSeat]
		if not p.eliminated then
			if (p.skipTurns or 0) > 0 then
				p.skipTurns -= 1
				self:addLog(p.name .. " melewatkan giliran ini (" .. tostring(p.skipTurns) .. " lagi).")
				-- Iterasi berlanjut ke kursi berikutnya tanpa rekursi (mencegah stack overflow)
			else
				if p.inBekasi then
					local returnPosition = p.bekasiReturnPosition
					if typeof(returnPosition) == "number" and returnPosition % 1 == 0 and returnPosition >= 1 and returnPosition <= Rules.TileCount then
						p.position = returnPosition
					end
					p.inBekasi = false
					p.bekasiReturnPosition = nil
					self:addLog(p.name .. " kembali dari Bekasi ke " .. self.tiles[p.position].name .. " setelah melewati satu giliran (adaptasi kepulangan; aturan asli belum terverifikasi).")
				end
				if p.rentSuppressed then
					p.rentSuppressed = false
					self:addLog("Sewa tanah " .. p.name .. " aktif kembali.")
				end
				if p.inJail then
					p.jailTries += 1
					if p.jailTries >= 3 then
						p.inJail = false
						p.jailTries = 0
						p.jailRentToState = false
						self:addLog(p.name .. " keluar LAPAS otomatis pada percobaan ketiga.")
					end
					self.phase = "AwaitRoll"
					self.deadline = now + Rules.DecisionSeconds
					return
				end
				self.phase = "AwaitRoll"
				self.deadline = now + Rules.DecisionSeconds
				return
			end
		end
		if self:checkEnd() then return end
	end
end

function Engine.pay(self: any, seat: number, amount: number, recipient: number?, reason: string)
	local previouslyOwned: {number} = {}
	for index, owner in self.owners do
		if owner == seat then table.insert(previouslyOwned, index) end
	end
	local payment = Economy.charge(self.players, self.owners, self.buildings, seat, amount, recipient)
	local target = if recipient then self.players[recipient].name else "Negara"
	self:addLog(self.players[seat].name .. " membayar " .. Rules.formatMoney(payment.paid) .. " ke " .. target .. ": " .. reason)
	if #payment.sold > 0 then
		self:addLog("Likuidasi prototipe: " .. tostring(#payment.sold) .. " tanah dijual sesuai urutan indeks.")
	end
	if payment.bankrupt then self:addLog(self.players[seat].name .. " bangkrut dan keluar dari giliran.") end
	if #payment.sold > 0 or payment.bankrupt then
		for _, index in previouslyOwned do
			if self.owners[index] ~= seat then self.buildings[index] = nil end
		end
	end
end

function Engine.sendToJail(self: any, seat: number, reason: string)
	local p = self.players[seat]
	p.inJail = true
	p.jailTries = 0
	p.jailRentToState = false
	p.position = 9
	self:addLog(p.name .. " masuk LAPAS (" .. reason .. ").")
end

local LEVEL_NAMES = {"Subsidi 1", "Subsidi 2", "Rumah OKB"}

function Engine.levelName(self: any, level: number): string
	return LEVEL_NAMES[level] or "?"
end

function Engine.upgradeCost(self: any, tileIndex: number): number?
	local level = self.buildings[tileIndex] or 0
	if level >= 3 then return nil end
	local t = Tarif.get(tileIndex)
	local cost = if level >= 2 then t.buildOKB else t.buildSubsidi
	local owner = self.owners[tileIndex]
	if owner and self.players[owner] and self.players[owner].role == "JURAGAN" then
		cost = math.floor(cost * 0.85) -- Diskon 15% Juragan Tanah
	end
	return cost
end

function Engine.hasBuildable(self: any, seat: number): boolean
	local cash = self.players[seat].cash
	for index, owner in self.owners do
		if owner == seat and self.tiles[index].kind == "Property" then
			local cost = self:upgradeCost(index)
			if cost and cash >= cost then return true end
		end
	end
	return false
end

function Engine.roll(self: any, now: number)
	local seat = self.activeSeat
	local participant = self.players[seat]
	local d1 = self.random:NextInteger(1, 6)
	local d2 = self.random:NextInteger(1, 6)
	self.dice = {d1, d2}
	local isDouble = (d1 == d2)
	if participant.inJail then
		if isDouble then
			participant.inJail = false
			participant.jailTries = 0
			participant.jailRentToState = false
			self:addLog(participant.name .. " lempar dadu kembar " .. d1 .. "-" .. d2 .. " dan keluar LAPAS; langsung jalan.")
		else
			self:addLog(participant.name .. " gagal keluar LAPAS (dadu " .. d1 .. "-" .. d2 .. "); tetap ditahan.")
			self:advance(now)
			return
		end
	else
		-- Dadu kembar di luar LAPAS → beri giliran ekstra setelah petak selesai
		if isDouble then
			participant.extraTurn = true
			self:addLog(participant.name .. " 🎲 DADU KEMBAR " .. d1 .. "-" .. d2 .. "! Mendapat giliran ekstra!")
		end
	end
	local destination = participant.position + d1 + d2
	-- Cek Hazard: Macet
	for pos = participant.position + 1, destination do
		local checkPos = (pos - 1) % Rules.TileCount + 1
		local h = self.activeHazards and self.activeHazards[checkPos]
		if h and h.kind == "Macet" then
			destination = math.max(participant.position + 1, destination - 2)
			self:addLog("🚗 " .. participant.name .. " tertahan macet di " .. self.tiles[checkPos].name .. "! Langkah dikurangi 2!")
			break
		end
	end
	local salaryGranted = destination > Rules.TileCount
	if salaryGranted then
		if participant.salaryBanned then
			participant.salaryBanned = false
			self:addLog(participant.name .. " tidak menerima gaji (dibekukan satu putaran).")
		else
			local salary = Rules.StartSalary
			if participant.role == "PNS" then
				salary = math.floor(salary * 1.25)
				Economy.credit(participant, salary)
				self:addLog(participant.name .. " [PNS TELADAN] menerima THR & gaji START " .. Rules.formatMoney(salary) .. " (+25%)!")
			else
				Economy.credit(participant, salary)
				self:addLog(participant.name .. " menerima gaji START " .. Rules.formatMoney(salary))
			end
		end
	end
	participant.position = (destination - 1) % Rules.TileCount + 1
	local tile = self.tiles[participant.position]
	self:addLog(participant.name .. ": dadu " .. d1 .. " + " .. d2 .. " menuju " .. tile.name)
	if salaryGranted and self:hasBuildable(seat) then
		self.phase = "AwaitBuild"
		self.deadline = now + Rules.DecisionSeconds
		self:addLog(participant.name .. " dapat kesempatan membangun (prototipe: satu bangunan per gaji).")
		return
	end
	self:resolveTile(now)
end

function Engine.resolveTile(self: any, now: number)
	local seat = self.activeSeat
	local participant = self.players[seat]
	local tile = self.tiles[participant.position]
	-- Cek Hazard Banjir
	if self.activeHazards and self.activeHazards[participant.position] then
		local h = self.activeHazards[participant.position]
		if h.kind == "Banjir" then
			self:pay(seat, 200000, nil, "sewa perahu getek banjir (" .. h.name .. ")")
			self:addLog("🌊 " .. participant.name .. " menerjang " .. h.name .. "! Bayar sewa perahu getek Rp200.000!")
		end
	end
	if tile.kind == "Property" and self.tolls and self.tolls[participant.position] then
		self:addLog(tile.name .. " kini TOL: sewa properti lama tidak berlaku.")
	elseif tile.kind == "Property" then
		local owner = self.owners[participant.position]
		if not owner then
			self.phase = "AwaitBuy"
			self.deadline = now + Rules.DecisionSeconds
			return
		elseif owner == seat then
			self:addLog("Tanah sendiri: tidak ada pembayaran sewa.")
		else
			local landlord = self.players[owner]
			local level = self.buildings[participant.position] or 0
			local rent = Tarif.get(participant.position).rents[level + 1]
			local isMono, monoIsland = self:isTileMonopolized(participant.position)
			if isMono then
				rent = rent * 2
			end
			if self.round >= 6 then
				rent = math.floor(rent * 1.5)
			end
			local label = if level == 0 then "sewa kosong " .. tile.name else "sewa " .. self:levelName(level) .. " " .. tile.name
			if isMono and monoIsland then
				label = label .. " [MONOPOLI " .. monoIsland .. " 2X]"
			end
			-- Dynamic Round Event: Musim Mudik Lebaran
			if self.activeEvent and self.activeEvent.id == "MusimMudik" then
				local tileNameLower = string.lower(tile.name)
				local isTransport = (monoIsland == "Transportasi")
					or string.find(tileNameLower, "bandara")
					or string.find(tileNameLower, "pelabuhan")
					or string.find(tileNameLower, "stasiun")
					or string.find(tileNameLower, "whoosh")
					or (tile.kind == "Transport")
				if isTransport then
					rent = rent * 2
					label ..= " [MUDIK 2X]"
				end
			end
			if self.round >= 6 then
				label = label .. " [INFLASI R" .. self.round .. "]"
			end
			-- Proposed team ruleset: suppression precedes detention and teammate exemption.
			if landlord.rentSuppressed then
				self:addLog("Sewa " .. tile.name .. " sedang dinonaktifkan; tidak ada tagihan.")
			elseif landlord.inJail then
				self:pay(seat, rent, nil, label .. " (pemilik ditahan; masuk Negara)")
			elseif landlord.team == participant.team then
				self:addLog("Tanah rekan yang bebas: tidak ada pembayaran sewa.")
			else
				self:pay(seat, rent, owner, label)
			end
		end
	elseif tile.kind == "Tax" then
		if participant.role == "INFLUENCER" then
			self:addLog("📸 [INFLUENCER VIRAL] " .. participant.name .. " bebas pajak berkat endorsement story IG!")
		else
			self:pay(seat, Rules.TaxAmount, nil, "pajak tetap prototipe")
		end
	elseif tile.kind == "Parking" then
		if participant.role == "INFLUENCER" then
			self:addLog("📸 [INFLUENCER VIRAL] " .. participant.name .. " bebas pungli parkir (dikenal akamsi)!")
		else
			self:pay(seat, Rules.ParkingAmount, nil, "parkir prototipe")
		end
	elseif tile.kind == "Fate" or tile.kind == "Disaster" then
		self:drawCard(seat, tile.kind, now)
		return
	elseif tile.kind == "Prison" then
		self:addLog(participant.name .. " hanya berkunjung ke LAPAS.")
	elseif tile.kind == "Court" then
		self:court(seat, now)
		return
	end
	self:advance(now)
end

function Engine.court(self: any, seat: number, now: number)
	local participant = self.players[seat]
	-- Gunakan 2 dadu (2-12) untuk distribusi probabilitas yang lebih representatif
	local d1 = self.random:NextInteger(1, 6)
	local d2 = self.random:NextInteger(1, 6)
	local roll = d1 + d2
	if participant.role == "PENGACARA" then
		roll = math.min(12, roll + 2)
		self:addLog("⚖️ [PENGACARA KONDANG] Lobi praperadilan lihai memberi bonus dadu sidang +2! (Hasil: " .. roll .. ")")
	end
	self.dice = {d1, d2}
	self:addLog(participant.name .. " di Pengadilan, dadu " .. d1 .. "+" .. d2 .. "=" .. roll .. ".")
	if roll >= 9 then
		-- Tinggi (9-12): menang gugatan
		Economy.credit(participant, Rules.CourtCompensation)
		self:addLog(participant.name .. " menang gugatan, menerima " .. Rules.formatMoney(Rules.CourtCompensation) .. ".")
	elseif roll >= 5 then
		-- Sedang (5-8): denda dan LAPAS
		self:pay(seat, Rules.CourtFine, nil, "denda Pengadilan")
		self:sendToJail(seat, "vonis Pengadilan")
	else
		-- Rendah (2-4): sitaan berat + LAPAS
		local take = math.ceil(participant.cash / 2)
		self:pay(seat, take, nil, "aset dirampas 50 persen (dibulatkan ke atas)")
		self:sendToJail(seat, "vonis Pengadilan berat")
	end
	self:advance(now)
end

function Engine.cardLandChoices(self: any, seat: number, cardId: string): {number}
	local choices: {number} = {}
	for index = 1, Rules.TileCount do
		if self.tiles[index].kind ~= "Property" or (self.tolls and self.tolls[index]) then continue end
		local owner = self.owners[index]
		if cardId == "MafiaTanah" and not owner then
			table.insert(choices, index)
		elseif cardId == "PembebasanLahan" and owner and self.players[owner] and not self.players[owner].eliminated and self.players[owner].team ~= self.players[seat].team then
			table.insert(choices, index)
		end
	end
	return choices
end

function Engine.finishCardChoice(self: any, target: number?, now: number): (boolean, string)
	local pending = self.pendingCardChoice
	if self.phase ~= "AwaitCardChoice" or not pending or pending.seat ~= self.activeSeat then
		return false, "Tidak ada pilihan kartu aktif."
	end
	local choices = self:cardLandChoices(pending.seat, pending.id)
	if target ~= nil then
		if typeof(target) ~= "number" or target ~= target or target % 1 ~= 0 or not table.find(choices, target) then
			return false, "Tanah tidak memenuhi syarat kartu."
		end
	elseif pending.id ~= "PembebasanLahan" and #choices > 0 then
		return false, "Pilih tanah kosong untuk Mafia Tanah."
	end
	self.pendingCardChoice = nil
	if target then
		local effect = self.cardEngine:resolve(pending.id, {
			seat = pending.seat, die = 0, players = self.players, owners = self.owners,
			freeLandIndex = target, enemyLandIndex = target,
		})
		self:runCardActions(effect, pending.seat, now)
	else
		self:addLog(self.players[pending.seat].name .. " melewati pilihan kartu " .. pending.id .. ".")
	end
	self:advance(now)
	return true, ""
end

function Engine.drawCard(self: any, seat: number, deckKind: string, now: number)
	if not self.cardEngine then
		local CardEngine = require(script.Parent:WaitForChild("CardEngine", 5))
		self.cardEngine = CardEngine.new()
	end
	local deckName = if deckKind == "Fate" then "Fate" else "Disaster"
	local id = self.cardEngine:draw(deckName)
	if id == "MafiaTanah" or id == "PembebasanLahan" then
		local choices = self:cardLandChoices(seat, id)
		self.cardEngine:discardCard(deckName, id)
		self.dice = {0, 0}
		self:addLog(self.players[seat].name .. " menarik " .. (if id == "MafiaTanah" then "Mafia Tanah" else "Pembebasan Lahan") .. ".")
		if #choices == 0 then
			self:addLog("Tidak ada tanah yang memenuhi syarat; kartu selesai tanpa efek.")
			self:advance(now)
		else
			self.pendingCardChoice = {id = id, seat = seat}
			self.phase = "AwaitCardChoice"
			self.deadline = now + Rules.DecisionSeconds
		end
		return
	end
	local die = self.random:NextInteger(1, 6)
	if deckName == "Disaster" and self.players[seat].insiderDie then
		die = self.players[seat].insiderDie
		self.players[seat].insiderDie = nil
		self:addLog(self.players[seat].name .. " menggunakan Orang Dalam: hasil dadu ditetapkan " .. die .. ".")
	elseif deckName == "Disaster" and self.players[seat].doaTier then
		local tier = self.players[seat].doaTier
		self.players[seat].doaTier = nil
		-- Konversi tier ke nilai representatif: high=6, mid=4, low=2
		die = if tier == "high" then 6 elseif tier == "mid" then 4 else 2
		local tierLabel = if tier == "high" then "aman (5-6)" elseif tier == "mid" then "sedang (3-4)" else "berat (1-2)"
		self:addLog(self.players[seat].name .. " menggunakan Doa Orang Tua: tier " .. tierLabel .. " (dadu " .. die .. ").")
	end
	local mostExpensive: number? = nil
	local bestValue = -1
	for index, owner in self.owners do
		if owner == seat and not (self.tolls and self.tolls[index]) then
			local value = Economy.assetInvestment(index, self.buildings)
			if value > bestValue then
				bestValue = value
				mostExpensive = index
			end
		end
	end
	local oldestSeat, youngestSeat = seat, seat
	for candidate = 1, #self.players do
		if not self.players[candidate].eliminated then
			if candidate > oldestSeat then oldestSeat = candidate end
			if candidate < youngestSeat then youngestSeat = candidate end
		end
	end
	local freeLandIndex: number? = nil
	for index = 1, Rules.TileCount do
		if self.tiles[index].kind == "Property" and not self.owners[index] and not (self.tolls and self.tolls[index]) then
			freeLandIndex = index
			break
		end
	end
	local enemyLandIndex: number? = nil
	for index = 1, Rules.TileCount do
		local owner = self.owners[index]
		if owner and owner ~= seat and self.players[owner].team ~= self.players[seat].team and not (self.tolls and self.tolls[index]) then
			enemyLandIndex = index
			break
		end
	end
	local ctx = {seat = seat, die = die, players = self.players, owners = self.owners, buildings = self.buildings, mostExpensive = mostExpensive, oldestSeat = oldestSeat, youngestSeat = youngestSeat, freeLandIndex = freeLandIndex, enemyLandIndex = enemyLandIndex, tarif = Tarif.get, assetInvestment = Economy.assetInvestment, tolls = self.tolls or {}}
	local effect = self.cardEngine:resolve(id, ctx)
	self.dice = {die, 0}
	self:addLog(self.players[seat].name .. " menarik " .. effect.name .. " (" .. deckName .. ", dadu " .. die .. ").")
	if #effect.actions == 0 then
		self:addLog("Tidak ada tanah/kondisi yang memenuhi syarat; kartu selesai tanpa efek tambahan.")
	end
	self:runCardActions(effect, seat, now)
	self.cardEngine:discardCard(deckName, id)
	self:advance(now)
end

function Engine.runCardActions(self: any, effect: any, seat: number, now: number)
	for _, a in ipairs(effect.actions) do
		local p = self.players[a.seat or seat]
		if a.type == "pay" then
			if a.to == a.seat then
				self:addLog(p.name .. " adalah penerima sekaligus pembayar (" .. effect.name .. "); tidak ada transfer.")
			else
				self:pay(a.seat, a.amount, a.to, a.reason or effect.name)
			end
		elseif a.type == "credit" then
			Economy.credit(p, a.amount)
			self:addLog(p.name .. " menerima " .. Rules.formatMoney(a.amount) .. " (" .. (a.reason or effect.name) .. ").")
		elseif a.type == "jail" then
			self:sendToJail(a.seat, effect.name)
		elseif a.type == "suppressRent" then
			p.rentSuppressed = true
			self:addLog("Sewa seluruh tanah " .. p.name .. " nonaktif sampai gilirannya kembali (" .. effect.name .. ").")
		elseif a.type == "skipTurn" then
			p.skipTurns = (p.skipTurns or 0) + (a.turns or 1)
			self:addLog(p.name .. " akan melewati " .. tostring(a.turns or 1) .. " giliran (" .. effect.name .. ").")
		elseif a.type == "toBekasi" then
			p.bekasiReturnPosition = p.position
			p.inBekasi = true
			self:addLog(p.name .. " dievakuasi ke Bekasi di luar lintasan dari " .. self.tiles[p.position].name .. " (" .. effect.name .. ").")
		elseif a.type == "teleport" then
			p.position = a.tile
			p.inBekasi = false
			p.bekasiReturnPosition = nil
			self:addLog(p.name .. " berpindah ke " .. self.tiles[a.tile].name .. " (" .. effect.name .. ").")
		elseif a.type == "grantLand" then
			if not self.owners[a.tile] then
				self.owners[a.tile] = a.seat
				self:addLog(p.name .. " mengambil " .. self.tiles[a.tile].name .. " gratis (" .. effect.name .. ").")
			end
		elseif a.type == "giveLand" then
			if a.to == a.seat then
				self:addLog(p.name .. " adalah pemilik sekaligus penerima tanah (" .. effect.name .. "); tidak ada perpindahan aset.")
			elseif a.tile and a.tile >= 1 and self.owners[a.tile] == a.seat then
				self.owners[a.tile] = a.to
				self.buildings[a.tile] = nil
				self:addLog(p.name .. " menyerahkan " .. self.tiles[a.tile].name .. " ke " .. self.players[a.to].name .. " (" .. effect.name .. ").")
			elseif a.fallback and a.fallback > 0 then
				self:pay(a.seat, a.fallback, a.to, effect.name .. " (pengganti tanah)")
			end
		elseif a.type == "returnLand" then
			if self.owners[a.tile] then
				self.owners[a.tile] = nil
				self.buildings[a.tile] = nil
				self:addLog(self.tiles[a.tile].name .. " dikembalikan ke Negara (" .. effect.name .. ").")
			end
		elseif a.type == "toToll" then
			if self.owners[a.tile] then
				self.owners[a.tile] = nil
				self.buildings[a.tile] = nil
				self.tolls = self.tolls or {}
				self.tolls[a.tile] = true
				self:addLog(self.tiles[a.tile].name .. " disita dan menjadi TOL permanen (" .. effect.name .. ").")
			end
		elseif a.type == "globalBan" then
			for _, q in self.players do
				if a.kind == "salary" then
					q.salaryBanned = true
				else
					q.buyBanned = true
				end
			end
			if a.kind == "buy" then self.buyBanReleaseSeat = seat end
			self:addLog((if a.kind == "salary" then "Gaji START" else "Pembelian") .. " dinonaktifkan untuk semua pemain selama satu putaran (" .. effect.name .. ").")
		elseif a.type == "globalTeleport" then
			for _, q in self.players do
				if not q.eliminated then
					q.position = a.tile
					q.inBekasi = false
					q.bekasiReturnPosition = nil
				end
			end
			self:addLog("Semua pemain pindah ke " .. self.tiles[a.tile].name .. " (" .. effect.name .. ").")
		elseif a.type == "swapCash" then
			local x = self.players[a.seat]
			local y = self.players[a.with]
			x.cash, y.cash = y.cash, x.cash
			self:addLog(x.name .. " dan " .. y.name .. " menukar seluruh uang (" .. effect.name .. ").")
		elseif a.type == "seizeLand" then
			if self.owners[a.tile] and self.owners[a.tile] ~= a.seat then
				self.owners[a.tile] = a.seat
				self:addLog(p.name .. " memenangkan sengketa dan menguasai " .. self.tiles[a.tile].name .. " beserta bangunannya (" .. effect.name .. ").")
			end
		elseif a.type == "toHand" then
			table.insert(p.hand, a.card)
			self:addLog(p.name .. " menyimpan kartu " .. effect.name .. " untuk dipakai nanti.")
		elseif a.type == "noOp" then
			self:addLog(a.reason or ("Tidak ada efek (" .. effect.name .. ")."))
		else
			self:addLog("Efek kartu " .. a.type .. " belum diimplementasi (" .. effect.name .. ").")
		end
	end
	self:checkEnd()
end

function Engine.restart(self: any, now: number)
	assert(self.phase == "Finished" and not self.rematchUnavailable, "Rematch unavailable")
	assert(#self.players == Rules.PlayerCount, "Incomplete rematch roster")
	for seat = 1, Rules.PlayerCount do
		assert(self.rematchVotes[seat], "Missing rematch consent")
	end
	local freshPlayers: {Participant} = {}
	for _, previous in self.players do
		local assignedRole = previous.role or (if RoleConfig then RoleConfig.assignRole(#freshPlayers + 1) else "PNS")
		table.insert(freshPlayers, {
			userId = previous.userId, name = previous.name, team = previous.team,
			cash = Rules.StartingCash, position = 1, ready = true, eliminated = false,
			inJail = false, jailTries = 0, jailRentToState = false, rentSuppressed = false,
			inBekasi = false, bekasiReturnPosition = nil,
			hand = {}, extraTurn = false, doaTier = nil,
			role = assignedRole,
			portfolio = {BBUMN = 0, KRIPTO = 0},
			isBot = previous.isBot == true,
		})
	end
	self.players = freshPlayers
	if self.gameMode == "SoloFFA" then
		for idx, member in ipairs(self.players) do
			member.team = tostring(idx)
		end
	end
	self.owners = {}
	self.buildings = {}
	self.tolls = {}
	self.cardEngine = nil
	self.pendingCardChoice = nil
	self.dice = {0, 0}
	self.logs = {}
	self.result = ""
	self.round = 1
	self.activeSeat = 1
	self.phase = "AwaitRoll"
	self.deadline = now + Rules.DecisionSeconds
	self.matchId = HttpService:GenerateGUID(false)
	self.rematchVotes = {false, false, false, false}
	self.activeEvent = nil
	self.activeHazards = {}
	self.stockPrices = {BBUMN = 500000, KRIPTO = 250000}
	self.stockNews = "Bursa Efek dibuka kembali dengan optimisme baru."
	self:addLog("Semua peserta setuju. Pertandingan baru dimulai dengan uang dan aset awal.")
end

function Engine.handle(self: any, userId: number, action: string, expectedRevision: number, now: number, targetTile: any?): (boolean, string)
	if expectedRevision ~= self.revision then return false, "Keadaan berubah; coba kembali." end
	local seat = self:seatFor(userId)
	if not seat then return false, "Kamu bukan peserta sesi ini." end
	local participant = self.players[seat]
	if action == "Rematch" then
		if self.phase ~= "Finished" or self.rematchUnavailable then
			return false, "Main ulang hanya tersedia setelah selesai dengan seluruh peserta tetap terhubung."
		end
		self.rematchVotes[seat] = not self.rematchVotes[seat]
		-- Auto-vote untuk semua bot seat agar tidak menghalangi rematch
		for index = 1, Rules.PlayerCount do
			local p = self.players[index]
			if p and p.isBot == true then
				self.rematchVotes[index] = true
			end
		end
		-- Unanimous: semua human seat sudah vote (bot seat dianggap selalu setuju)
		local unanimous = #self.players == Rules.PlayerCount
		for index = 1, Rules.PlayerCount do
			local p = self.players[index]
			if p and not p.isBot and not self.rematchVotes[index] then unanimous = false end
		end
		if unanimous then self:restart(now) end
	elseif action == "RequestTeamSwap" then
		if self.phase ~= "Waiting" then return false, "Pertukaran hanya tersedia di lobi." end
		if typeof(targetTile) ~= "number" or targetTile ~= targetTile or targetTile % 1 ~= 0 or targetTile < 1 or targetTile > #self.players then return false, "Pemain tujuan tidak sah." end
		local target = self.players[targetTile]
		if target.userId == userId or target.team == participant.team then return false, "Pilih pemain dari tim lain." end
		if self.teamSwap and now < self.teamSwap.expiresAt then return false, "Selesaikan permintaan tukar tim yang sedang aktif." end
		self.teamSwap = {fromUserId = userId, toUserId = target.userId, expiresAt = now + 30}
		self:addLog(participant.name .. " meminta tukar tim dengan " .. target.name .. ".")
	elseif action == "AcceptTeamSwap" or action == "CancelTeamSwap" then
		if self.phase ~= "Waiting" or not self.teamSwap then return false, "Tidak ada permintaan tukar tim aktif." end
		if targetTile ~= nil then return false, "Respons tukar tim tidak menerima target." end
		local pending = self.teamSwap
		if now >= pending.expiresAt then return false, "Permintaan tukar tim sudah kedaluwarsa." end
		if action == "AcceptTeamSwap" then
			if userId ~= pending.toUserId then return false, "Hanya pemain tujuan yang dapat menyetujui." end
			local fromSeat = self:seatFor(pending.fromUserId)
			local toSeat = self:seatFor(pending.toUserId)
			if not fromSeat or not toSeat then return false, "Peserta sudah berubah." end
			local sender, receiver = self.players[fromSeat], self.players[toSeat]
			if sender.team == receiver.team then return false, "Kedua pemain sudah satu tim." end
			sender.team, receiver.team = receiver.team, sender.team
			for _, member in self.players do member.ready = false end
			self:addLog(sender.name .. " dan " .. receiver.name .. " menyetujui tukar tim. Semua peserta perlu siap kembali.")
		else
			if userId ~= pending.fromUserId and userId ~= pending.toUserId then return false, "Kamu tidak terlibat dalam permintaan ini." end
			self:addLog(participant.name .. " membatalkan atau menolak permintaan tukar tim.")
		end
		self.teamSwap = nil
	elseif action == "SetGameMode" then
		if self.phase ~= "Waiting" then return false, "Mode permainan hanya bisa diubah di lobi." end
		if targetTile ~= "Team2v2" and targetTile ~= "SoloFFA" then return false, "Pilihan mode tidak sah." end
		self.gameMode = targetTile
		for _, member in self.players do member.ready = false end
		self:addLog("Mode permainan diubah: " .. (if targetTile == "SoloFFA" then "👑 SOLO SULTAN (1v1v1v1 FFA)" else "🤝 TIM 2v2 NUSANTARA") .. ". Nyatakan siap kembali.")
	elseif action == "SelectRole" then
		if self.phase ~= "Waiting" then return false, "Profesi hanya bisa dipilih di lobi." end
		if targetTile ~= "PNS" and targetTile ~= "JURAGAN" and targetTile ~= "INFLUENCER" and targetTile ~= "PENGACARA" then
			return false, "Profesi tidak dikenal."
		end
		participant.role = targetTile
		local roleDef = if RoleConfig then RoleConfig.get(targetTile) else nil
		local roleName = if roleDef then roleDef.icon .. " " .. roleDef.name else targetTile
		self:addLog(participant.name .. " memilih profesi " .. roleName .. ".")
	elseif action == "BailoutTeammate" then
		if self.gameMode == "SoloFFA" then return false, "Tidak ada rekan di mode Solo." end
		local teammateSeat = nil
		for s, p in ipairs(self.players) do
			if s ~= seat and p.team == participant.team and not p.eliminated then
				teammateSeat = s
				break
			end
		end
		if not teammateSeat then return false, "Rekan tidak ditemukan atau sudah tereliminasi." end
		local teammate = self.players[teammateSeat]
		local transferAmount = 1000000
		if participant.cash < transferAmount + 100000 then return false, "Saldo kasmu tidak mencukupi untuk membantu rekan." end
		participant.cash -= transferAmount
		teammate.cash += transferAmount
		self:addLog("🤝 GOTONG ROYONG! " .. participant.name .. " mentransfer " .. Rules.formatMoney(transferAmount) .. " ke rekan setimnya " .. teammate.name .. "!")
	elseif action == "BailTeammateFromJail" then
		if self.gameMode == "SoloFFA" then return false, "Tidak ada rekan di mode Solo." end
		local teammateSeat = nil
		for s, p in ipairs(self.players) do
			if s ~= seat and p.team == participant.team and not p.eliminated then
				teammateSeat = s
				break
			end
		end
		if not teammateSeat then return false, "Rekan tidak ditemukan." end
		local teammate = self.players[teammateSeat]
		if not teammate.inJail then return false, "Rekan tidak sedang berada di LAPAS." end
		local cost = Rules.JailBailAmount
		if participant.role == "PENGACARA" or teammate.role == "PENGACARA" then
			cost = math.floor(cost * 0.5) -- Diskon 50% Pengacara
		end
		if participant.cash < cost then return false, "Uang kas tidak cukup untuk tebusan LAPAS." end
		participant.cash -= cost
		teammate.inJail = false
		teammate.jailTries = 0
		teammate.jailRentToState = false
		self:addLog("🔓 TEBUSAN LAPAS! " .. participant.name .. " menebus kebebasan " .. teammate.name .. " seharga " .. Rules.formatMoney(cost) .. "!")
	elseif action == "BuyStock" then
		if typeof(targetTile) ~= "table" then return false, "Parameter saham tidak sah." end
		local stockId = targetTile.stockId
		local count = math.clamp(tonumber(targetTile.count) or 1, 1, 10)
		local currentPrice = self.stockPrices[stockId]
		local currentOwned = (participant.portfolio and participant.portfolio[stockId]) or 0
		if currentOwned + count > 10 then
			return false, string.format("Maksimal kepemilikan 10 lot per instrumen (kamu sudah memiliki %d lot).", currentOwned)
		end
		local totalCost = currentPrice * count
		if participant.cash < totalCost then return false, "Uang kas tidak cukup untuk membeli saham." end
		participant.cash -= totalCost
		participant.portfolio = participant.portfolio or {}
		participant.portfolio[stockId] = currentOwned + count
		self:addLog(string.format("📈 %s membeli %d lot %s seharga %s!", participant.name, count, stockId, Rules.formatMoney(totalCost)))
	elseif action == "SellStock" then
		if typeof(targetTile) ~= "table" then return false, "Parameter saham tidak sah." end
		local stockId = targetTile.stockId
		local count = math.clamp(tonumber(targetTile.count) or 1, 1, 10)
		participant.portfolio = participant.portfolio or {}
		local owned = participant.portfolio[stockId] or 0
		if owned < count then return false, "Jumlah lot saham yang kamu miliki tidak cukup." end
		local currentPrice = self.stockPrices[stockId] or 0
		local totalIncome = currentPrice * count
		participant.portfolio[stockId] -= count
		participant.cash += totalIncome
		self:addLog(string.format("📉 %s menjual %d lot %s seharga %s!", participant.name, count, stockId, Rules.formatMoney(totalIncome)))
	elseif action == "ChooseTeam" then
		if self.phase ~= "Waiting" then return false, "Tim terkunci setelah pertandingan dimulai." end
		if targetTile ~= "A" and targetTile ~= "B" then return false, "Pilih Tim A atau Tim B." end
		if participant.team == targetTile then return false, "Kamu sudah berada di tim ini." end
		local count = 0
		for _, member in self.players do if member.team == targetTile then count += 1 end end
		if count >= 2 then return false, "Tim sudah penuh (2 pemain)." end
		self.teamSwap = nil
		participant.team = targetTile
		for _, member in self.players do member.ready = false end
		self:addLog(participant.name .. " memilih Tim " .. targetTile .. ". Semua peserta perlu menyatakan siap kembali.")
	elseif action == "Ready" then
		if self.phase ~= "Waiting" then return false, "Persiapan sudah berakhir." end
		if #self.players == Rules.PlayerCount and self.gameMode ~= "SoloFFA" then
			local countA, countB = 0, 0
			for _, member in self.players do
				if member.team == "A" then countA += 1 elseif member.team == "B" then countB += 1 end
			end
			if countA ~= 2 or countB ~= 2 then return false, "Pertandingan membutuhkan dua pemain di setiap tim." end
		end
		participant.ready = not participant.ready
		local allReady = #self.players == Rules.PlayerCount
		for _, member in self.players do if not member.ready then allReady = false end end
		if allReady then
			self.teamSwap = nil
			if self.gameMode == "SoloFFA" then
				for idx, member in ipairs(self.players) do
					member.team = tostring(idx)
				end
				self.round = 1
				self.activeSeat = 1
				self.phase = "AwaitRoll"
				self.deadline = now + Rules.DecisionSeconds
				self:addLog("👑 MODE SOLO SULTAN DIMULAI! Tidak ada rekan, jadilah Sultan terkaya!")
			else
				local teamA: {Participant} = {}
				local teamB: {Participant} = {}
				for _, member in self.players do
					table.insert(if member.team == "A" then teamA else teamB, member)
				end
				self.players = {teamA[1], teamB[1], teamA[2], teamB[2]}
				self.round = 1
				self.activeSeat = 1
				self.phase = "AwaitRoll"
				self.deadline = now + Rules.DecisionSeconds
				self:addLog("Prototipe dimulai. Giliran A1, B1, A2, B2; batas 8 ronde.")
			end
		end
	else
		if seat ~= self.activeSeat or participant.eliminated then return false, "Bukan giliranmu." end
		if (action == "SelectCardLand" or action == "SkipCardChoice") and self.phase == "AwaitCardChoice" then
			if action == "SelectCardLand" and typeof(targetTile) ~= "number" then return false, "Pilih tanah yang sah." end
			if action == "SkipCardChoice" and targetTile ~= nil then return false, "Lewati tidak menerima target." end
			local ok, message = self:finishCardChoice(if action == "SelectCardLand" then targetTile else nil, now)
			if not ok then return false, message end
		elseif action == "PlayCard" and self.phase == "AwaitRoll" then
			if typeof(targetTile) ~= "table" then return false, "Pilihan kartu tidak sah." end
			local cardId = targetTile.cardId
			local choice = targetTile.choice
			if cardId ~= "KaburAjaDulu" and cardId ~= "OrangDalam" and cardId ~= "DoaOrangTua" then return false, "Kartu tidak dapat dimainkan." end
			if cardId == "KaburAjaDulu" then
				local maximum = Rules.TileCount
				if typeof(choice) ~= "number" or choice ~= choice or choice % 1 ~= 0 or choice < 1 or choice > maximum then
					return false, "Pilih tujuan petak yang sah (1-" .. maximum .. ")."
				end
				if not self.tiles[choice] then return false, "Petak tujuan tidak tersedia." end
			elseif cardId == "OrangDalam" then
				if typeof(choice) ~= "number" or choice ~= choice or choice % 1 ~= 0 or choice < 1 or choice > 6 then
					return false, "Pilih nilai dadu yang sah (1-6)."
				end
				if participant.insiderDie then return false, "Orang Dalam sudah disiapkan untuk Musibah berikutnya." end
			elseif cardId == "DoaOrangTua" then
				if choice ~= "high" and choice ~= "mid" and choice ~= "low" then
					return false, "Pilih tier: 'high' (aman), 'mid' (sedang), atau 'low' (berat)."
				end
				if participant.doaTier then return false, "Doa Orang Tua sudah disiapkan untuk Musibah berikutnya." end
			end
			local handIndex = table.find(participant.hand, cardId)
			if not handIndex then return false, "Kartu tidak ada di tanganmu." end
			table.remove(participant.hand, handIndex)
			if cardId == "KaburAjaDulu" then
				participant.position = choice :: number
				participant.inBekasi = false
				participant.bekasiReturnPosition = nil
				self:addLog(participant.name .. " kabur ke " .. self.tiles[choice :: number].name .. " (Kabur Aja Dulu); tanpa gaji START, efek lokasi tetap berlaku.")
				self:resolveTile(now)
			elseif cardId == "OrangDalam" then
				participant.insiderDie = choice :: number
				self:addLog(participant.name .. " menyiapkan Orang Dalam: Musibah berikutnya dipicu dadu " .. (choice :: number) .. " (adaptasi pilih tingkat).")
			else -- DoaOrangTua
				participant.doaTier = choice :: string
				local tierLabel = if choice == "high" then "aman (5-6)" elseif choice == "mid" then "sedang (3-4)" else "berat (1-2)"
				self:addLog(participant.name .. " menyiapkan Doa Orang Tua: tier " .. tierLabel .. " untuk Musibah berikutnya.")
			end
			self.revision += 1
			return true, ""
		elseif action == "Bail" and self.phase == "AwaitRoll" then
			if not participant.inJail then return false, "Kamu tidak ditahan." end
			if participant.cash < Rules.JailBailAmount then return false, "Uang tidak cukup untuk titipan." end
			participant.cash -= Rules.JailBailAmount
			participant.inJail = false
			participant.jailTries = 0
			participant.jailRentToState = false
			self:addLog(participant.name .. " bayar titipan " .. Rules.formatMoney(Rules.JailBailAmount) .. " dan keluar LAPAS; langsung jalan.")
			self:roll(now)
		elseif action == "Roll" and self.phase == "AwaitRoll" then
			self:roll(now)
		elseif action == "Build" and self.phase == "AwaitBuild" then
			local index = targetTile
			if typeof(index) ~= "number" or index ~= index or index % 1 ~= 0 or index < 1 or index > Rules.TileCount then
				return false, "Pilih tanah yang sah untuk dibangun."
			end
			if not self.tiles[index] or self.tiles[index].kind ~= "Property" then
				return false, "Bangunan hanya dapat dibuat pada petak properti."
			end
			if self.owners[index] ~= seat then return false, "Hanya bisa membangun di tanahmu." end
			local cost = self:upgradeCost(index)
			if not cost then return false, "Tidak bisa meningkatkan lagi." end
			if participant.cash < cost then return false, "Uang tidak cukup untuk bangun." end
			participant.cash -= cost
			self.buildings[index] = (self.buildings[index] or 0) + 1
			self:addLog(participant.name .. " membangun " .. self:levelName(self.buildings[index]) .. " di " .. self.tiles[index].name .. " (" .. Rules.formatMoney(cost) .. ").")
			self:resolveTile(now)
		elseif action == "SkipBuild" and self.phase == "AwaitBuild" then
			self:addLog(participant.name .. " melewati kesempatan membangun.")
			self:resolveTile(now)
		elseif (action == "Buy" or action == "Skip") and self.phase == "AwaitBuy" then
			if action == "Buy" then
				if participant.buyBanned then return false, "Pembelian sedang dilarang (efek kartu)." end
				if self.tiles[participant.position].kind ~= "Property" then return false, "Bukan tanah." end
				local price = Tarif.get(participant.position).price
				if participant.role == "JURAGAN" then
					price = math.floor(price * 0.85) -- Diskon 15% Juragan Tanah
				end
				if participant.cash < price then return false, "Uang kas tidak mencukupi." end
				participant.cash -= price
				self.owners[participant.position] = seat
				self:addLog(participant.name .. " membeli " .. self.tiles[participant.position].name .. " seharga " .. Rules.formatMoney(price) .. (if participant.role == "JURAGAN" then " [DISKON JURAGAN 15%]" else ""))
				local isMono, monoIsland = self:isTileMonopolized(participant.position)
				if isMono and monoIsland then
					if self.gameMode == "SoloFFA" then
						self:addLog("👑 MONOPOLI SULTAN: " .. participant.name .. " menguasai seluruh wilayah " .. monoIsland .. "! Sewa berlipat ganda 2x!")
					else
						self:addLog("👑 MONOPOLI NUSANTARA: Tim " .. participant.team .. " menguasai seluruh wilayah " .. monoIsland .. "! Sewa berlipat ganda 2x!")
					end
				end
			else
				self:addLog(participant.name .. " melewati pembelian.")
			end
			self:advance(now)
		else
			return false, "Aksi tidak sesuai fase pertandingan."
		end
	end
	self.revision += 1
	return true, ""
end

function Engine.tick(self: any, now: number): boolean
	if self.phase == "Waiting" and self.teamSwap and now >= self.teamSwap.expiresAt then
		self.teamSwap = nil
		self:addLog("Permintaan tukar tim kedaluwarsa.")
		self.revision += 1
		return true
	end
	if self.deadline <= 0 or now < self.deadline then return false end
	if self.phase == "AwaitRoll" then
		self:addLog("Waktu habis: server melempar dadu otomatis.")
		self:roll(now)
	elseif self.phase == "AwaitBuild" then
		self:addLog("Waktu habis: kesempatan membangun dilewati.")
		self:resolveTile(now)
	elseif self.phase == "AwaitCardChoice" then
		local pending = self.pendingCardChoice
		assert(pending, "Missing pending card choice")
		local choices = self:cardLandChoices(pending.seat, pending.id)
		local target = if pending.id == "MafiaTanah" then choices[1] else nil
		self:addLog("Waktu habis: " .. (if target then "Mafia Tanah memilih tanah sah pertama (prototipe)." else "pilihan kartu dilewati."))
		local ok, message = self:finishCardChoice(target, now)
		assert(ok, message)
	elseif self.phase == "AwaitBuy" then
		self:addLog("Waktu habis: pembelian opsional dilewati.")
		self:advance(now)
	else
		return false
	end
	self.revision += 1
	return true
end

function Engine.snapshot(self: any)
	local participants = {}
	for _, participant in self.players do
		local pClone = table.clone(participant)
		pClone.portfolio = if participant.portfolio then table.clone(participant.portfolio) else {BBUMN = 0, KRIPTO = 0}
		table.insert(participants, pClone)
	end
	local ownership = {}
	for index = 1, Rules.TileCount do ownership[index] = self.owners[index] or 0 end
	local buildings = {}
	for index = 1, Rules.TileCount do buildings[index] = self.buildings[index] or 0 end
	local tolls: {boolean} = {}
	for index = 1, Rules.TileCount do tolls[index] = self.tolls ~= nil and self.tolls[index] == true end
	return {
		version = Rules.Version, revision = self.revision, phase = self.phase,
		players = participants, owners = ownership, buildings = buildings, tolls = tolls, activeSeat = self.activeSeat,
		round = self.round, deadline = self.deadline, dice = table.clone(self.dice),
		logs = table.clone(self.logs), result = self.result,
		matchId = self.matchId, rematchVotes = table.clone(self.rematchVotes),
		rematchUnavailable = self.rematchUnavailable,
		monopolies = self:getIslandMonopolies(),
		teamSwap = if self.phase == "Waiting" and self.teamSwap then table.clone(self.teamSwap) else nil,
		activeEvent = if self.activeEvent then table.clone(self.activeEvent) else nil,
		gameMode = self.gameMode or "Team2v2",
		activeHazards = if self.activeHazards then table.clone(self.activeHazards) else {},
		stockPrices = if self.stockPrices then table.clone(self.stockPrices) else {},
		stockNews = self.stockNews or "",
		cardChoice = if self.phase == "AwaitCardChoice" and self.pendingCardChoice then {
			id = self.pendingCardChoice.id, seat = self.pendingCardChoice.seat,
			options = self:cardLandChoices(self.pendingCardChoice.seat, self.pendingCardChoice.id),
			canSkip = self.pendingCardChoice.id == "PembebasanLahan",
		} else nil,
	}
end

return Engine
