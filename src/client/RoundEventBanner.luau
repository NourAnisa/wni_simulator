--!strict
-- RoundEventBanner.luau (LocalScript)
-- Menampilkan banner dramatis & indikator aktif saat Event Musiman Nasional terjadi (Ronde 3, 5, 7).
-- Contoh: Musim Mudik Lebaran (Sewa 2x), Bansos Sembako Cair, Audit Pajak & OTT.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated or not stateUpdated:IsA("RemoteEvent") then return end

-- ─── RESPONSIVE SCREEN GUI ───────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WNIRoundEventUI"
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
	uiScale.Scale = math.clamp(target, 0.55, 1.25)
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

-- ─── PERSISTENT EVENT PILL (TOP BAR) ─────────────────────────────────────────

local pill = Instance.new("Frame")
pill.Name = "ActiveEventPill"
pill.Size = UDim2.new(0, 320, 0, 30)
pill.Position = UDim2.new(0.5, 0, 0, -50) -- disembunyikan awalnya
pill.AnchorPoint = Vector2.new(0.5, 0)
pill.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
pill.BackgroundTransparency = 0.15
pill.Visible = false
pill.Parent = screenGui

local pillCorner = Instance.new("UICorner")
pillCorner.CornerRadius = UDim.new(0, 15)
pillCorner.Parent = pill

local pillStroke = Instance.new("UIStroke")
pillStroke.Color = Color3.fromRGB(255, 215, 60)
pillStroke.Thickness = 1.5
pillStroke.Parent = pill

local pillText = Instance.new("TextLabel")
pillText.Name = "PillText"
pillText.Size = UDim2.new(1, -20, 1, 0)
pillText.Position = UDim2.new(0, 10, 0, 0)
pillText.BackgroundTransparency = 1
pillText.TextColor3 = Color3.fromRGB(255, 235, 160)
pillText.TextSize = 12
pillText.Font = Enum.Font.GothamBold
pillText.Text = ""
pillText.Parent = pill

-- ─── DRAMATIC BANNER ANIMATION ───────────────────────────────────────────────

local function playEventChime()
	local s = Instance.new("Sound")
	s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	s.Volume = 0.5
	s.PlaybackSpeed = 1.05
	s.Parent = screenGui
	s:Play()
	game:GetService("Debris"):AddItem(s, 2.0)
end

local activeBanner: Frame? = nil

local function showRoundEventBanner(event: {id: string, name: string, desc: string, icon: string?, round: number?})
	if activeBanner then
		activeBanner:Destroy()
		activeBanner = nil
	end

	playEventChime()

	-- 1. Main Banner Frame
	local banner = Instance.new("Frame")
	banner.Name = "EventBanner"
	banner.Size = UDim2.new(0.68, 0, 0, 84)
	local bannerConstraint = Instance.new("UISizeConstraint")
	bannerConstraint.MinSize = Vector2.new(340, 75)
	bannerConstraint.MaxSize = Vector2.new(580, 95)
	bannerConstraint.Parent = banner
	banner.Position = UDim2.new(0.5, 0, 0, -110)
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.BackgroundColor3 = Color3.fromRGB(30, 20, 45)
	banner.BackgroundTransparency = 0.1
	banner.Parent = screenGui
	activeBanner = banner

	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 18); bc.Parent = banner
	local bs = Instance.new("UIStroke"); bs.Color = Color3.fromRGB(255, 215, 60); bs.Thickness = 2.5; bs.Parent = banner

	-- Gradient
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(80, 25, 45)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(45, 25, 65)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(25, 30, 60)),
	})
	grad.Rotation = 45
	grad.Parent = banner

	-- Icon
	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size = UDim2.new(0, 56, 1, 0)
	iconLbl.Position = UDim2.new(0, 12, 0, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Text = event.icon or "📢"
	iconLbl.TextSize = 36
	iconLbl.Font = Enum.Font.GothamBold
	iconLbl.Parent = banner

	-- Title
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -78, 0, 30)
	titleLbl.Position = UDim2.new(0, 72, 0, 12)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "📢 EVENT NASIONAL: " .. string.upper(event.name)
	titleLbl.TextSize = 16
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextColor3 = Color3.fromRGB(255, 220, 80)
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = banner

	-- Description
	local descLbl = Instance.new("TextLabel")
	descLbl.Size = UDim2.new(1, -78, 0, 32)
	descLbl.Position = UDim2.new(0, 72, 0, 42)
	descLbl.BackgroundTransparency = 1
	descLbl.Text = event.desc or ""
	descLbl.TextSize = 13
	descLbl.Font = Enum.Font.GothamMedium
	descLbl.TextColor3 = Color3.fromRGB(240, 240, 250)
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.TextWrapped = true
	descLbl.Parent = banner

	-- Slide down with bounce
	local bScale = Instance.new("UIScale"); bScale.Scale = 0.8; bScale.Parent = banner
	TweenService:Create(banner, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0, 18)}):Play()
	TweenService:Create(bScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Scale = 1.0}):Play()

	-- Update pill text
	local roundText = if event.round then " [Ronde " .. tostring(event.round) .. "]" else ""
	pillText.Text = (event.icon or "📢") .. " " .. event.name .. roundText .. ": " .. (event.desc or "")

	-- Setelah 4.5 detik, banner slide out dan pill muncul di atas layar
	task.delay(4.5, function()
		if banner.Parent then
			local slideOut = TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, 0, 0, -110), BackgroundTransparency = 1})
			slideOut:Play()
			slideOut.Completed:Once(function()
				banner:Destroy()
				if activeBanner == banner then
					activeBanner = nil
				end
			end)
		end

		-- Tampilkan top pill
		pill.Visible = true
		pill.Position = UDim2.new(0.5, 0, 0, -40)
		TweenService:Create(pill, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Position = UDim2.new(0.5, 0, 0, 8)}):Play()
	end)
end

local function hidePill()
	if pill.Visible then
		local t = TweenService:Create(pill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, 0, 0, -50)})
		t:Play()
		t.Completed:Once(function()
			pill.Visible = false
		end)
	end
end

-- ─── STATE LISTENER ──────────────────────────────────────────────────────────

local lastActiveEventId: string? = nil

stateUpdated.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then return end

	local currentEvent = payload.activeEvent

	if currentEvent and typeof(currentEvent) == "table" and currentEvent.id then
		if currentEvent.id ~= lastActiveEventId then
			lastActiveEventId = currentEvent.id
			showRoundEventBanner(currentEvent)
		end
	else
		if lastActiveEventId ~= nil then
			lastActiveEventId = nil
			hidePill()
		end
	end

	if payload.phase == "Waiting" then
		lastActiveEventId = nil
		hidePill()
		if activeBanner then
			activeBanner:Destroy()
			activeBanner = nil
		end
	end
end)
