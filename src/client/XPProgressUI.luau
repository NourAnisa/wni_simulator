--!strict
-- XPProgressUI.luau (LocalScript)
-- Bar XP + level + gelar mini di pojok kiri atas layar.
-- Update real-time dari snapshot.profile pemain.

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
local ProgressionConfig = require(shared:WaitForChild("ProgressionConfig", 5))

-- ─── BUILD UI ────────────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WNIXPProgressUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 5
screenGui.Parent = pgui

-- Pill container kiri atas
local pill = Instance.new("Frame")
pill.Name = "XPPill"
pill.Size = UDim2.new(0, 230, 0, 52)
pill.Position = UDim2.new(0, 12, 0, 12)
pill.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
pill.BackgroundTransparency = 0.15
pill.Parent = screenGui

local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 26); pc.Parent = pill
local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(90, 180, 255); ps.Thickness = 2; ps.Parent = pill

-- Level badge (kiri)
local lvlBadge = Instance.new("Frame")
lvlBadge.Size = UDim2.new(0, 44, 0, 44)
lvlBadge.Position = UDim2.new(0, 4, 0.5, 0)
lvlBadge.AnchorPoint = Vector2.new(0, 0.5)
lvlBadge.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
lvlBadge.Parent = pill
local lbc = Instance.new("UICorner"); lbc.CornerRadius = UDim.new(0, 22); lbc.Parent = lvlBadge

local lvlLabel = Instance.new("TextLabel")
lvlLabel.Name = "LvLabel"
lvlLabel.Size = UDim2.new(1, 0, 1, 0)
lvlLabel.Text = "1"
lvlLabel.TextSize = 18; lvlLabel.Font = Enum.Font.GothamBold
lvlLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
lvlLabel.BackgroundTransparency = 1
lvlLabel.Parent = lvlBadge

-- Info kanan
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(1, -56, 1, 0)
infoFrame.Position = UDim2.new(0, 52, 0, 0)
infoFrame.BackgroundTransparency = 1
infoFrame.Parent = pill

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -4, 0, 18)
titleLabel.Position = UDim2.new(0, 0, 0, 5)
titleLabel.Text = "Warga Biasa"
titleLabel.TextSize = 12; titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextColor3 = Color3.fromRGB(220, 200, 90)
titleLabel.BackgroundTransparency = 1; titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = infoFrame

-- XP bar background
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -6, 0, 10)
barBg.Position = UDim2.new(0, 0, 0, 26)
barBg.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
barBg.Parent = infoFrame
local bbc = Instance.new("UICorner"); bbc.CornerRadius = UDim.new(0, 5); bbc.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Name = "XPFill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
barFill.Parent = barBg
local bfc = Instance.new("UICorner"); bfc.CornerRadius = UDim.new(0, 5); bfc.Parent = barFill

-- Teks XP kecil di bawah bar
local xpLabel = Instance.new("TextLabel")
xpLabel.Name = "XPLabel"
xpLabel.Size = UDim2.new(1, -4, 0, 12)
xpLabel.Position = UDim2.new(0, 0, 0, 38)
xpLabel.Text = "0 / 350 XP"
xpLabel.TextSize = 9; xpLabel.Font = Enum.Font.Gotham
xpLabel.TextColor3 = Color3.fromRGB(140, 180, 220)
xpLabel.BackgroundTransparency = 1; xpLabel.TextXAlignment = Enum.TextXAlignment.Left
xpLabel.Parent = infoFrame

-- Resize pill untuk tampung xp label
pill.Size = UDim2.new(0, 230, 0, 62)

-- Level Up popup (muncul sementara saat naik level)
local levelUpPopup = Instance.new("TextLabel")
levelUpPopup.Name = "LevelUpPopup"
levelUpPopup.Size = UDim2.new(0, 220, 0, 40)
levelUpPopup.Position = UDim2.new(0, 12, 0, 80)
levelUpPopup.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
levelUpPopup.BackgroundTransparency = 0.1
levelUpPopup.Text = "⬆️ NAIK LEVEL!"
levelUpPopup.TextSize = 16; levelUpPopup.Font = Enum.Font.GothamBold
levelUpPopup.TextColor3 = Color3.fromRGB(255, 255, 255)
levelUpPopup.Visible = false
levelUpPopup.Parent = screenGui
local lpC = Instance.new("UICorner"); lpC.CornerRadius = UDim.new(0, 20); lpC.Parent = levelUpPopup
local lpS = Instance.new("UIStroke"); lpS.Color = Color3.fromRGB(255, 255, 150); lpS.Thickness = 2; lpS.Parent = levelUpPopup

local function showLevelUp(newLevel: number, title: string)
	levelUpPopup.Text = "⬆️ LEVEL " .. newLevel .. "! " .. title
	levelUpPopup.Visible = true
	levelUpPopup.BackgroundTransparency = 0.1
	TweenService:Create(levelUpPopup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0, 12, 0, 80)}):Play()
	task.delay(2.5, function()
		TweenService:Create(levelUpPopup, TweenInfo.new(0.4, Enum.EasingStyle.Quad),
			{BackgroundTransparency = 1}):Play()
		task.delay(0.5, function()
			levelUpPopup.Visible = false
			levelUpPopup.BackgroundTransparency = 0.1
			levelUpPopup.Position = UDim2.new(0, 12, 0, 80)
		end)
	end)
end

-- ─── STATE TRACKING ──────────────────────────────────────────────────────────

local lastLevel = 0

stateUpdated.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then return end
	if typeof(payload.players) ~= "table" then return end

	local localUserId = lp.UserId
	for _, p in ipairs(payload.players) do
		if typeof(p) ~= "table" then continue end
		if p.userId ~= localUserId then continue end

		local profile = p.profile
		if typeof(profile) ~= "table" then continue end

		local totalXP = profile.xp or 0
		local level, curXP, needed = ProgressionConfig.calculateLevel(totalXP)
		local title = ProgressionConfig.getTitleForLevel(level)
		local isMax = level >= ProgressionConfig.MAX_LEVEL

		-- Update labels
		lvlLabel.Text = tostring(level)
		titleLabel.Text = title

		if isMax then
			xpLabel.Text = "MAX LEVEL 👑"
			lvlBadge.BackgroundColor3 = Color3.fromRGB(200, 160, 20)
		else
			xpLabel.Text = tostring(curXP) .. " / " .. tostring(needed) .. " XP"
			lvlBadge.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
		end

		-- Animasi fill bar
		local ratio = if isMax then 1 else math.clamp(curXP / math.max(needed, 1), 0, 1)
		TweenService:Create(barFill, TweenInfo.new(0.6, Enum.EasingStyle.Cubic),
			{Size = UDim2.new(ratio, 0, 1, 0)}):Play()

		-- Warna bar berubah sesuai title
		local barColors: {[string]: Color3} = {
			["Warga Biasa"]      = Color3.fromRGB(80, 140, 220),
			["Warga Teladan"]    = Color3.fromRGB(80, 180, 120),
			["Pedagang Pasar"]   = Color3.fromRGB(160, 130, 60),
			["Juragan Tanah"]    = Color3.fromRGB(180, 100, 40),
			["Cukong Properti"]  = Color3.fromRGB(160, 60, 180),
			["Konglomerat"]      = Color3.fromRGB(200, 180, 30),
			["Sultan Nusantara 👑"] = Color3.fromRGB(220, 160, 20),
		}
		barFill.BackgroundColor3 = barColors[title] or Color3.fromRGB(80, 160, 255)
		ps.Color = barColors[title] or Color3.fromRGB(90, 180, 255)

		-- Level up notification
		if lastLevel > 0 and level > lastLevel then
			showLevelUp(level, title)
		end
		lastLevel = level
		break
	end
end)
