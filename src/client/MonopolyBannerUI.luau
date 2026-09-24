--!strict
-- MonopolyBannerUI.luau (LocalScript)
-- Tampilkan banner dramatis saat Monopoli Nusantara terbentuk.
-- Juga menampilkan skor akhir tim yang detail saat match selesai.

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

-- ─── RESPONSIVE SCREEN GUI ───────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WNIBannerUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 10
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

-- ─── MONOPOLY BANNER ─────────────────────────────────────────────────────────

local function showMonopolyBanner(teamLabel: string, islandName: string, teamColor: Color3)
	-- Buat banner baru setiap kali (auto-destroy setelah animasi)
	local banner = Instance.new("Frame")
	banner.Size = UDim2.new(0.65, 0, 0, 75)
	local bannerConstraint = Instance.new("UISizeConstraint")
	bannerConstraint.MinSize = Vector2.new(280, 60)
	bannerConstraint.MaxSize = Vector2.new(550, 85)
	bannerConstraint.Parent = banner
	banner.Position = UDim2.new(0.5, 0, 0, -90)
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.BackgroundColor3 = teamColor
	banner.BackgroundTransparency = 0.15
	banner.Parent = screenGui

	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 18); bc.Parent = banner
	local bs = Instance.new("UIStroke"); bs.Color = Color3.fromRGB(255, 255, 100); bs.Thickness = 3; bs.Parent = banner

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -12, 1, -8)
	txt.Position = UDim2.new(0, 6, 0, 4)
	txt.Text = "👑 MONOPOLI " .. string.upper(islandName) .. "!\n" .. teamLabel .. " — SEWA 2× AKTIF!"
	txt.TextSize = 18; txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = Color3.fromRGB(255, 255, 255)
	txt.BackgroundTransparency = 1
	txt.TextScaled = true
	txt.Parent = banner

	-- Slide in dari atas
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0, 12)}):Play()

	-- Bounce scale
	local uiScale = Instance.new("UIScale"); uiScale.Scale = 0.8; uiScale.Parent = banner
	TweenService:Create(uiScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Scale = 1}):Play()

	-- Bertahan 3 detik lalu slide out
	task.delay(3.5, function()
		if not banner.Parent then return end
		TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, 0, 0, -100), BackgroundTransparency = 1}):Play()
		task.delay(0.4, function() banner:Destroy() end)
	end)
end

-- ─── ENDGAME SCORECARD ───────────────────────────────────────────────────────

local scorecardFrame: Frame? = nil

local function formatMoney(n: number): string
	local s = tostring(math.floor(math.abs(n)))
	local rev = string.reverse(s)
	local grouped = string.gsub(rev, "(%d%d%d)", "%1.")
	grouped = string.reverse(grouped)
	if string.sub(grouped, 1, 1) == "." then grouped = string.sub(grouped, 2) end
	return (if n < 0 then "-Rp" else "Rp") .. grouped
end

local function buildScorecard(payload: any)
	if scorecardFrame then scorecardFrame:Destroy() end

	local winnerStr = tostring(payload.result or "")
	local isA = string.find(winnerStr, "TIM A") ~= nil or string.find(winnerStr, "Tim A") ~= nil
	local isDraw = string.find(string.upper(winnerStr), "SERI") ~= nil
	local winnerTeam = if isDraw then "" elseif isA then "A" else "B"
	local teamColors = {A = Color3.fromRGB(70, 130, 220), B = Color3.fromRGB(220, 80, 80)}

	-- Parse skor dari string result (format: "TIM X MENANG | A RpX | B RpY")
	local scoreA, scoreB = 0, 0
	local sa = string.match(winnerStr, "| A (Rp[%d%.]+)")
	local sb = string.match(winnerStr, "| B (Rp[%d%.]+)")
	if sa then scoreA = tonumber(string.gsub(sa, "[Rp%.]", "")) or 0 end
	if sb then scoreB = tonumber(string.gsub(sb, "[Rp%.]", "")) or 0 end

	local card = Instance.new("Frame")
	card.Name = "ScoreCard"
	card.Size = UDim2.new(0.85, 0, 0, 250)
	local cardConstraint = Instance.new("UISizeConstraint")
	cardConstraint.MinSize = Vector2.new(280, 220)
	cardConstraint.MaxSize = Vector2.new(440, 280)
	cardConstraint.Parent = card
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
	card.BackgroundTransparency = 0.05
	card.Parent = screenGui
	scorecardFrame = card

	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 20); cc.Parent = card
	local cs = Instance.new("UIStroke"); cs.Thickness = 3
	cs.Color = if isDraw then Color3.fromRGB(180, 180, 180)
		elseif winnerTeam == "A" then teamColors.A else teamColors.B
	cs.Parent = card

	local titleColor = if isDraw then Color3.fromRGB(220, 220, 220)
		elseif winnerTeam == "A" then teamColors.A else teamColors.B
	local titleText = if isDraw then "⚖️ HASIL SERI"
		elseif winnerTeam == "A" then "🏆 TIM A MENANG!"
		else "🏆 TIM B MENANG!"

	local titleL = Instance.new("TextLabel")
	titleL.Size = UDim2.new(1, 0, 0, 50)
	titleL.Position = UDim2.new(0, 0, 0, 10)
	titleL.Text = titleText; titleL.TextSize = 22; titleL.Font = Enum.Font.GothamBold
	titleL.TextColor3 = titleColor; titleL.BackgroundTransparency = 1; titleL.Parent = card

	-- Team score bars
	for idx, team in ipairs({"A", "B"}) do
		local score = if team == "A" then scoreA else scoreB
		local isWinner = winnerTeam == team
		local yPos = 65 + (idx - 1) * 65

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -20, 0, 24)
		label.Position = UDim2.new(0, 10, 0, yPos)
		label.Text = (if isWinner then "🏆 " else "  ") .. "TIM " .. team .. ": " .. formatMoney(score)
		label.TextSize = 15; label.Font = Enum.Font.GothamBold
		label.TextColor3 = teamColors[team]; label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = card

		-- Score bar visual
		local maxScore = math.max(scoreA + scoreB, 1)
		local ratio = math.clamp(score / maxScore, 0, 1)

		local barBg = Instance.new("Frame")
		barBg.Size = UDim2.new(1, -20, 0, 18)
		barBg.Position = UDim2.new(0, 10, 0, yPos + 26)
		barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		barBg.Parent = card
		local bbc = Instance.new("UICorner"); bbc.CornerRadius = UDim.new(0, 9); bbc.Parent = barBg

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(0, 0, 1, 0) -- start dari 0 untuk animasi
		fill.BackgroundColor3 = teamColors[team]
		fill.Parent = barBg
		local fbc = Instance.new("UICorner"); fbc.CornerRadius = UDim.new(0, 9); fbc.Parent = fill

		-- Animasi bar
		task.delay(0.5 + idx * 0.2, function()
			if fill.Parent then
				TweenService:Create(fill, TweenInfo.new(0.8, Enum.EasingStyle.Cubic),
					{Size = UDim2.new(ratio, 0, 1, 0)}):Play()
			end
		end)
	end

	-- Tombol tutup
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 100, 0, 34)
	closeBtn.Position = UDim2.new(0.5, 0, 0, 200)
	closeBtn.AnchorPoint = Vector2.new(0.5, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
	closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	closeBtn.Text = "Tutup ×"; closeBtn.TextSize = 13; closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = card
	local clc = Instance.new("UICorner"); clc.CornerRadius = UDim.new(0, 17); clc.Parent = closeBtn

	closeBtn.Activated:Connect(function()
		if card.Parent then
			TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad),
				{BackgroundTransparency = 1}):Play()
			task.delay(0.3, function() card:Destroy() end)
		end
	end)

	-- Slide in dari bawah
	card.Position = UDim2.new(0.5, 0, 1.2, 0)
	TweenService:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
end

-- ─── STATE TRACKING ──────────────────────────────────────────────────────────

local lastMonopolies: {[string]: {string}} = {A = {}, B = {}}
local lastPhase = ""
local TEAM_COLORS = {A = Color3.fromRGB(70, 130, 220), B = Color3.fromRGB(220, 80, 80)}
local TEAM_LABELS = {A = "TIM A (Biru)", B = "TIM B (Merah)"}

stateUpdated.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then return end

	-- Cek monopoli baru terbentuk
	if typeof(payload.monopolies) == "table" then
		for _, team in ipairs({"A", "B"}) do
			local current: {string} = payload.monopolies[team] or {}
			local prev: {string} = lastMonopolies[team] or {}
			for _, island in ipairs(current) do
				if not table.find(prev, island) then
					-- Monopoli baru!
					local islandNames: {[string]: string} = {
						SUMATERA = "Sumatera", KALIMANTAN = "Kalimantan",
						SULAWESI = "Sulawesi", PAPUA = "Papua", JAWA = "Jawa"
					}
					local name = islandNames[island] or island
					showMonopolyBanner(TEAM_LABELS[team], name, TEAM_COLORS[team])
				end
			end
			lastMonopolies[team] = current
		end
	end

	-- Scorecard saat Finished
	if payload.phase == "Finished" and lastPhase ~= "Finished" then
		task.delay(1.5, function()
			if payload.result and payload.result ~= "" then
				buildScorecard(payload)
			end
		end)
	end

	-- Reset saat Waiting
	if payload.phase == "Waiting" then
		lastMonopolies = {A = {}, B = {}}
		if scorecardFrame then
			scorecardFrame:Destroy()
			scorecardFrame = nil
		end
	end

	lastPhase = payload.phase or ""
end)
