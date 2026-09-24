--!strict
-- XPProgressUI.luau (LocalScript)
-- Bar XP + level + gelar mini di bawah Header (horizontal center, responsive).
-- Update real-time dari snapshot.profile pemain.

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
local stateUpdated = Remotes:WaitForChild("StateUpdated", 10)
local ProgressionConfig = require(shared:WaitForChild("ProgressionConfig", 5))

-- ─── RESPONSIVE SCREEN GUI ───────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WNIXPProgressUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 5
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

-- ─── BUILD UI ────────────────────────────────────────────────────────────────

-- Pill container: diposisikan di tengah horizontal tepat di bawah Header (Y = 68)
local pill = Instance.new("Frame")
pill.Name = "XPPill"
pill.Size = UDim2.new(0, 230, 0, 56)
pill.Position = UDim2.new(0.5, 0, 0, 68)
pill.AnchorPoint = Vector2.new(0.5, 0)
pill.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
pill.BackgroundTransparency = 0.15
pill.Parent = screenGui

local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 28); pc.Parent = pill
local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(90, 180, 255); ps.Thickness = 2; ps.Parent = pill

-- Level badge (kiri)
local lvlBadge = Instance.new("Frame")
lvlBadge.Size = UDim2.new(0, 44, 0, 44)
lvlBadge.Position = UDim2.new(0, 6, 0.5, 0)
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
infoFrame.Size = UDim2.new(1, -60, 1, 0)
infoFrame.Position = UDim2.new(0, 56, 0, 0)
infoFrame.BackgroundTransparency = 1
infoFrame.Parent = pill

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -6, 0, 16)
titleLabel.Position = UDim2.new(0, 0, 0, 6)
titleLabel.Text = "Warga Biasa"
titleLabel.TextSize = 11; titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextColor3 = Color3.fromRGB(220, 200, 90)
titleLabel.BackgroundTransparency = 1; titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = infoFrame

-- XP bar background
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -8, 0, 8)
barBg.Position = UDim2.new(0, 0, 0, 24)
barBg.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
barBg.Parent = infoFrame
local bbc = Instance.new("UICorner"); bbc.CornerRadius = UDim.new(0, 4); bbc.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Name = "XPFill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
barFill.Parent = barBg
local bfc = Instance.new("UICorner"); bfc.CornerRadius = UDim.new(0, 4); bfc.Parent = barFill

-- Teks XP kecil di bawah bar
local xpLabel = Instance.new("TextLabel")
xpLabel.Name = "XPLabel"
xpLabel.Size = UDim2.new(1, -8, 0, 14)
xpLabel.Position = UDim2.new(0, 0, 0, 34)
xpLabel.Text = "0 / 350 XP"
xpLabel.TextSize = 9; xpLabel.Font = Enum.Font.Gotham
xpLabel.TextColor3 = Color3.fromRGB(140, 180, 220)
xpLabel.BackgroundTransparency = 1; xpLabel.TextXAlignment = Enum.TextXAlignment.Left
xpLabel.Parent = infoFrame

-- Level Up popup (muncul di tengah tepat di bawah bar XP)
local levelUpPopup = Instance.new("TextLabel")
levelUpPopup.Name = "LevelUpPopup"
levelUpPopup.Size = UDim2.new(0, 240, 0, 38)
levelUpPopup.Position = UDim2.new(0.5, 0, 0, 130)
levelUpPopup.AnchorPoint = Vector2.new(0.5, 0)
levelUpPopup.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
levelUpPopup.BackgroundTransparency = 0.1
levelUpPopup.Text = "⬆️ NAIK LEVEL!"
levelUpPopup.TextSize = 15; levelUpPopup.Font = Enum.Font.GothamBold
levelUpPopup.TextColor3 = Color3.fromRGB(255, 255, 255)
levelUpPopup.Visible = false
levelUpPopup.Parent = screenGui
local lpC = Instance.new("UICorner"); lpC.CornerRadius = UDim.new(0, 19); lpC.Parent = levelUpPopup
local lpS = Instance.new("UIStroke"); lpS.Color = Color3.fromRGB(255, 255, 150); lpS.Thickness = 2; lpS.Parent = levelUpPopup

local function showLevelUp(newLevel: number, title: string)
	levelUpPopup.Text = "⬆️ LEVEL " .. newLevel .. "! " .. title
	levelUpPopup.Visible = true
	levelUpPopup.BackgroundTransparency = 0.1
	TweenService:Create(levelUpPopup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0, 130)}):Play()
	task.delay(2.5, function()
		TweenService:Create(levelUpPopup, TweenInfo.new(0.4, Enum.EasingStyle.Quad),
			{BackgroundTransparency = 1}):Play()
		task.delay(0.5, function()
			levelUpPopup.Visible = false
			levelUpPopup.BackgroundTransparency = 0.1
			levelUpPopup.Position = UDim2.new(0.5, 0, 0, 130)
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

		lvlLabel.Text = tostring(level)
		titleLabel.Text = title

		if isMax then
			xpLabel.Text = "MAX LEVEL 👑"
			lvlBadge.BackgroundColor3 = Color3.fromRGB(200, 160, 20)
		else
			xpLabel.Text = tostring(curXP) .. " / " .. tostring(needed) .. " XP"
			lvlBadge.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
		end

		local ratio = if isMax then 1 else math.clamp(curXP / math.max(needed, 1), 0, 1)
		TweenService:Create(barFill, TweenInfo.new(0.6, Enum.EasingStyle.Cubic),
			{Size = UDim2.new(ratio, 0, 1, 0)}):Play()

		local barColors: {[string]: Color3} = {
			["Warga Biasa"]        = Color3.fromRGB(80, 140, 220),
			["Warga Teladan"]      = Color3.fromRGB(80, 180, 120),
			["Pedagang Pasar"]     = Color3.fromRGB(160, 130, 60),
			["Juragan Tanah"]      = Color3.fromRGB(180, 100, 40),
			["Cukong Properti"]    = Color3.fromRGB(160, 60, 180),
			["Konglomerat"]        = Color3.fromRGB(200, 180, 30),
			["Sultan Nusantara 👑"] = Color3.fromRGB(220, 160, 20),
		}
		barFill.BackgroundColor3 = barColors[title] or Color3.fromRGB(80, 160, 255)
		ps.Color = barColors[title] or Color3.fromRGB(90, 180, 255)

		if lastLevel > 0 and level > lastLevel then
			showLevelUp(level, title)
		end
		lastLevel = level
		break
	end
end)
