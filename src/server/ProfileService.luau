--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProgressionConfig = require(ReplicatedStorage:WaitForChild("WNI"):WaitForChild("ProgressionConfig"))

export type Profile = {
	version: number,
	matches: number,
	wins: number,
	losses: number,
	draws: number,
	lastMatchId: string,
	recentMatchIds: {string},
	xp: number,
	level: number,
	coins: number,
	title: string,
	diceSkin: string,
}

local STORE_NAME = "WNI_Profile_v1"
local PROFILE_VERSION = 3
local store: any = nil
local storeOK, storeResult = pcall(function()
	return DataStoreService:GetDataStore(STORE_NAME)
end)
if storeOK then
	store = storeResult
end

local ProfileService = {}
ProfileService.__index = ProfileService

local function defaultProfile(): Profile
	return {
		version = PROFILE_VERSION,
		matches = 0,
		wins = 0,
		losses = 0,
		draws = 0,
		lastMatchId = "",
		recentMatchIds = {},
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

function ProfileService.recordMatch(self: any, userId: number, matchId: string, outcome: string): boolean
	if matchId == "" or (outcome ~= "win" and outcome ~= "loss" and outcome ~= "draw") then return false end
	local key = "u_" .. tostring(userId)
	local cached = self.cache[userId] or defaultProfile()
	if table.find(cached.recentMatchIds, matchId) then return false end

	local ok, updated = false, nil
	if store then
		ok, updated = pcall(function()
			return store:UpdateAsync(key, function(raw)
				local profile = sanitize(raw)
				if table.find(profile.recentMatchIds, matchId) then return profile end
				profile.matches += 1
				local xpGain = if outcome == "win" then 250 elseif outcome == "draw" then 100 else 50
				local coinGain = if outcome == "win" then 500 elseif outcome == "draw" then 250 else 100
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
				return profile
			end)
		end)
	end

	if ok and typeof(updated) == "table" then
		self.cache[userId] = sanitize(updated)
		self.loaded[userId] = true
		return true
	end

	-- Studio/API-disabled fallback: keep useful session stats without overwriting persistent data.
	cached.matches += 1
	local xpGain = if outcome == "win" then 250 elseif outcome == "draw" then 100 else 50
	local coinGain = if outcome == "win" then 500 elseif outcome == "draw" then 250 else 100
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
	self.cache[userId] = cached
	self.loaded[userId] = true
	return true
end

function ProfileService.setDiceSkin(self: any, userId: number, skinKey: string): boolean
	local skin = ProgressionConfig.DICE_SKINS[skinKey]
	if not skin then return false end
	local profile = self:get(userId)
	if profile.level < skin.RequiredLevel then return false end

	profile.diceSkin = skinKey
	self.cache[userId] = profile

	if store then
		local key = "u_" .. tostring(userId)
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
		task.spawn(function()
			self:load(player)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:release(player.UserId)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:load(player)
		end)
	end
end

return ProfileService
