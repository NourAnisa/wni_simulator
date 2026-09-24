--!strict
-- LeaderboardService.luau
-- Leaderboard global (OrderedDataStore XP) + Misi Harian sederhana.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
local Remotes = shared and shared:WaitForChild("Remotes", 10)

local xpStore: any = nil
local storeOK, storeResult = pcall(function()
	return DataStoreService:GetOrderedDataStore("WNI_XP_Leaderboard_v1")
end)
if storeOK then xpStore = storeResult end

-- Remote events untuk leaderboard & misi
if Remotes then
	for _, name in ipairs({"LeaderboardUpdated", "MissionsUpdated"}) do
		if not Remotes:FindFirstChild(name) then
			local re = Instance.new("RemoteEvent")
			re.Name = name
			re.Parent = Remotes
		end
	end
end

local function getRemote(name: string): RemoteEvent?
	return Remotes and Remotes:FindFirstChild(name) :: RemoteEvent?
end

-- ===================== LEADERBOARD =====================

export type LeaderboardEntry = {rank: number, userId: number, xp: number, level: number, title: string}

local LeaderboardService = {}
LeaderboardService.__index = LeaderboardService

local cachedLeaderboard: {LeaderboardEntry} = {}
local lastRefresh = 0
local REFRESH_INTERVAL = 120

function LeaderboardService.updatePlayerXP(userId: number, xp: number)
	if not xpStore then return end
	task.spawn(function()
		pcall(function() xpStore:SetAsync(tostring(userId), math.floor(math.max(xp, 0))) end)
	end)
end

function LeaderboardService.fetchLeaderboard(): {LeaderboardEntry}
	if not xpStore then return {} end
	local ok, pages = pcall(function() return xpStore:GetSortedAsync(false, 10) end)
	if not ok or not pages then return cachedLeaderboard end
	local ok2, data = pcall(function() return pages:GetCurrentPage() end)
	if not ok2 or not data then return cachedLeaderboard end

	local ProgressionConfig = require(shared:WaitForChild("ProgressionConfig", 5))
	local result: {LeaderboardEntry} = {}
	for rank, entry in ipairs(data) do
		local userId = tonumber(entry.key) or 0
		local xp = entry.value or 0
		local level = ProgressionConfig.calculateLevel(xp)
		local title = ProgressionConfig.getTitleForLevel(level)
		table.insert(result, {rank = rank, userId = userId, xp = xp, level = level, title = title})
	end
	cachedLeaderboard = result
	return result
end

function LeaderboardService.broadcastLeaderboard()
	local re = getRemote("LeaderboardUpdated")
	if not re then return end
	local data = LeaderboardService.fetchLeaderboard()
	re:FireAllClients(data)
end

-- ===================== MISI HARIAN =====================

export type Mission = {id: string, label: string, description: string, target: number,
	progress: number, completed: boolean, rewardXP: number, rewardCoins: number}

local MISSION_DEFS: {{id: string, label: string, desc: string, target: number, xp: number, coins: number}} = {
	{id = "buy_land",    label = "🏠 Beli Tanah",      desc = "Beli 2 tanah dalam 1 sesi",     target = 2, xp = 50,  coins = 100},
	{id = "pay_rent",    label = "💸 Bayar Sewa",       desc = "Bayar sewa 3 kali",             target = 3, xp = 40,  coins = 75 },
	{id = "roll_dice",   label = "🎲 Lempar Dadu",      desc = "Lempar dadu 5 kali",            target = 5, xp = 30,  coins = 50 },
	{id = "win_match",   label = "🏆 Menangkan Match",  desc = "Menangkan 1 pertandingan",      target = 1, xp = 150, coins = 300},
	{id = "get_salary",  label = "💰 Gaji START",       desc = "Lewati START dan terima gaji 2×",target=2, xp = 35,  coins = 60 },
	{id = "double_roll", label = "🎲🎲 Dadu Kembar",   desc = "Lempar dadu kembar 1 kali",     target = 1, xp = 60,  coins = 120},
	{id = "build_prop",  label = "🏗️ Bangun Properti",  desc = "Bangun 1 bangunan",             target = 1, xp = 70,  coins = 140},
}

local missionState: {[number]: {missions: {Mission}, day: number}} = {}

local function todayStamp(): number
	return math.floor(os.time() / 86400)
end

local function getTemplate(id: string): any?
	for _, t in ipairs(MISSION_DEFS) do if t.id == id then return t end end
	return nil
end

function LeaderboardService.getOrCreateMissions(userId: number): {Mission}
	local today = todayStamp()
	local state = missionState[userId]
	if state and state.day == today then return state.missions end
	-- Pilih 3 misi acak berdasarkan hari (seed deterministik agar semua pemain dapat misi sama)
	local rng = Random.new(today)
	local pool = table.clone(MISSION_DEFS)
	rng:Shuffle(pool)
	local missions: {Mission} = {}
	for i = 1, math.min(3, #pool) do
		local t = pool[i]
		table.insert(missions, {
			id = t.id, label = t.label, description = t.desc,
			target = t.target, progress = 0, completed = false,
			rewardXP = t.xp, rewardCoins = t.coins,
		})
	end
	missionState[userId] = {missions = missions, day = today}
	return missions
end

-- Catat progres misi; kembalikan Mission jika baru diselesaikan, nil jika belum
function LeaderboardService.trackMission(userId: number, missionId: string, amount: number?): Mission?
	local state = missionState[userId]
	if not state then return nil end
	for _, m in ipairs(state.missions) do
		if m.id == missionId and not m.completed then
			m.progress = math.min(m.progress + (amount or 1), m.target)
			if m.progress >= m.target then
				m.completed = true
				return m
			end
		end
	end
	return nil
end

function LeaderboardService.sendMissions(player: Player)
	local re = getRemote("MissionsUpdated")
	if not re then return end
	local missions = LeaderboardService.getOrCreateMissions(player.UserId)
	re:FireClient(player, missions)
end

-- Dipanggil di server loop tiap detik
function LeaderboardService.tick(now: number)
	if now - lastRefresh > REFRESH_INTERVAL then
		lastRefresh = now
		task.spawn(LeaderboardService.broadcastLeaderboard)
	end
end

function LeaderboardService.onPlayerJoin(player: Player)
	task.delay(2, function()
		if player.Parent then
			LeaderboardService.sendMissions(player)
		end
	end)
end

Players.PlayerAdded:Connect(LeaderboardService.onPlayerJoin)

return LeaderboardService
