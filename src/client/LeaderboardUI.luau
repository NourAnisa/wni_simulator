--!strict
-- LeaderboardUI.luau (LocalScript)
-- Panel Terpadu: 🏆 Peringkat, 📋 Misi Harian, 📜 Riwayat Pertandingan, 🏅 Pencapaian
-- Responsive dock di sisi kanan tengah layar, tidak tumpang tindih.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local Remotes = shared:WaitForChild("Remotes", 10)
if not Remotes then return end
local stateUpdated = Remotes:WaitForChild("StateUpdated", 10) :: RemoteEvent
local lbRemote = Remotes:WaitForChild("LeaderboardUpdated", 15) :: RemoteEvent
local missionsRemote = Remotes:WaitForChild("MissionsUpdated", 15) :: RemoteEvent
local achRemote = Remotes:WaitForChild("AchievementUnlocked", 15) :: RemoteEvent?
local requestAction = Remotes:WaitForChild("RequestAction", 10) :: RemoteEvent?

local rulesModule = shared:FindFirstChild("PrototypeRules")
local Rules = if rulesModule and rulesModule:IsA("ModuleScript") then require(rulesModule) else nil
local gameVersion = if Rules then Rules.Version else "1.5.3"
local ProgressionConfig = require(shared:WaitForChild("ProgressionConfig", 5))

-- ─── RESPONSIVE SCREEN GUI ───────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WNILeaderboardUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 12
screenGui.Parent = pgui

local uiScale = Instance.new("UIScale")
uiScale.Name = "InterfaceScale"
uiScale.Parent = screenGui

local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera") :: Camera
local function updateScale()
	local vp = camera.ViewportSize
	if vp.X <= 0 or vp.Y <= 0 then return end
	local target = math.min(vp.X / 1366, vp.Y / 768)
	uiScale.Scale = math.clamp(target, 0.52, 1.25)
end

camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local c = Workspace.CurrentCamera
	if c then
		camera = c
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
		updateScale()
	end
end)
task.spawn(updateScale)

-- ─── UI BUILDER HELPERS ──────────────────────────────────────────────────────

local function corner(r: number, parent: Instance)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
	return c
end

local function stroke(color: Color3, thick: number, parent: Instance)
	local s = Instance.new("UIStroke")
	s.Color = color; s.Thickness = thick; s.Parent = parent
	return s
end

local function label(text: string, size: number, color: Color3, parent: Instance): TextLabel
	local l = Instance.new("TextLabel")
	l.Text = text; l.TextSize = size; l.TextColor3 = color
	l.BackgroundTransparency = 1; l.TextXAlignment = Enum.TextXAlignment.Left
	l.Font = Enum.Font.GothamBold; l.Size = UDim2.new(1, 0, 0, size + 4)
	l.Parent = parent
	return l
end

local function clearChildren(p: Instance)
	for _, ch in ipairs(p:GetChildren()) do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
	end
end

-- ─── SIDEBAR TOGGLE BUTTONS ──────────────────────────────────────────────────

local function makeToggleBtn(name: string, icon: string, yOffset: number, bg: Color3, textCol: Color3, strokeCol: Color3): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 42, 0, 42)
	btn.Position = UDim2.new(1, -12, 0.5, yOffset)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.BackgroundColor3 = bg
	btn.TextColor3 = textCol
	btn.Text = icon
	btn.TextSize = 20
	btn.Font = Enum.Font.GothamBold
	btn.Parent = screenGui
	corner(21, btn)
	stroke(strokeCol, 2, btn)
	return btn
end

local toggleBtn = makeToggleBtn("LeaderboardToggle", "🏆", -125, Color3.fromRGB(22, 38, 50), Color3.fromRGB(250, 220, 80), Color3.fromRGB(200, 170, 40))
local missionBtn = makeToggleBtn("MissionToggle", "📋", -75, Color3.fromRGB(30, 50, 30), Color3.fromRGB(100, 230, 130), Color3.fromRGB(60, 180, 80))
local streakBtn = makeToggleBtn("StreakToggle", "📅", -25, Color3.fromRGB(18, 40, 50), Color3.fromRGB(100, 220, 255), Color3.fromRGB(40, 160, 200))
local shopBtn = makeToggleBtn("ShopToggle", "🛍️", 25, Color3.fromRGB(45, 32, 18), Color3.fromRGB(255, 190, 80), Color3.fromRGB(220, 140, 40))
local historyBtn = makeToggleBtn("HistoryToggle", "📜", 75, Color3.fromRGB(35, 30, 55), Color3.fromRGB(200, 170, 255), Color3.fromRGB(140, 110, 220))
local achBtn = makeToggleBtn("AchievementToggle", "🏅", 125, Color3.fromRGB(50, 35, 22), Color3.fromRGB(255, 180, 90), Color3.fromRGB(220, 130, 40))

local streakBadge = Instance.new("TextLabel")
streakBadge.Name = "Badge"
streakBadge.Size = UDim2.new(0, 16, 0, 16)
streakBadge.Position = UDim2.new(1, -2, 0, -2)
streakBadge.AnchorPoint = Vector2.new(0.5, 0.5)
streakBadge.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
streakBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
streakBadge.Text = "!"
streakBadge.TextSize = 11
streakBadge.Font = Enum.Font.GothamBold
streakBadge.Visible = false
streakBadge.Parent = streakBtn
corner(8, streakBadge)
stroke(Color3.fromRGB(255, 255, 255), 1.5, streakBadge)

-- ─── DOCK PANELS ─────────────────────────────────────────────────────────────

local function makePanel(name: string, bg: Color3, strokeCol: Color3, h: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = UDim2.new(0, 295, 0, h)
	f.Position = UDim2.new(1, -62, 0.5, 0)
	f.AnchorPoint = Vector2.new(1, 0.5)
	f.BackgroundColor3 = bg
	f.BackgroundTransparency = 0.05
	f.Visible = false
	f.Parent = screenGui
	corner(16, f)
	stroke(strokeCol, 2, f)
	return f
end

local lbPanel = makePanel("LeaderboardPanel", Color3.fromRGB(14, 20, 32), Color3.fromRGB(200, 170, 40), 340)
local missionPanel = makePanel("MissionPanel", Color3.fromRGB(14, 28, 22), Color3.fromRGB(60, 180, 80), 280)
local streakPanel = makePanel("StreakPanel", Color3.fromRGB(16, 26, 36), Color3.fromRGB(40, 160, 200), 340)
local shopPanel = makePanel("ShopPanel", Color3.fromRGB(26, 18, 16), Color3.fromRGB(220, 140, 40), 350)
local historyPanel = makePanel("HistoryPanel", Color3.fromRGB(20, 16, 32), Color3.fromRGB(140, 110, 220), 310)
local achPanel = makePanel("AchievementPanel", Color3.fromRGB(28, 20, 14), Color3.fromRGB(220, 130, 40), 320)

local allPanels = {lbPanel, missionPanel, streakPanel, shopPanel, historyPanel, achPanel}

for _, p in ipairs(allPanels) do
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = p
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = p
end

-- ─── RENDERING: 1. LEADERBOARD ───────────────────────────────────────────────

local function renderLeaderboard(data: {any})
	clearChildren(lbPanel)
	label("🏆 TOP PEMAIN", 13, Color3.fromRGB(250, 220, 80), lbPanel).LayoutOrder = 0

	if #data == 0 then
		label("Belum ada data.", 12, Color3.fromRGB(150, 150, 150), lbPanel).LayoutOrder = 1
		return
	end

	for i, entry in ipairs(data) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 30)
		row.BackgroundColor3 = if i % 2 == 0 then Color3.fromRGB(20, 28, 40) else Color3.fromRGB(25, 35, 48)
		row.BackgroundTransparency = 0.3
		row.LayoutOrder = i
		row.Parent = lbPanel
		corner(6, row)

		local rankColors = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(192, 192, 192), Color3.fromRGB(205, 127, 50)}
		local medals = {"🥇", "🥈", "🥉"}
		local rankEmoji = if i <= 3 then medals[i] else tostring(i)

		local rankL = Instance.new("TextLabel")
		rankL.Size = UDim2.new(0, 26, 1, 0)
		rankL.Text = rankEmoji
		rankL.TextSize = 12
		rankL.TextColor3 = rankColors[i] or Color3.fromRGB(180, 180, 180)
		rankL.BackgroundTransparency = 1
		rankL.Font = Enum.Font.GothamBold
		rankL.Parent = row

		local nameL = Instance.new("TextLabel")
		nameL.Size = UDim2.new(1, -86, 1, 0)
		nameL.Position = UDim2.new(0, 26, 0, 0)
		nameL.Text = entry.title .. " Lv." .. tostring(entry.level)
		nameL.TextSize = 11
		nameL.TextColor3 = Color3.fromRGB(220, 220, 220)
		nameL.BackgroundTransparency = 1
		nameL.Font = Enum.Font.Gotham
		nameL.TextXAlignment = Enum.TextXAlignment.Left
		nameL.TextTruncate = Enum.TextTruncate.AtEnd
		nameL.Parent = row

		local xpL = Instance.new("TextLabel")
		xpL.Size = UDim2.new(0, 60, 1, 0)
		xpL.Position = UDim2.new(1, -64, 0, 0)
		xpL.Text = tostring(entry.xp) .. " XP"
		xpL.TextSize = 10
		xpL.TextColor3 = Color3.fromRGB(100, 220, 255)
		xpL.BackgroundTransparency = 1
		xpL.Font = Enum.Font.GothamBold
		xpL.TextXAlignment = Enum.TextXAlignment.Right
		xpL.Parent = row
	end
end

-- ─── RENDERING: 2. MISI HARIAN ───────────────────────────────────────────────

local function renderMissions(missions: {any})
	clearChildren(missionPanel)
	label("📋 MISI HARIAN", 13, Color3.fromRGB(100, 230, 130), missionPanel).LayoutOrder = 0

	for i, m in ipairs(missions) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 58)
		row.BackgroundColor3 = if m.completed then Color3.fromRGB(20, 50, 20) else Color3.fromRGB(20, 30, 40)
		row.BackgroundTransparency = 0.3
		row.LayoutOrder = i
		row.Parent = missionPanel
		corner(8, row)

		local titleL = Instance.new("TextLabel")
		titleL.Size = UDim2.new(1, -8, 0, 18)
		titleL.Position = UDim2.new(0, 4, 0, 2)
		titleL.Text = m.label .. (if m.completed then " ✅" else "")
		titleL.TextSize = 11
		titleL.TextColor3 = if m.completed then Color3.fromRGB(100, 230, 130) else Color3.fromRGB(230, 230, 230)
		titleL.BackgroundTransparency = 1
		titleL.Font = Enum.Font.GothamBold
		titleL.TextXAlignment = Enum.TextXAlignment.Left
		titleL.Parent = row

		local descL = Instance.new("TextLabel")
		descL.Size = UDim2.new(1, -8, 0, 14)
		descL.Position = UDim2.new(0, 4, 0, 20)
		descL.Text = m.description
		descL.TextSize = 9
		descL.TextColor3 = Color3.fromRGB(160, 160, 160)
		descL.BackgroundTransparency = 1
		descL.Font = Enum.Font.Gotham
		descL.TextXAlignment = Enum.TextXAlignment.Left
		descL.Parent = row

		local barBg = Instance.new("Frame")
		barBg.Size = UDim2.new(1, -8, 0, 8)
		barBg.Position = UDim2.new(0, 4, 0, 38)
		barBg.BackgroundColor3 = Color3.fromRGB(30, 40, 50)
		barBg.Parent = row
		corner(4, barBg)

		local pct = math.clamp(m.progress / math.max(m.target, 1), 0, 1)
		local barFill = Instance.new("Frame")
		barFill.Size = UDim2.new(pct, 0, 1, 0)
		barFill.BackgroundColor3 = if m.completed then Color3.fromRGB(80, 220, 100) else Color3.fromRGB(80, 160, 240)
		barFill.Parent = barBg
		corner(4, barFill)

		local progL = Instance.new("TextLabel")
		progL.Size = UDim2.new(1, -12, 0, 12)
		progL.Position = UDim2.new(0, 4, 0, 44)
		progL.Text = tostring(m.progress) .. "/" .. tostring(m.target) .. "  •  +" .. tostring(m.rewardXP) .. " XP"
		progL.TextSize = 8
		progL.TextColor3 = Color3.fromRGB(180, 180, 180)
		progL.BackgroundTransparency = 1
		progL.Font = Enum.Font.Gotham
		progL.TextXAlignment = Enum.TextXAlignment.Right
		progL.Parent = row
	end
end

-- ─── RENDERING: 3. RIWAYAT PERTANDINGAN (MATCH HISTORY) ──────────────────────

local function renderHistory(history: {any})
	clearChildren(historyPanel)
	label("📜 RIWAYAT PERTANDINGAN", 13, Color3.fromRGB(200, 170, 255), historyPanel).LayoutOrder = 0

	if not history or #history == 0 then
		label("Belum ada riwayat tanding.", 11, Color3.fromRGB(160, 160, 180), historyPanel).LayoutOrder = 1
		return
	end

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "HistoryScroll"
	scroll.Size = UDim2.new(1, 0, 1, -26)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Color3.fromRGB(180, 150, 240)
	scroll.CanvasSize = UDim2.new(0, 0, 0, #history * 52)
	scroll.LayoutOrder = 1
	scroll.Parent = historyPanel

	local sList = Instance.new("UIListLayout")
	sList.Padding = UDim.new(0, 4)
	sList.Parent = scroll

	for i, item in ipairs(history) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -4, 0, 48)
		local isWin = item.outcome == "win"
		local isLoss = item.outcome == "loss"
		row.BackgroundColor3 = if isWin then Color3.fromRGB(20, 45, 30) elseif isLoss then Color3.fromRGB(45, 20, 25) else Color3.fromRGB(35, 35, 20)
		row.BackgroundTransparency = 0.2
		row.Parent = scroll
		corner(8, row)

		local badge = Instance.new("TextLabel")
		badge.Size = UDim2.new(0, 68, 0, 20)
		badge.Position = UDim2.new(0, 6, 0, 6)
		badge.BackgroundColor3 = if isWin then Color3.fromRGB(35, 120, 65) elseif isLoss then Color3.fromRGB(140, 40, 45) else Color3.fromRGB(120, 100, 30)
		badge.Text = if isWin then "MENANG" elseif isLoss then "KALAH" else "SERI"
		badge.TextColor3 = Color3.fromRGB(255, 255, 255)
		badge.TextSize = 10
		badge.Font = Enum.Font.GothamBold
		badge.Parent = row
		corner(4, badge)

		local xpL = Instance.new("TextLabel")
		xpL.Size = UDim2.new(0, 100, 0, 20)
		xpL.Position = UDim2.new(1, -106, 0, 6)
		xpL.Text = "+" .. tostring(item.xpGain or 0) .. " XP  •  +" .. tostring(item.coinGain or 0) .. " 🪙"
		xpL.TextColor3 = Color3.fromRGB(255, 220, 100)
		xpL.TextSize = 10
		xpL.Font = Enum.Font.GothamBold
		xpL.TextXAlignment = Enum.TextXAlignment.Right
		xpL.BackgroundTransparency = 1
		xpL.Parent = row

		local sumL = Instance.new("TextLabel")
		sumL.Size = UDim2.new(1, -12, 0, 16)
		sumL.Position = UDim2.new(0, 6, 0, 28)
		local summaryText = tostring(item.summary or "")
		sumL.Text = if #summaryText > 0 then summaryText else ("Match #" .. string.sub(tostring(item.matchId), 1, 8))
		sumL.TextColor3 = Color3.fromRGB(180, 180, 200)
		sumL.TextSize = 9
		sumL.Font = Enum.Font.Gotham
		sumL.TextXAlignment = Enum.TextXAlignment.Left
		sumL.TextTruncate = Enum.TextTruncate.AtEnd
		sumL.BackgroundTransparency = 1
		sumL.Parent = row
	end
end

-- ─── RENDERING: 4. PENCAPAIAN (ACHIEVEMENTS) ──────────────────────────────────

local ACHIEVEMENTS_LIST = {
	{id = "first_match",      name = "Langkah Perdana",    desc = "Mainkan 1 match sampai selesai",   xp = 100, coins = 200, icon = "🏁"},
	{id = "first_win",        name = "Kemenangan Perdana", desc = "Menangkan 1 pertandingan",          xp = 150, coins = 300, icon = "🏆"},
	{id = "monopoly_king",    name = "Sultan Monopoli",    desc = "Bentuk monopoli 1 pulau penuh",     xp = 250, coins = 500, icon = "👑"},
	{id = "escape_jail",      name = "Bebas dari LAPAS",   desc = "Keluar LAPAS dengan dadu kembar",   xp = 100, coins = 200, icon = "🔓"},
	{id = "survive_bankrupt", name = "Hoki Selamat",       desc = "Menang saat kas < Rp1.000.000",     xp = 200, coins = 400, icon = "🍀"},
	{id = "card_master",      name = "Taktik Kartu",       desc = "Gunakan kartu simpanan dari tangan",xp = 100, coins = 200, icon = "🃏"},
	{id = "land_tycoon",      name = "Juragan Tanah",      desc = "Miliki 4 tanah secara bersamaan",   xp = 200, coins = 400, icon = "🏘️"},
	{id = "ten_matches",      name = "Warga Teladan",      desc = "Mainkan 10 pertandingan",          xp = 300, coins = 600, icon = "⭐"},
}

local function renderAchievements(userAchs: {[string]: any})
	clearChildren(achPanel)
	label("🏅 PENCAPAIAN NUSANTARA", 13, Color3.fromRGB(255, 180, 90), achPanel).LayoutOrder = 0

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "AchScroll"
	scroll.Size = UDim2.new(1, 0, 1, -26)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Color3.fromRGB(240, 160, 60)
	scroll.CanvasSize = UDim2.new(0, 0, 0, #ACHIEVEMENTS_LIST * 48)
	scroll.LayoutOrder = 1
	scroll.Parent = achPanel

	local sList = Instance.new("UIListLayout")
	sList.Padding = UDim.new(0, 4)
	sList.Parent = scroll

	for i, ach in ipairs(ACHIEVEMENTS_LIST) do
		local userItem = userAchs and userAchs[ach.id]
		local isUnlocked = userItem ~= nil and userItem.unlocked == true

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -4, 0, 44)
		row.BackgroundColor3 = if isUnlocked then Color3.fromRGB(45, 34, 18) else Color3.fromRGB(28, 24, 24)
		row.BackgroundTransparency = 0.2
		row.Parent = scroll
		corner(8, row)

		local iconL = Instance.new("TextLabel")
		iconL.Size = UDim2.new(0, 32, 1, 0)
		iconL.Text = ach.icon
		iconL.TextSize = 18
		iconL.BackgroundTransparency = 1
		iconL.Parent = row

		local nameL = Instance.new("TextLabel")
		nameL.Size = UDim2.new(1, -110, 0, 16)
		nameL.Position = UDim2.new(0, 34, 0, 4)
		nameL.Text = ach.name
		nameL.TextColor3 = if isUnlocked then Color3.fromRGB(255, 215, 120) else Color3.fromRGB(180, 180, 180)
		nameL.TextSize = 11
		nameL.Font = Enum.Font.GothamBold
		nameL.TextXAlignment = Enum.TextXAlignment.Left
		nameL.BackgroundTransparency = 1
		nameL.Parent = row

		local descL = Instance.new("TextLabel")
		descL.Size = UDim2.new(1, -110, 0, 14)
		descL.Position = UDim2.new(0, 34, 0, 22)
		descL.Text = ach.desc
		descL.TextColor3 = Color3.fromRGB(140, 140, 140)
		descL.TextSize = 8
		descL.Font = Enum.Font.Gotham
		descL.TextXAlignment = Enum.TextXAlignment.Left
		descL.TextTruncate = Enum.TextTruncate.AtEnd
		descL.BackgroundTransparency = 1
		descL.Parent = row

		local statusBadge = Instance.new("TextLabel")
		statusBadge.Size = UDim2.new(0, 68, 0, 20)
		statusBadge.Position = UDim2.new(1, -74, 0.5, -10)
		statusBadge.BackgroundColor3 = if isUnlocked then Color3.fromRGB(40, 130, 60) else Color3.fromRGB(50, 45, 45)
		statusBadge.Text = if isUnlocked then "✅ SELESAI" else "🔒 TERKUNCI"
		statusBadge.TextColor3 = if isUnlocked then Color3.fromRGB(240, 255, 240) else Color3.fromRGB(160, 160, 160)
		statusBadge.TextSize = 9
		statusBadge.Font = Enum.Font.GothamBold
		statusBadge.Parent = row
		corner(4, statusBadge)
	end
end

-- ─── RENDERING: 5. DAILY STREAK ──────────────────────────────────────────────

local STREAK_REWARDS_DATA = {
	{day = 1, coins = 150, xp = 50},
	{day = 2, coins = 250, xp = 75},
	{day = 3, coins = 400, xp = 100},
	{day = 4, coins = 600, xp = 125},
	{day = 5, coins = 800, xp = 150},
	{day = 6, coins = 1200, xp = 200},
	{day = 7, coins = 2500, xp = 350, jackpot = true},
}

local function renderStreak(streakInfo: any)
	clearChildren(streakPanel)
	if typeof(streakInfo) ~= "table" then return end

	local streakDays = streakInfo.streakDays or 0
	local canClaim = streakInfo.canClaim == true
	local nextStreak = streakInfo.nextStreak or 1
	local nextReward = streakInfo.nextReward or STREAK_REWARDS_DATA[nextStreak] or STREAK_REWARDS_DATA[1]

	local head = label("📅 LOGIN HARIAN (STREAK)", 13, Color3.fromRGB(100, 220, 255), streakPanel)
	head.LayoutOrder = 0

	local sub = Instance.new("TextLabel")
	sub.Text = "🔥 Streak: " .. tostring(streakDays) .. " Hari Berturut-turut"
	sub.TextSize = 10
	sub.TextColor3 = Color3.fromRGB(255, 200, 100)
	sub.Font = Enum.Font.GothamBold
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.new(1, 0, 0, 14)
	sub.LayoutOrder = 1
	sub.Parent = streakPanel

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "StreakScroll"
	scroll.Size = UDim2.new(1, 0, 1, -84)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 200, 255)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 7 * 37)
	scroll.LayoutOrder = 2
	scroll.Parent = streakPanel

	local sList = Instance.new("UIListLayout")
	sList.Padding = UDim.new(0, 3)
	sList.Parent = scroll

	for dayIdx, reward in ipairs(STREAK_REWARDS_DATA) do
		local isClaimed = not canClaim and dayIdx <= streakDays
		local isCurrent = canClaim and dayIdx == nextStreak
		local isLocked = dayIdx > (if canClaim then nextStreak else streakDays)

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -4, 0, 33)
		row.BackgroundColor3 = if isCurrent then Color3.fromRGB(24, 52, 64)
			elseif isClaimed then Color3.fromRGB(20, 38, 28)
			else Color3.fromRGB(24, 24, 30)
		row.BackgroundTransparency = 0.2
		row.Parent = scroll
		corner(6, row)
		if isCurrent then
			stroke(Color3.fromRGB(255, 215, 60), 1.5, row)
		end

		local dayL = Instance.new("TextLabel")
		dayL.Size = UDim2.new(0, 62, 1, 0)
		dayL.Position = UDim2.new(0, 8, 0, 0)
		dayL.Text = "HARI " .. tostring(dayIdx) .. (if reward.jackpot then " 🎁" else "")
		dayL.TextColor3 = if isCurrent then Color3.fromRGB(255, 230, 120) elseif isClaimed then Color3.fromRGB(140, 230, 160) else Color3.fromRGB(180, 180, 180)
		dayL.TextSize = 10
		dayL.Font = Enum.Font.GothamBold
		dayL.TextXAlignment = Enum.TextXAlignment.Left
		dayL.BackgroundTransparency = 1
		dayL.Parent = row

		local rewardL = Instance.new("TextLabel")
		rewardL.Size = UDim2.new(1, -145, 1, 0)
		rewardL.Position = UDim2.new(0, 72, 0, 0)
		rewardL.Text = "+" .. tostring(reward.coins) .. " 🪙  +" .. tostring(reward.xp) .. " XP"
		rewardL.TextColor3 = Color3.fromRGB(255, 255, 255)
		rewardL.TextSize = 9
		rewardL.Font = Enum.Font.Gotham
		rewardL.TextXAlignment = Enum.TextXAlignment.Left
		rewardL.BackgroundTransparency = 1
		rewardL.Parent = row

		local statusL = Instance.new("TextLabel")
		statusL.Size = UDim2.new(0, 66, 0, 18)
		statusL.Position = UDim2.new(1, -72, 0.5, -9)
		statusL.BackgroundColor3 = if isCurrent then Color3.fromRGB(220, 160, 20)
			elseif isClaimed then Color3.fromRGB(35, 120, 60)
			else Color3.fromRGB(45, 45, 50)
		statusL.Text = if isCurrent then "⭐ KLAIM" elseif isClaimed then "✅ SELESAI" else "🔒 NANTI"
		statusL.TextColor3 = Color3.fromRGB(255, 255, 255)
		statusL.TextSize = 8
		statusL.Font = Enum.Font.GothamBold
		statusL.Parent = row
		corner(4, statusL)
	end

	-- Tombol Klaim Hadiah
	local claimBtn = Instance.new("TextButton")
	claimBtn.Name = "ClaimBtn"
	claimBtn.Size = UDim2.new(1, 0, 0, 32)
	claimBtn.LayoutOrder = 3
	claimBtn.BackgroundColor3 = if canClaim then Color3.fromRGB(35, 150, 75) else Color3.fromRGB(45, 50, 58)
	claimBtn.Text = if canClaim then ("🎁 KLAIM HARI INI (+" .. tostring(nextReward.coins) .. " 🪙)") else "✅ SUDAH DIKLAIM HARI INI"
	claimBtn.TextColor3 = if canClaim then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(150, 150, 150)
	claimBtn.TextSize = 11
	claimBtn.Font = Enum.Font.GothamBold
	claimBtn.Parent = streakPanel
	corner(8, claimBtn)
	if canClaim then
		stroke(Color3.fromRGB(100, 255, 140), 1.5, claimBtn)
	end

	claimBtn.Activated:Connect(function()
		if not canClaim then return end
		if requestAction then
			requestAction:FireServer("ClaimDailyStreak", 0, gameVersion, nil)
			claimBtn.Text = "⏳ MEMPROSES..."
			claimBtn.Active = false
		end
	end)
end

-- ─── RENDERING: 6. TOKO KOSMETIK NUSANTARA ────────────────────────────────────

local function renderShop(profile: any)
	clearChildren(shopPanel)
	if typeof(profile) ~= "table" then return end

	local coins = profile.coins or 0
	local level = profile.level or 1
	local currentSkin = profile.diceSkin or "Classic"
	local unlockedSkins = profile.unlockedSkins or {Classic = true}

	local head = label("🛍️ TOKO KOSMETIK DADU", 13, Color3.fromRGB(255, 195, 70), shopPanel)
	head.LayoutOrder = 0

	-- Info Saldo
	local balBar = Instance.new("Frame")
	balBar.Size = UDim2.new(1, 0, 0, 24)
	balBar.BackgroundColor3 = Color3.fromRGB(38, 26, 16)
	balBar.LayoutOrder = 1
	balBar.Parent = shopPanel
	corner(6, balBar)

	local coinIcon = Instance.new("TextLabel")
	coinIcon.Size = UDim2.new(1, -12, 1, 0)
	coinIcon.Position = UDim2.new(0, 8, 0, 0)
	coinIcon.Text = "🪙 Saldo: " .. tostring(coins) .. " Koin  •  ⭐ Level " .. tostring(level)
	coinIcon.TextColor3 = Color3.fromRGB(255, 230, 130)
	coinIcon.TextSize = 10
	coinIcon.Font = Enum.Font.GothamBold
	coinIcon.TextXAlignment = Enum.TextXAlignment.Left
	coinIcon.BackgroundTransparency = 1
	coinIcon.Parent = balBar

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "ShopScroll"
	scroll.Size = UDim2.new(1, 0, 1, -66)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 190, 80)
	scroll.CanvasSize = UDim2.new(0, 0, 0, #ProgressionConfig.SKIN_ORDER * 52)
	scroll.LayoutOrder = 2
	scroll.Parent = shopPanel

	local sList = Instance.new("UIListLayout")
	sList.Padding = UDim.new(0, 4)
	sList.Parent = scroll

	for _, key in ipairs(ProgressionConfig.SKIN_ORDER) do
		local skin = ProgressionConfig.DICE_SKINS[key]
		if not skin then continue end

		local isEquipped = key == currentSkin
		local isOwned = unlockedSkins[key] == true
		local isLevelLocked = level < skin.RequiredLevel
		local canAfford = coins >= skin.Price

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -4, 0, 48)
		row.BackgroundColor3 = if isEquipped then Color3.fromRGB(28, 48, 36)
			elseif isOwned then Color3.fromRGB(34, 30, 42)
			elseif isLevelLocked then Color3.fromRGB(24, 22, 24)
			else Color3.fromRGB(38, 30, 24)
		row.BackgroundTransparency = 0.15
		row.Parent = scroll
		corner(6, row)
		if isEquipped then
			stroke(Color3.fromRGB(100, 240, 140), 1.5, row)
		end

		local iconL = Instance.new("TextLabel")
		iconL.Size = UDim2.new(0, 34, 1, 0)
		iconL.Text = skin.Icon or "🎲"
		iconL.TextSize = 20
		iconL.BackgroundTransparency = 1
		iconL.Parent = row

		local nameL = Instance.new("TextLabel")
		nameL.Size = UDim2.new(1, -125, 0, 16)
		nameL.Position = UDim2.new(0, 36, 0, 6)
		nameL.Text = skin.Name .. " (Lv." .. skin.RequiredLevel .. ")"
		nameL.TextColor3 = if isEquipped then Color3.fromRGB(140, 245, 170) elseif isOwned then Color3.fromRGB(220, 210, 240) else Color3.fromRGB(255, 230, 160)
		nameL.TextSize = 10
		nameL.Font = Enum.Font.GothamBold
		nameL.TextXAlignment = Enum.TextXAlignment.Left
		nameL.BackgroundTransparency = 1
		nameL.Parent = row

		local descL = Instance.new("TextLabel")
		descL.Size = UDim2.new(1, -125, 0, 14)
		descL.Position = UDim2.new(0, 36, 0, 24)
		descL.Text = skin.Desc or ""
		descL.TextColor3 = Color3.fromRGB(150, 150, 150)
		descL.TextSize = 8
		descL.Font = Enum.Font.Gotham
		descL.TextXAlignment = Enum.TextXAlignment.Left
		descL.TextTruncate = Enum.TextTruncate.AtEnd
		descL.BackgroundTransparency = 1
		descL.Parent = row

		-- Action Button: Beli / Pasang / Digunakan
		local actBtn = Instance.new("TextButton")
		actBtn.Size = UDim2.new(0, 78, 0, 26)
		actBtn.Position = UDim2.new(1, -84, 0.5, -13)
		actBtn.Font = Enum.Font.GothamBold
		actBtn.TextSize = 9
		actBtn.Parent = row
		corner(5, actBtn)

		if isEquipped then
			actBtn.Text = "✅ DIPAKAI"
			actBtn.BackgroundColor3 = Color3.fromRGB(35, 120, 60)
			actBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			actBtn.Active = false
		elseif isOwned then
			actBtn.Text = "PASANG"
			actBtn.BackgroundColor3 = Color3.fromRGB(40, 95, 150)
			actBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			actBtn.Activated:Connect(function()
				if requestAction then
					requestAction:FireServer("SetDiceSkin", skin.Name, key)
				end
			end)
		elseif isLevelLocked then
			actBtn.Text = "🔒 LV." .. skin.RequiredLevel
			actBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
			actBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
			actBtn.Active = false
		else
			actBtn.Text = "🛒 " .. tostring(skin.Price) .. " 🪙"
			actBtn.BackgroundColor3 = if canAfford then Color3.fromRGB(190, 130, 30) else Color3.fromRGB(60, 50, 45)
			actBtn.TextColor3 = if canAfford then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(160, 150, 140)
			if canAfford then
				actBtn.Activated:Connect(function()
					if requestAction then
						requestAction:FireServer("BuyDiceSkin", 0, gameVersion, key)
						actBtn.Text = "⏳ MEMBELI..."
						actBtn.Active = false
					end
				end)
			end
		end
	end
end

-- ─── POPUP NOTIFIKASI PENCAPAIAN DIBUKA ───────────────────────────────────────

local function showAchievementToast(ach: any)
	local toast = Instance.new("Frame")
	toast.Name = "AchToast"
	toast.Size = UDim2.new(0, 280, 0, 64)
	toast.Position = UDim2.new(0.5, -140, 0, -80)
	toast.BackgroundColor3 = Color3.fromRGB(22, 28, 44)
	toast.Parent = screenGui
	corner(14, toast)
	stroke(Color3.fromRGB(255, 215, 60), 2.5, toast)

	local iconL = Instance.new("TextLabel")
	iconL.Size = UDim2.new(0, 46, 1, 0)
	iconL.Text = ach.icon or "🏅"
	iconL.TextSize = 28
	iconL.BackgroundTransparency = 1
	iconL.Parent = toast

	local titleL = Instance.new("TextLabel")
	titleL.Size = UDim2.new(1, -54, 0, 18)
	titleL.Position = UDim2.new(0, 48, 0, 8)
	titleL.Text = "PENCAPAIAN TERBUKA! 🌟"
	titleL.TextColor3 = Color3.fromRGB(255, 215, 60)
	titleL.TextSize = 11
	titleL.Font = Enum.Font.GothamBold
	titleL.TextXAlignment = Enum.TextXAlignment.Left
	titleL.BackgroundTransparency = 1
	titleL.Parent = toast

	local nameL = Instance.new("TextLabel")
	nameL.Size = UDim2.new(1, -54, 0, 16)
	nameL.Position = UDim2.new(0, 48, 0, 26)
	nameL.Text = ach.name .. "  (+" .. tostring(ach.xp) .. " XP, +" .. tostring(ach.coins) .. " 🪙)"
	nameL.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameL.TextSize = 10
	nameL.Font = Enum.Font.GothamBold
	nameL.TextXAlignment = Enum.TextXAlignment.Left
	nameL.BackgroundTransparency = 1
	nameL.Parent = toast

	-- Slide In
	TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -140, 0, 24)
	}):Play()

	-- Suara Ding
	local s = Instance.new("Sound")
	s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	s.Volume = 0.5
	s.Parent = screenGui
	s:Play()
	game:GetService("Debris"):AddItem(s, 1.5)

	task.delay(3.5, function()
		if toast.Parent then
			local out = TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, -140, 0, -80)
			})
			out.Completed:Connect(function() toast:Destroy() end)
			out:Play()
		end
	end)
end

if achRemote then
	achRemote.OnClientEvent:Connect(function(achData: any)
		if typeof(achData) == "table" then
			showAchievementToast(achData)
		end
	end)
end

-- ─── TOGGLE LOGIC & MUTUAL EXCLUSION ─────────────────────────────────────────

local function togglePanel(target: Frame)
	local isCurrentlyOpen = target.Visible
	for _, p in ipairs(allPanels) do
		if p.Visible then
			local t = TweenService:Create(p, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
			t.Completed:Connect(function() p.Visible = false; p.BackgroundTransparency = 0.05 end)
			t:Play()
		end
	end
	if not isCurrentlyOpen then
		target.Visible = true
		target.BackgroundTransparency = 1
		TweenService:Create(target, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.05}):Play()
	end
end

toggleBtn.Activated:Connect(function() togglePanel(lbPanel) end)
missionBtn.Activated:Connect(function() togglePanel(missionPanel) end)
streakBtn.Activated:Connect(function() togglePanel(streakPanel) end)
shopBtn.Activated:Connect(function() togglePanel(shopPanel) end)
historyBtn.Activated:Connect(function() togglePanel(historyPanel) end)
achBtn.Activated:Connect(function() togglePanel(achPanel) end)

-- ─── STATE LISTENER ──────────────────────────────────────────────────────────

local function onStateUpdate(payload: any)
	if typeof(payload) ~= "table" then return end
	local inMatch = payload.phase == "Active" or payload.phase == "AwaitRoll"
		or payload.phase == "AwaitBuy" or payload.phase == "AwaitBuild"
		or payload.phase == "AwaitCardChoice"

	toggleBtn.Visible = not inMatch
	missionBtn.Visible = not inMatch
	streakBtn.Visible = not inMatch
	shopBtn.Visible = not inMatch
	historyBtn.Visible = not inMatch
	achBtn.Visible = not inMatch

	if inMatch then
		for _, p in ipairs(allPanels) do
			if p.Visible then p.Visible = false end
		end
	end

	-- Render History, Achievements, Daily Streak & Toko Kosmetik
	if typeof(payload.profile) == "table" then
		if typeof(payload.profile.matchHistory) == "table" then
			renderHistory(payload.profile.matchHistory)
		end
		if typeof(payload.profile.achievements) == "table" then
			renderAchievements(payload.profile.achievements)
		end
		if typeof(payload.profile.dailyStreak) == "table" then
			renderStreak(payload.profile.dailyStreak)
			streakBadge.Visible = payload.profile.dailyStreak.canClaim == true
		end
		renderShop(payload.profile)
	end
end

stateUpdated.OnClientEvent:Connect(onStateUpdate)

lbRemote.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then return end
	renderLeaderboard(data)
end)

missionsRemote.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then return end
	renderMissions(data)
end)
