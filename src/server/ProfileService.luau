--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProgressionConfig = require(ReplicatedStorage:WaitForChild("WNI"):WaitForChild("ProgressionConfig"))

export type MatchHistoryItem = {
	matchId: string,
	outcome: string, -- "win", "loss", "draw"
	xpGain: number,
	coinGain: number,
	timestamp: number,
	summary: string?,
}

export type AchievementItem = {
	id: string,
	unlocked: boolean,
	unlockedAt: number,
}

export type Profile = {
	version: number,
	matches: number,
	wins: number,
	losses: number,
	draws: number,
	lastMatchId: string,
	recentMatchIds: {string},
	matchHistory: {MatchHistoryItem},
	achievements: {[string]: AchievementItem},
	xp: number,
	level: number,
	coins: number,
	title: string,
	diceSkin: string,
}

local STORE_NAME = "WNI_Profile_v1"
local PROFILE_VERSION = 4
local store: any = nil
local storeOK, storeResult = pcall(function()
	return DataStoreService:GetDataStore(STORE_NAME)
end)
if storeOK then
	store = storeResult
end

local ACHIEVEMENTS_DEF: {[string]: {name: string, desc: string, xp: number, coins: number, icon: string}} = {
	first_match = {name = "Langkah Perdana", desc = "Mainkan 1 pertandingan sampai selesai", xp = 100, coins = 200, icon = "🏁"},
	first_win = {name = "Kemenangan Perdana", desc = "Menangkan 1 pertandingan", xp = 150, coins = 300, icon = "🏆"},
	monopoly_king = {name = "Sultan Monopoli", desc = "Bentuk monopoli 1 pulau penuh", xp = 250, coins = 500, icon = "👑"},
	escape_jail = {name = "Bebas dari LAPAS", desc = "Bebas dari LAPAS dengan dadu kembar/jaminan", xp = 100, coins = 200, icon = "🔓"},
	survive_bankrupt = {name = "Hoki Selamat", desc = "Menang saat kas di bawah Rp1.000.000", xp = 200, coins = 400, icon = "🍀"},
	card_master = {name = "Taktik Kartu", desc = "Gunakan kartu simpanan dari tangan", xp = 100, coins = 200, icon = "🃏"},
	land_tycoon = {name = "Juragan Tanah", desc = "Miliki 4 tanah secara bersamaan", xp = 200, coins = 400, icon = "🏘️"},
	ten_matches = {name = "Warga Teladan", desc = "Mainkan 10 pertandingan", xp = 300, coins = 600, icon = "⭐"},
}

local ProfileService = {}
ProfileService.__index = ProfileService
ProfileService.ACHIEVEMENTS_DEF = ACHIEVEMENTS_DEF

local function defaultProfile(): Profile
	return {
		version = PROFILE_VERSION,
		matches = 0,
		wins = 0,
		losses = 0,
		draws = 0,
		lastMatchId = "",
		recentMatchIds = {},
		matchHistory = {},
		achievements = {},
		xp = 0,
		level = 1,
		coins = 1000,
		title = "Warga Biasa",
		diceSkin = "Classic",
	}
end

local function sanitize(raw: any): Profile
	local profile = defaultProfile()
	if typeof(raw) ~= "table" then return profile end
	local function safeInt(value: any): number
		if typeof(value) ~= "number" or value ~= value or value < 0 then return 0 end
		return math.floor(value)
	end
	profile.matches = safeInt(raw.matches)
	profile.wins = safeInt(raw.wins)
	profile.losses = safeInt(raw.losses)
	profile.draws = safeInt(raw.draws)
	profile.xp = safeInt(raw.xp)
	profile.coins = if typeof(raw.coins) == "number" and raw.coins >= 0 then math.floor(raw.coins) else 1000
	local calculatedLevel = ProgressionConfig.calculateLevel(profile.xp)
	profile.level = calculatedLevel
	profile.title = ProgressionConfig.getTitleForLevel(calculatedLevel)
	profile.diceSkin = if typeof(raw.diceSkin) == "string" and ProgressionConfig.DICE_SKINS[raw.diceSkin] ~= nil then raw.diceSkin else "Classic"
	profile.lastMatchId = if typeof(raw.lastMatchId) == "string" then string.sub(raw.lastMatchId, 1, 80) else ""

	if typeof(raw.recentMatchIds) == "table" then
		local seen: {[string]: boolean} = {}
		for _, value in raw.recentMatchIds do
			if typeof(value) == "string" then
				local id = string.sub(value, 1, 80)
				if id ~= "" and not seen[id] then
					table.insert(profile.recentMatchIds, id)
					seen[id] = true
					if #profile.recentMatchIds >= 20 then break end
				end
			end
		end
	elseif profile.lastMatchId ~= "" then
		table.insert(profile.recentMatchIds, profile.lastMatchId)
	end

	-- Sanitize Match History
	if typeof(raw.matchHistory) == "table" then
		for _, item in ipairs(raw.matchHistory) do
			if typeof(item) == "table" and typeof(item.matchId) == "string" then
				table.insert(profile.matchHistory, {
					matchId = tostring(item.matchId),
					outcome = tostring(item.outcome or "draw"),
					xpGain = safeInt(item.xpGain),
					coinGain = safeInt(item.coinGain),
					timestamp = safeInt(item.timestamp),
					summary = if typeof(item.summary) == "string" then item.summary else nil,
				})
				if #profile.matchHistory >= 10 then break end
			end
		end
	end

	-- Sanitize Achievements
	if typeof(raw.achievements) == "table" then
		for achId, item in pairs(raw.achievements) do
			if typeof(achId) == "string" and ACHIEVEMENTS_DEF[achId] ~= nil and typeof(item) == "table" and item.unlocked == true then
				profile.achievements[achId] = {
					id = achId,
					unlocked = true,
					unlockedAt = safeInt(item.unlockedAt),
				}
			end
		end
	end

	return profile
end

function ProfileService.new()
	local self: any = setmetatable({}, ProfileService)
	self.cache = {} :: {[number]: Profile}
	self.loaded = {} :: {[number]: boolean}
	self.warned = {} :: {[number]: boolean}
	return self
end

function ProfileService.get(self: any, userId: number): Profile
	return self.cache[userId] or defaultProfile()
end

function ProfileService.load(self: any, player: Player): Profile
	local userId = player.UserId
	if self.loaded[userId] then return self:get(userId) end
	local key = "u_" .. tostring(userId)
	local ok, raw = false, nil
	if store then
		ok, raw = pcall(function()
			return store:GetAsync(key)
		end)
	end
	if ok then
		self.cache[userId] = sanitize(raw)
	else
		self.cache[userId] = self.cache[userId] or defaultProfile()
		if not self.warned[userId] then
			self.warned[userId] = true
			warn("[WNI] Profile load unavailable for " .. player.Name .. "; using session-only profile.")
		end
	end
	self.loaded[userId] = true
	return self.cache[userId]
end

function ProfileService.unlockAchievement(self: any, userId: number, achId: string): boolean
	local def = ACHIEVEMENTS_DEF[achId]
	if not def then return false end
	local profile = self:get(userId)
	profile.achievements = profile.achievements or {}
	if profile.achievements[achId] and profile.achievements[achId].unlocked then
		return false
	end

	profile.achievements[achId] = {
		id = achId,
		unlocked = true,
		unlockedAt = os.time(),
	}
	profile.xp = (profile.xp or 0) + def.xp
	profile.coins = (profile.coins or 1000) + def.coins
	local newLevel = ProgressionConfig.calculateLevel(profile.xp)
	profile.level = newLevel
	profile.title = ProgressionConfig.getTitleForLevel(newLevel)

	-- Fire notification to online player
	local player = Players:GetPlayerByUserId(userId)
	if player then
		local sharedRemotes = ReplicatedStorage:FindFirstChild("WNI") and ReplicatedStorage.WNI:FindFirstChild("Remotes")
		local re = sharedRemotes and sharedRemotes:FindFirstChild("AchievementUnlocked") :: RemoteEvent?
		if re then
			re:FireClient(player, {
				id = achId,
				name = def.name,
				desc = def.desc,
				icon = def.icon,
				xp = def.xp,
				coins = def.coins,
			})
		end
	end
	return true
end

function ProfileService.recordMatch(self: any, userId: number, matchId: string, outcome: string, summary: string?): boolean
	if matchId == "" or (outcome ~= "win" and outcome ~= "loss" and outcome ~= "draw") then return false end
	local key = "u_" .. tostring(userId)
	local cached = self.cache[userId] or defaultProfile()
	if table.find(cached.recentMatchIds, matchId) then return false end

	local xpGain = if outcome == "win" then 250 elseif outcome == "draw" then 100 else 50
	local coinGain = if outcome == "win" then 500 elseif outcome == "draw" then 250 else 100

	local ok, updated = false, nil
	if store then
		ok, updated = pcall(function()
			return store:UpdateAsync(key, function(raw)
				local profile = sanitize(raw)
				if table.find(profile.recentMatchIds, matchId) then return profile end
				profile.matches += 1
				profile.xp = (profile.xp or 0) + xpGain
				profile.coins = (profile.coins or 1000) + coinGain
				local newLevel = ProgressionConfig.calculateLevel(profile.xp)
				profile.level = newLevel
				profile.title = ProgressionConfig.getTitleForLevel(newLevel)
				if outcome == "win" then
					profile.wins += 1
				elseif outcome == "loss" then
					profile.losses += 1
				else
					profile.draws += 1
				end
				profile.lastMatchId = matchId
				table.insert(profile.recentMatchIds, 1, matchId)
				while #profile.recentMatchIds > 20 do table.remove(profile.recentMatchIds) end

				-- Update Match History
				profile.matchHistory = profile.matchHistory or {}
				table.insert(profile.matchHistory, 1, {
					matchId = matchId,
					outcome = outcome,
					xpGain = xpGain,
					coinGain = coinGain,
					timestamp = os.time(),
					summary = summary,
				})
				while #profile.matchHistory > 10 do table.remove(profile.matchHistory) end

				return profile
			end)
		end)
	end

	if ok and typeof(updated) == "table" then
		self.cache[userId] = sanitize(updated)
		self.loaded[userId] = true
	else
		-- Session fallback
		cached.matches += 1
		cached.xp = (cached.xp or 0) + xpGain
		cached.coins = (cached.coins or 1000) + coinGain
		local fallbackLevel = ProgressionConfig.calculateLevel(cached.xp)
		cached.level = fallbackLevel
		cached.title = ProgressionConfig.getTitleForLevel(fallbackLevel)
		if outcome == "win" then
			cached.wins += 1
		elseif outcome == "loss" then
			cached.losses += 1
		else
			cached.draws += 1
		end
		cached.lastMatchId = matchId
		table.insert(cached.recentMatchIds, 1, matchId)
		while #cached.recentMatchIds > 20 do table.remove(cached.recentMatchIds) end

		cached.matchHistory = cached.matchHistory or {}
		table.insert(cached.matchHistory, 1, {
			matchId = matchId,
			outcome = outcome,
			xpGain = xpGain,
			coinGain = coinGain,
			timestamp = os.time(),
			summary = summary,
		})
		while #cached.matchHistory > 10 do table.remove(cached.matchHistory) end
	end

	-- Check auto achievements on match finish
	self:unlockAchievement(userId, "first_match")
	if outcome == "win" then
		self:unlockAchievement(userId, "first_win")
	end
	local p = self:get(userId)
	if p.matches >= 10 then
		self:unlockAchievement(userId, "ten_matches")
	end

	return true
end

function ProfileService.setDiceSkin(self: any, userId: number, skinKey: string): boolean
	local skinDef = ProgressionConfig.DICE_SKINS[skinKey]
	if not skinDef then return false end
	local profile = self:get(userId)
	if profile.level < skinDef.requiredLevel then return false end

	profile.diceSkin = skinKey
	local key = "u_" .. tostring(userId)
	if store then
		task.spawn(function()
			pcall(function()
				store:UpdateAsync(key, function(raw)
					local p = sanitize(raw)
					p.diceSkin = skinKey
					return p
				end)
			end)
		end)
	end
	return true
end

function ProfileService.release(self: any, userId: number)
	self.cache[userId] = nil
	self.loaded[userId] = nil
	self.warned[userId] = nil
end

function ProfileService.bindLifecycle(self: any)
	Players.PlayerAdded:Connect(function(player)
		self:load(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:release(player.UserId)
	end)
end

return ProfileService
