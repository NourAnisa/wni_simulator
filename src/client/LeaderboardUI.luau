--!strict
-- LeaderboardUI.luau (LocalScript)
-- Panel Leaderboard + Misi Harian: muncul di Lobby, bisa dibuka/tutup.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local Remotes = shared:WaitForChild("Remotes", 10)
if not Remotes then return end
local stateUpdated = Remotes:WaitForChild("StateUpdated", 10)
local lbRemote = Remotes:WaitForChild("LeaderboardUpdated", 15)
local missionsRemote = Remotes:WaitForChild("MissionsUpdated", 15)

-- ─── UI BUILDER ─────────────────────────────────────────────────────────────

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

-- Root ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WNILeaderboardUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = pgui

-- Toggle button (pojok kiri bawah)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "LeaderboardToggle"
toggleBtn.Size = UDim2.new(0, 44, 0, 44)
toggleBtn.Position = UDim2.new(0, 12, 1, -130)
toggleBtn.AnchorPoint = Vector2.new(0, 1)
toggleBtn.BackgroundColor3 = Color3.fromRGB(22, 38, 50)
toggleBtn.TextColor3 = Color3.fromRGB(250, 220, 80)
toggleBtn.Text = "🏆"
toggleBtn.TextSize = 22
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = screenGui
corner(22, toggleBtn)
stroke(Color3.fromRGB(200, 170, 40), 2, toggleBtn)

-- Mission button (di atas toggle)
local missionBtn = Instance.new("TextButton")
missionBtn.Name = "MissionToggle"
missionBtn.Size = UDim2.new(0, 44, 0, 44)
missionBtn.Position = UDim2.new(0, 12, 1, -180)
missionBtn.AnchorPoint = Vector2.new(0, 1)
missionBtn.BackgroundColor3 = Color3.fromRGB(30, 50, 30)
missionBtn.TextColor3 = Color3.fromRGB(100, 230, 130)
missionBtn.Text = "📋"
missionBtn.TextSize = 22
missionBtn.Font = Enum.Font.GothamBold
missionBtn.Parent = screenGui
corner(22, missionBtn)
stroke(Color3.fromRGB(60, 180, 80), 2, missionBtn)

-- Panel utama (tersembunyi awalnya)
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 280, 0, 360)
panel.Position = UDim2.new(0, 62, 1, -360)
panel.AnchorPoint = Vector2.new(0, 1)
panel.BackgroundColor3 = Color3.fromRGB(14, 20, 28)
panel.BackgroundTransparency = 0.08
panel.Visible = false
panel.Parent = screenGui
corner(14, panel)
stroke(Color3.fromRGB(200, 170, 40), 2, panel)

local panelList = Instance.new("UIListLayout")
panelList.SortOrder = Enum.SortOrder.LayoutOrder
panelList.Padding = UDim.new(0, 2)
panelList.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = panel

-- Panel misi
local missionPanel = Instance.new("Frame")
missionPanel.Name = "MissionPanel"
missionPanel.Size = UDim2.new(0, 280, 0, 260)
missionPanel.Position = UDim2.new(0, 62, 1, -260)
missionPanel.AnchorPoint = Vector2.new(0, 1)
missionPanel.BackgroundColor3 = Color3.fromRGB(14, 26, 20)
missionPanel.BackgroundTransparency = 0.08
missionPanel.Visible = false
missionPanel.Parent = screenGui
corner(14, missionPanel)
stroke(Color3.fromRGB(60, 180, 80), 2, missionPanel)

local missionList = Instance.new("UIListLayout")
missionList.SortOrder = Enum.SortOrder.LayoutOrder
missionList.Padding = UDim.new(0, 4)
missionList.Parent = missionPanel
local mPad = Instance.new("UIPadding")
mPad.PaddingLeft = UDim.new(0, 10); mPad.PaddingRight = UDim.new(0, 10)
mPad.PaddingTop = UDim.new(0, 8); mPad.PaddingBottom = UDim.new(0, 8)
mPad.Parent = missionPanel

-- ─── RENDERING ───────────────────────────────────────────────────────────────

local function clearChildren(parent: Instance)
	for _, ch in ipairs(parent:GetChildren()) do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
	end
end

local function renderLeaderboard(data: {any})
	clearChildren(panel)
	label("🏆 TOP PEMAIN", 13, Color3.fromRGB(250, 220, 80), panel).LayoutOrder = 0

	if #data == 0 then
		label("Belum ada data.", 12, Color3.fromRGB(150, 150, 150), panel).LayoutOrder = 1
		return
	end

	for i, entry in ipairs(data) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundColor3 = if i % 2 == 0 then Color3.fromRGB(20, 28, 40) else Color3.fromRGB(25, 35, 48)
		row.BackgroundTransparency = 0.3
		row.LayoutOrder = i
		row.Parent = panel
		corner(6, row)

		local rankColors = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(192, 192, 192), Color3.fromRGB(205, 127, 50)}
		local medals = {"🥇", "🥈", "🥉"}
		local rankEmoji = if i <= 3 then medals[i] else tostring(i)

		local rankL = Instance.new("TextLabel")
		rankL.Size = UDim2.new(0, 28, 1, 0)
		rankL.Text = rankEmoji
		rankL.TextSize = 13
		rankL.TextColor3 = rankColors[i] or Color3.fromRGB(180, 180, 180)
		rankL.BackgroundTransparency = 1
		rankL.Font = Enum.Font.GothamBold
		rankL.Parent = row

		local nameL = Instance.new("TextLabel")
		nameL.Size = UDim2.new(1, -90, 1, 0)
		nameL.Position = UDim2.new(0, 28, 0, 0)
		nameL.Text = entry.title .. " Lv." .. tostring(entry.level)
		nameL.TextSize = 11
		nameL.TextColor3 = Color3.fromRGB(220, 220, 220)
		nameL.BackgroundTransparency = 1
		nameL.Font = Enum.Font.Gotham
		nameL.TextXAlignment = Enum.TextXAlignment.Left
		nameL.TextTruncate = Enum.TextTruncate.AtEnd
		nameL.Parent = row

		local xpL = Instance.new("TextLabel")
		xpL.Size = UDim2.new(0, 70, 1, 0)
		xpL.Position = UDim2.new(1, -70, 0, 0)
		xpL.Text = tostring(entry.xp) .. " XP"
		xpL.TextSize = 11
		xpL.TextColor3 = Color3.fromRGB(100, 220, 255)
		xpL.BackgroundTransparency = 1
		xpL.Font = Enum.Font.GothamBold
		xpL.TextXAlignment = Enum.TextXAlignment.Right
		xpL.Parent = row
	end
end

local function renderMissions(missions: {any})
	clearChildren(missionPanel)
	label("📋 MISI HARIAN", 13, Color3.fromRGB(100, 230, 130), missionPanel).LayoutOrder = 0

	for i, m in ipairs(missions) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 60)
		row.BackgroundColor3 = if m.completed then Color3.fromRGB(20, 50, 20) else Color3.fromRGB(20, 30, 40)
		row.BackgroundTransparency = 0.3
		row.LayoutOrder = i
		row.Parent = missionPanel
		corner(8, row)

		local titleL = Instance.new("TextLabel")
		titleL.Size = UDim2.new(1, -8, 0, 20)
		titleL.Position = UDim2.new(0, 4, 0, 2)
		titleL.Text = m.label .. (if m.completed then " ✅" else "")
		titleL.TextSize = 12
		titleL.TextColor3 = if m.completed then Color3.fromRGB(100, 230, 130) else Color3.fromRGB(230, 230, 230)
		titleL.BackgroundTransparency = 1
		titleL.Font = Enum.Font.GothamBold
		titleL.TextXAlignment = Enum.TextXAlignment.Left
		titleL.Parent = row

		local descL = Instance.new("TextLabel")
		descL.Size = UDim2.new(1, -8, 0, 14)
		descL.Position = UDim2.new(0, 4, 0, 22)
		descL.Text = m.description
		descL.TextSize = 10
		descL.TextColor3 = Color3.fromRGB(160, 160, 160)
		descL.BackgroundTransparency = 1
		descL.Font = Enum.Font.Gotham
		descL.TextXAlignment = Enum.TextXAlignment.Left
		descL.Parent = row

		-- Progress bar
		local barBg = Instance.new("Frame")
		barBg.Size = UDim2.new(1, -8, 0, 8)
		barBg.Position = UDim2.new(0, 4, 0, 38)
		barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		barBg.Parent = row
		corner(4, barBg)

		local prog = math.clamp(m.progress / math.max(m.target, 1), 0, 1)
		local barFill = Instance.new("Frame")
		barFill.Size = UDim2.new(prog, 0, 1, 0)
		barFill.BackgroundColor3 = if m.completed then Color3.fromRGB(80, 200, 100) else Color3.fromRGB(60, 130, 220)
		barFill.Parent = barBg
		corner(4, barFill)

		local progL = Instance.new("TextLabel")
		progL.Size = UDim2.new(0, 60, 0, 14)
		progL.Position = UDim2.new(1, -62, 0, 38)
		progL.Text = tostring(m.progress) .. "/" .. tostring(m.target) .. " · +" .. m.rewardXP .. "XP"
		progL.TextSize = 9
		progL.TextColor3 = Color3.fromRGB(180, 180, 180)
		progL.BackgroundTransparency = 1
		progL.Font = Enum.Font.Gotham
		progL.TextXAlignment = Enum.TextXAlignment.Right
		progL.Parent = row
	end
end

-- ─── TOGGLE LOGIC ────────────────────────────────────────────────────────────

local function tweenVisible(frame: Frame, visible: boolean)
	if visible then
		frame.Visible = true
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.08}):Play()
	else
		local t = TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
		t.Completed:Connect(function() frame.Visible = false; frame.BackgroundTransparency = 0.08 end)
		t:Play()
	end
end

toggleBtn.Activated:Connect(function()
	if missionPanel.Visible then tweenVisible(missionPanel, false) end
	tweenVisible(panel, not panel.Visible)
end)

missionBtn.Activated:Connect(function()
	if panel.Visible then tweenVisible(panel, false) end
	tweenVisible(missionPanel, not missionPanel.Visible)
end)

-- Sembunyikan panel saat match aktif
local function onStateUpdate(payload: any)
	if typeof(payload) ~= "table" then return end
	local inMatch = payload.phase == "Active" or payload.phase == "AwaitRoll"
		or payload.phase == "AwaitBuy" or payload.phase == "AwaitBuild"
		or payload.phase == "AwaitCardChoice"
	toggleBtn.Visible = not inMatch
	missionBtn.Visible = not inMatch
	if inMatch then
		if panel.Visible then tweenVisible(panel, false) end
		if missionPanel.Visible then tweenVisible(missionPanel, false) end
	end
end

stateUpdated.OnClientEvent:Connect(onStateUpdate)

-- ─── REMOTE HANDLERS ─────────────────────────────────────────────────────────

lbRemote.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then return end
	renderLeaderboard(data)
end)

missionsRemote.OnClientEvent:Connect(function(data: any)
	if typeof(data) ~= "table" then return end
	renderMissions(data)
end)
