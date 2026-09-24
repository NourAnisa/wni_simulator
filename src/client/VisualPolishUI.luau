--!strict
-- VisualPolishUI.luau (LocalScript)
-- Menangani semua visual enhancement:
--   • Hover glow effect pada semua TextButton
--   • Confetti / particle saat Victory
--   • Font upgrade ke GothamBold / Gotham
--   • UIStroke shadow tipis di panel utama
--   • Roster item gradient merah/biru per tim
--   • Dice panel pop animation saat dice berubah
--   • UIGradient pada panel utama

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp     = Players.LocalPlayer
local pgui   = lp:WaitForChild("PlayerGui")
local wniGui = pgui:WaitForChild("WNIGameUI", 15)
if not wniGui then return end
local root   = wniGui:WaitForChild("Root", 10)
if not root then return end

local shared  = ReplicatedStorage:WaitForChild("WNI", 10)
local remotes = shared:WaitForChild("Remotes", 10)
local stateUpdated = remotes:WaitForChild("StateUpdated", 10) :: RemoteEvent

-- ═══════════════════════════════════════════════════════════
-- 1. PALETTE
-- ═══════════════════════════════════════════════════════════
local C = {
	navy       = Color3.fromRGB(14, 20, 38),
	navyLight  = Color3.fromRGB(22, 32, 58),
	gold       = Color3.fromRGB(230, 175, 30),
	goldLight  = Color3.fromRGB(255, 215, 60),
	teal       = Color3.fromRGB(50, 180, 160),
	red        = Color3.fromRGB(220, 70, 70),
	teamA      = Color3.fromRGB(60, 170, 130),  -- hijau-teal
	teamB      = Color3.fromRGB(200, 110, 50),  -- oranye
	white      = Color3.fromRGB(255, 255, 255),
	stroke     = Color3.fromRGB(255, 210, 80),
	shadow     = Color3.fromRGB(0, 0, 0),
}

-- ═══════════════════════════════════════════════════════════
-- 2. UTILITY
-- ═══════════════════════════════════════════════════════════
local function addCorner(inst: Instance, r: number)
	local c = inst:FindFirstChildOfClass("UICorner")
	if c then c.CornerRadius = UDim.new(0, r); return end
	c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = inst
end

local function addGradient(inst: Instance, c0: Color3, c1: Color3, rot: number)
	if inst:FindFirstChildOfClass("UIGradient") then return end
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c0),
		ColorSequenceKeypoint.new(1, c1),
	})
	g.Rotation = rot
	g.Parent = inst
end

local function addStroke(inst: Instance, color: Color3, thickness: number, trans: number?)
	if inst:FindFirstChildOfClass("UIStroke") then
		local s = inst:FindFirstChildOfClass("UIStroke") :: UIStroke
		s.Color = color; s.Thickness = thickness
		s.Transparency = trans or 0
		return s
	end
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Transparency = trans or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function setFont(inst: Instance, font: Enum.Font)
	if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
		(inst :: TextLabel).Font = font
	end
end

-- ═══════════════════════════════════════════════════════════
-- 3. FONT UPGRADE — semua teks ke Gotham / GothamBold
-- ═══════════════════════════════════════════════════════════
local function upgradeFont(parent: Instance)
	for _, desc in ipairs(parent:GetDescendants()) do
		if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
			local tl = desc :: TextLabel
			if tl.Font == Enum.Font.SourceSansBold or tl.Font == Enum.Font.SourceSans then
				tl.Font = if tl.Font == Enum.Font.SourceSansBold
					then Enum.Font.GothamBold
					else Enum.Font.Gotham
			end
		end
	end
end
upgradeFont(root)
root.DescendantAdded:Connect(function(d) upgradeFont(d) end)

-- ═══════════════════════════════════════════════════════════
-- 4. PANEL STYLING — Header, Roster, ActionPanel, LogPanel, PropertyPanel
-- ═══════════════════════════════════════════════════════════
local function stylePanel(name: string, cornerR: number, gradTop: Color3, gradBot: Color3, strokeColor: Color3?)
	local f = root:FindFirstChild(name)
	if not f or not f:IsA("Frame") then return end
	local frame = f :: Frame
	frame.BackgroundColor3 = gradTop
	addCorner(frame, cornerR)
	addGradient(frame, gradTop, gradBot, 170)
	if strokeColor then
		addStroke(frame, strokeColor, 1.5, 0.3)
	end
end

stylePanel("Header",       16, C.navyLight,  C.navy,       C.gold)
stylePanel("Roster",       16, C.navyLight,  C.navy,       C.stroke)
stylePanel("ActionPanel",  16, C.navyLight,  C.navy,       C.stroke)
stylePanel("LogPanel",     12, C.navy,        Color3.fromRGB(8, 12, 22), nil)
stylePanel("PropertyPanel",12, C.navyLight,  C.navy,       nil)
stylePanel("MatchmakingPanel", 16, C.navyLight, C.navy,    C.gold)
stylePanel("RoomPanel",    16, C.navyLight,  C.navy,       C.gold)
stylePanel("DicePanel",    16, C.navy,       Color3.fromRGB(8, 12, 22), C.teal)
stylePanel("HintBar",      12, Color3.fromRGB(30, 22, 8), Color3.fromRGB(18, 12, 4), C.gold)

-- VictoryPanel Content
local victoryPanel = root:FindFirstChild("VictoryPanel")
if victoryPanel then
	local content = victoryPanel:FindFirstChild("Content")
	if content and content:IsA("Frame") then
		(content :: Frame).BackgroundColor3 = C.navyLight
		addCorner(content, 20)
		addGradient(content, Color3.fromRGB(22, 32, 60), C.navy, 160)
		addStroke(content, C.gold, 2, 0)
	end
	if victoryPanel:IsA("Frame") then
		(victoryPanel :: Frame).BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	end
end

-- ═══════════════════════════════════════════════════════════
-- 5. BUTTON STYLING + HOVER GLOW EFFECT
-- ═══════════════════════════════════════════════════════════
local PRIMARY_BTN_COLOR = C.gold
local PRIMARY_BTN_HOVER = C.goldLight
local SECONDARY_BTN_COLOR = Color3.fromRGB(48, 58, 88)
local SECONDARY_BTN_HOVER = Color3.fromRGB(65, 80, 120)

local function styleButton(btn: TextButton, isPrimary: boolean)
	local baseColor = if isPrimary then PRIMARY_BTN_COLOR else SECONDARY_BTN_COLOR
	local hoverColor = if isPrimary then PRIMARY_BTN_HOVER else SECONDARY_BTN_HOVER
	btn.BackgroundColor3 = baseColor
	addCorner(btn, 14)
	-- Gradient sudah ditambahkan, remove dulu lalu buat baru
	local oldGrad = btn:FindFirstChildOfClass("UIGradient")
	if oldGrad then oldGrad:Destroy() end
	addGradient(btn,
		if isPrimary then C.goldLight else Color3.fromRGB(65, 80, 120),
		if isPrimary then Color3.fromRGB(180, 120, 10) else Color3.fromRGB(35, 44, 70),
		90
	)

	-- Hover enter
	btn.MouseEnter:Connect(function()
		if not btn.Active then return end
		TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
			BackgroundColor3 = hoverColor,
			Size = btn.Size + UDim2.fromOffset(0, 2),
		}):Play()
	end)
	-- Hover leave
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
			BackgroundColor3 = baseColor,
			Size = btn.Size - UDim2.fromOffset(0, 2),
		}):Play()
	end)
	-- Press effect
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
			Size = btn.Size - UDim2.fromOffset(2, 2),
		}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = btn.Size + UDim2.fromOffset(2, 2),
		}):Play()
	end)
end

-- Terapkan ke semua button di root
local PRIMARY_NAMES = {"RollButton", "ReadyButton", "BuyButton", "Rematch", "QueueButton", "AcceptMatchButton"}
for _, desc in ipairs(root:GetDescendants()) do
	if desc:IsA("TextButton") then
		local btn = desc :: TextButton
		local isPrimary = table.find(PRIMARY_NAMES, btn.Name) ~= nil
		-- Hanya style jika bukan tombol kecil navigasi
		if btn.Name ~= "Previous" and btn.Name ~= "Next" and
		   btn.Name ~= "CloseHand" and btn.Name ~= "PreviousCard" and btn.Name ~= "NextCard" then
			task.spawn(styleButton, btn, isPrimary)
		end
	end
end

-- ═══════════════════════════════════════════════════════════
-- 6. ROSTER ITEM — gradient per tim + shadow per seat
-- ═══════════════════════════════════════════════════════════
-- Roster seat frames: Tim A = teal-gradient, Tim B = oranye-gradient, kosong = abu
local rosterFrame = root:FindFirstChild("Roster") :: Frame?
if rosterFrame then
	for seat = 1, 4 do
		local sf = rosterFrame:FindFirstChild("Seat" .. seat) :: Frame?
		if not sf then continue end
		addCorner(sf, 12)
		addStroke(sf, C.shadow, 2, 0.7)
	end
end

local function updateRosterColors(snap: any)
	if not rosterFrame then return end
	for seat = 1, 4 do
		local sf = rosterFrame:FindFirstChild("Seat" .. seat) :: Frame?
		if not sf then continue end
		local player_ = snap and snap.players and snap.players[seat]
		local oldGrad = sf:FindFirstChildOfClass("UIGradient")
		if oldGrad then oldGrad:Destroy() end
		if player_ and player_.team == "A" then
			sf.BackgroundColor3 = Color3.fromRGB(20, 60, 50)
			addGradient(sf, Color3.fromRGB(25, 80, 65), Color3.fromRGB(12, 32, 28), 160)
			local s = sf:FindFirstChildOfClass("UIStroke")
			if s then s.Color = C.teamA; s.Transparency = 0.2 end
		elseif player_ and player_.team == "B" then
			sf.BackgroundColor3 = Color3.fromRGB(60, 32, 14)
			addGradient(sf, Color3.fromRGB(80, 44, 18), Color3.fromRGB(38, 18, 8), 160)
			local s = sf:FindFirstChildOfClass("UIStroke")
			if s then s.Color = C.teamB; s.Transparency = 0.2 end
		else
			sf.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
			addGradient(sf, Color3.fromRGB(22, 30, 48), Color3.fromRGB(12, 16, 28), 160)
			local s = sf:FindFirstChildOfClass("UIStroke")
			if s then s.Color = C.shadow; s.Transparency = 0.7 end
		end
	end
end

-- ═══════════════════════════════════════════════════════════
-- 7. DICE POP ANIMATION saat nilai dadu berubah
-- ═══════════════════════════════════════════════════════════
local dicePanel = root:FindFirstChild("DicePanel") :: Frame?
local lastDiceText = ""

local function pulseDice()
	if not dicePanel then return end
	local origSize = dicePanel.Size
	TweenService:Create(dicePanel, TweenInfo.new(0.10, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(origSize.X.Scale, origSize.X.Offset + 8, origSize.Y.Scale, origSize.Y.Offset + 8),
	}):Play()
	task.delay(0.12, function()
		TweenService:Create(dicePanel, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
			Size = origSize,
		}):Play()
	end)
end

-- ═══════════════════════════════════════════════════════════
-- 8. CONFETTI — muncul saat VictoryPanel dibuka (menang)
-- ═══════════════════════════════════════════════════════════
local confettiGui: ScreenGui? = nil

local CONFETTI_COLORS = {
	Color3.fromRGB(255, 215, 0),
	Color3.fromRGB(80, 220, 160),
	Color3.fromRGB(255, 100, 100),
	Color3.fromRGB(100, 180, 255),
	Color3.fromRGB(220, 100, 255),
	Color3.fromRGB(255, 180, 50),
}

local function spawnConfetti(won: boolean)
	if not won then return end
	-- Bersihkan confetti lama
	if confettiGui then confettiGui:Destroy() end
	local gui_ = Instance.new("ScreenGui")
	gui_.Name = "WNIConfetti"
	gui_.ResetOnSpawn = false
	gui_.DisplayOrder = 20
	gui_.Parent = pgui
	confettiGui = gui_

	local PIECES = 60
	for i = 1, PIECES do
		task.spawn(function()
			task.wait(math.random() * 1.2)
			if not confettiGui then return end
			local piece = Instance.new("Frame")
			local w = math.random(6, 14)
			local h = math.random(8, 18)
			piece.Size = UDim2.fromOffset(w, h)
			piece.Position = UDim2.new(math.random() * 0.9 + 0.05, 0, -0.05, 0)
			piece.BackgroundColor3 = CONFETTI_COLORS[math.random(#CONFETTI_COLORS)]
			piece.BorderSizePixel = 0
			piece.Rotation = math.random(-45, 45)
			-- Rounded kecil agar tidak kotak
			local c_ = Instance.new("UICorner")
			c_.CornerRadius = UDim.new(0, 3)
			c_.Parent = piece
			piece.Parent = gui_

			-- Jatuh ke bawah
			local duration = math.random(18, 32) / 10
			local targetY = 1.1 + math.random() * 0.2
			TweenService:Create(piece, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(piece.Position.X.Scale + (math.random() - 0.5) * 0.3, 0, targetY, 0),
				Rotation = piece.Rotation + math.random(-360, 360),
			}):Play()
			task.delay(duration, function()
				if piece and piece.Parent then piece:Destroy() end
			end)
		end)
	end

	-- Auto hapus confetti gui setelah 5 detik
	task.delay(5.5, function()
		if confettiGui == gui_ then
			gui_:Destroy()
			confettiGui = nil
		end
	end)
end

-- ═══════════════════════════════════════════════════════════
-- 9. STATE LISTENER — update roster color + dice pop + confetti
-- ═══════════════════════════════════════════════════════════
local lastPhase = ""
local wasFinished = false
local myUserId = lp.UserId

stateUpdated.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then return end

	-- Roster colors
	updateRosterColors(payload)

	-- Dice pop
	local diceResult = ""
	if typeof(payload.dice) == "table" then
		for _, v in ipairs(payload.dice) do
			diceResult ..= tostring(v)
		end
	end
	if diceResult ~= lastDiceText and diceResult ~= "00" and diceResult ~= "" then
		lastDiceText = diceResult
		pulseDice()
	end

	-- Confetti saat victory
	local phase = typeof(payload.phase) == "string" and payload.phase or ""
	if phase == "Finished" and not wasFinished then
		wasFinished = true
		-- Cari apakah player menang
		local myTeam = ""
		if typeof(payload.players) == "table" then
			for _, p in ipairs(payload.players) do
				if typeof(p) == "table" and p.userId == myUserId then
					myTeam = typeof(p.team) == "string" and p.team or ""
					break
				end
			end
		end
		local result = typeof(payload.result) == "string" and payload.result or ""
		local won = (myTeam == "A" and string.find(result, "TIM A MENANG", 1, true) ~= nil)
			or (myTeam == "B" and string.find(result, "TIM B MENANG", 1, true) ~= nil)
		task.delay(0.5, function() spawnConfetti(won) end)
	elseif phase ~= "Finished" then
		wasFinished = false
		if confettiGui then confettiGui:Destroy(); confettiGui = nil end
	end
	lastPhase = phase
end)

-- ═══════════════════════════════════════════════════════════
-- 10. SHADOW STROKE pada semua outer panel
-- ═══════════════════════════════════════════════════════════
local SHADOW_PANELS = {"VictoryPanel", "MatchmakingPanel", "RoomPanel", "TutorialPanel", "HandPanel", "CardDrawModal", "SpecialTileToast", "CardToast", "ActionBanner"}
for _, name in ipairs(SHADOW_PANELS) do
	local f = root:FindFirstChild(name)
	if f and (f:IsA("Frame") or f:IsA("CanvasGroup")) then
		addStroke(f, C.shadow, 3, 0.6)
		addCorner(f, 18)
	end
end

-- ═══════════════════════════════════════════════════════════
-- 11. HEADER GOLD STROKE khusus
-- ═══════════════════════════════════════════════════════════
local headerFrame = root:FindFirstChild("Header") :: Frame?
if headerFrame then
	local s = headerFrame:FindFirstChildOfClass("UIStroke")
	if s then
		s.Color = C.gold
		s.Thickness = 2
		s.Transparency = 0
	else
		addStroke(headerFrame, C.gold, 2, 0)
	end
end

-- Initial roster color (sebelum state datang)
updateRosterColors(nil)
