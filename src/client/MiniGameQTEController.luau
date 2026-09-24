--!strict
-- MiniGameQTEController.luau (LocalScript)
-- Mini-Game Interaktif QTE (Quick Time Event):
-- 1. ⚖️ Sidang Tipikor di Pengadilan (Meter Bar Ketuk Palu Hakim)
-- 2. 🛵 Parkiran Pungli / Razia Reaksi Cepat

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local Remotes = shared:WaitForChild("Remotes", 10)
if not Remotes then return end
local stateUpdated = Remotes:WaitForChild("StateUpdated", 10) :: RemoteEvent

local board = Workspace:WaitForChild("WNIBoard", 10)
if not board then return end
local tilesFolder = board:WaitForChild("Tiles", 10)

-- ─── RESPONSIVE SCREEN GUI ───────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WNIMiniGameUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 15 -- Di atas GameUI dan LeaderboardUI
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
task.spawn(updateScale)

-- ─── UI HELPERS ──────────────────────────────────────────────────────────────

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

local function playSound(soundId: string, volume: number)
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volume
	s.Parent = screenGui
	s:Play()
	game:GetService("Debris"):AddItem(s, 3)
end

-- ─── 1. QTE: SIDANG TIPIKOR (PENGADILAN) ──────────────────────────────────────

local isCourtQTEActive = false
local courtConnection: RBXScriptConnection? = nil

local function startCourtMiniGame(onComplete: (isFree: boolean) -> ())
	if isCourtQTEActive then return end
	isCourtQTEActive = true

	local overlay = Instance.new("Frame")
	overlay.Name = "CourtOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.45
	overlay.Parent = screenGui

	local modal = Instance.new("Frame")
	modal.Name = "CourtModal"
	modal.Size = UDim2.new(0, 360, 0, 250)
	modal.Position = UDim2.new(0.5, 0, 0.5, 0)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.BackgroundColor3 = Color3.fromRGB(22, 20, 30)
	modal.Parent = overlay
	corner(18, modal)
	stroke(Color3.fromRGB(240, 190, 70), 2.5, modal)

	local iconL = Instance.new("TextLabel")
	iconL.Size = UDim2.new(1, 0, 0, 38)
	iconL.Position = UDim2.new(0, 0, 0, 12)
	iconL.Text = "⚖️"
	iconL.TextSize = 32
	iconL.BackgroundTransparency = 1
	iconL.Parent = modal

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 22)
	title.Position = UDim2.new(0, 0, 0, 52)
	title.Text = "SIDANG TIPIKOR NUSANTARA"
	title.TextColor3 = Color3.fromRGB(255, 215, 80)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.BackgroundTransparency = 1
	title.Parent = modal

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -40, 0, 30)
	subtitle.Position = UDim2.new(0, 20, 0, 76)
	subtitle.Text = "Ketuk palu saat jarum berada di Zona Hijau (Vonis Bebas)!"
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 210)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 11
	subtitle.TextWrapped = true
	subtitle.BackgroundTransparency = 1
	subtitle.Parent = modal

	-- Meter Bar
	local meterTrack = Instance.new("Frame")
	meterTrack.Name = "MeterTrack"
	meterTrack.Size = UDim2.new(0, 280, 0, 26)
	meterTrack.Position = UDim2.new(0.5, 0, 0, 122)
	meterTrack.AnchorPoint = Vector2.new(0.5, 0)
	meterTrack.BackgroundColor3 = Color3.fromRGB(180, 50, 50) -- Red zone
	meterTrack.Parent = modal
	corner(13, meterTrack)
	stroke(Color3.fromRGB(60, 60, 70), 2, meterTrack)

	-- Sweet Spot (Green Zone di tengah: 38% - 62%)
	local sweetSpot = Instance.new("Frame")
	sweetSpot.Name = "SweetSpot"
	sweetSpot.Size = UDim2.new(0.28, 0, 1, 0)
	sweetSpot.Position = UDim2.new(0.36, 0, 0, 0)
	sweetSpot.BackgroundColor3 = Color3.fromRGB(45, 175, 85) -- Green zone
	sweetSpot.Parent = meterTrack
	corner(8, sweetSpot)

	local sweetLabel = Instance.new("TextLabel")
	sweetLabel.Size = UDim2.new(1, 0, 1, 0)
	sweetLabel.Text = "BEBAS"
	sweetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	sweetLabel.TextSize = 10
	sweetLabel.Font = Enum.Font.GothamBold
	sweetLabel.BackgroundTransparency = 1
	sweetLabel.Parent = sweetSpot

	-- Moving Needle (Jarum Penunjuk)
	local needle = Instance.new("Frame")
	needle.Name = "Needle"
	needle.Size = UDim2.new(0, 8, 1, 6)
	needle.AnchorPoint = Vector2.new(0.5, 0.5)
	needle.Position = UDim2.new(0.5, 0, 0.5, 0)
	needle.BackgroundColor3 = Color3.fromRGB(255, 240, 90)
	needle.Parent = meterTrack
	corner(4, needle)
	stroke(Color3.fromRGB(30, 30, 30), 1.5, needle)

	-- Tombol Ketuk Palu
	local hammerBtn = Instance.new("TextButton")
	hammerBtn.Name = "HammerBtn"
	hammerBtn.Size = UDim2.new(0, 240, 0, 42)
	hammerBtn.Position = UDim2.new(0.5, 0, 0, 170)
	hammerBtn.AnchorPoint = Vector2.new(0.5, 0)
	hammerBtn.BackgroundColor3 = Color3.fromRGB(215, 150, 40)
	hammerBtn.Text = "🔨 KETUK PALU SEKARANG!"
	hammerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	hammerBtn.TextSize = 12
	hammerBtn.Font = Enum.Font.GothamBold
	hammerBtn.Parent = modal
	corner(10, hammerBtn)
	stroke(Color3.fromRGB(255, 220, 100), 2, hammerBtn)

	-- Animasi Ayunan Jarum (Ping-Pong)
	local currentPos = 0.5
	local speed = 1.35
	local startTime = os.clock()
	local resolved = false

	courtConnection = RunService.RenderStepped:Connect(function()
		if resolved then return end
		local elapsed = os.clock() - startTime
		local cycle = (math.sin(elapsed * speed * math.pi * 2) + 1) / 2
		currentPos = math.clamp(cycle, 0.05, 0.95)
		needle.Position = UDim2.new(currentPos, 0, 0.5, 0)
	end)

	local function resolveQTE()
		if resolved then return end
		resolved = true
		if courtConnection then
			courtConnection:Disconnect()
			courtConnection = nil
		end

		hammerBtn.Active = false
		-- Palu sound
		playSound("rbxasset://sounds/button.wav", 0.8)

		local isFree = currentPos >= 0.35 and currentPos <= 0.65

		if isFree then
			modal.BackgroundColor3 = Color3.fromRGB(20, 42, 28)
			title.Text = "🎉 VONIS BEBAS MURNI!"
			title.TextColor3 = Color3.fromRGB(120, 255, 150)
			subtitle.Text = "Eksepsi pembelaanmu diterima hakim! Kamu terbebas dari denda perkara!"
			hammerBtn.Text = "✅ BEBAS TANPA SYARAT"
			hammerBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 75)
			playSound("rbxasset://sounds/victory.mp3", 0.6)
		else
			modal.BackgroundColor3 = Color3.fromRGB(45, 20, 24)
			title.Text = "❌ VONIS BERSALAH!"
			title.TextColor3 = Color3.fromRGB(255, 110, 110)
			subtitle.Text = "Dakwaan jaksa terbukti sah! Denda perkara diberlakukan!"
			hammerBtn.Text = "⚖️ VONIS DIKETUK"
			hammerBtn.BackgroundColor3 = Color3.fromRGB(160, 45, 45)
			playSound("rbxasset://sounds/electronicpingshort.wav", 0.6)
		end

		task.delay(2.6, function()
			if overlay.Parent then
				local out = TweenService:Create(modal, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = UDim2.new(0, 300, 0, 180),
					BackgroundTransparency = 1,
				})
				out.Completed:Connect(function()
					overlay:Destroy()
					isCourtQTEActive = false
					onComplete(isFree)
				end)
				out:Play()
			end
		end)
	end

	hammerBtn.Activated:Connect(resolveQTE)
	-- Timeout otomatis 5 detik
	task.delay(5.0, function()
		if not resolved then resolveQTE() end
	end)
end

-- ─── 2. QUICK ALERT: PARKIRAN PUNGLI ──────────────────────────────────────────

local function showParkingAlert()
	local toast = Instance.new("Frame")
	toast.Name = "ParkingAlert"
	toast.Size = UDim2.new(0, 320, 0, 52)
	toast.Position = UDim2.new(0.5, -160, 0, -70)
	toast.BackgroundColor3 = Color3.fromRGB(36, 26, 18)
	toast.Parent = screenGui
	corner(14, toast)
	stroke(Color3.fromRGB(245, 160, 50), 2, toast)

	local iconL = Instance.new("TextLabel")
	iconL.Size = UDim2.new(0, 44, 1, 0)
	iconL.Text = "🛵"
	iconL.TextSize = 24
	iconL.BackgroundTransparency = 1
	iconL.Parent = toast

	local titleL = Instance.new("TextLabel")
	titleL.Size = UDim2.new(1, -52, 0, 16)
	titleL.Position = UDim2.new(0, 46, 0, 8)
	titleL.Text = "PARKIRAN PUNGLI AKAMSI!"
	titleL.TextColor3 = Color3.fromRGB(255, 185, 60)
	titleL.TextSize = 11
	titleL.Font = Enum.Font.GothamBold
	titleL.TextXAlignment = Enum.TextXAlignment.Left
	titleL.BackgroundTransparency = 1
	titleL.Parent = toast

	local subL = Instance.new("TextLabel")
	subL.Size = UDim2.new(1, -52, 0, 14)
	subL.Position = UDim2.new(0, 46, 0, 26)
	subL.Text = "\"Priiit! Dua ribu dulu bang!\" Biaya parkir ditarik."
	subL.TextColor3 = Color3.fromRGB(220, 220, 220)
	subL.TextSize = 9
	subL.Font = Enum.Font.Gotham
	subL.TextXAlignment = Enum.TextXAlignment.Left
	subL.BackgroundTransparency = 1
	subL.Parent = toast

	playSound("rbxasset://sounds/electronicpingshort.wav", 0.5)

	TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -160, 0, 22)
	}):Play()

	task.delay(3.2, function()
		if toast.Parent then
			local out = TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, -160, 0, -70)
			})
			out.Completed:Connect(function() toast:Destroy() end)
			out:Play()
		end
	end)
end

-- ─── 3. STATE UPDATE LISTENER ────────────────────────────────────────────────

local lastPawnPosition = 1
local lastPhase = ""

local function tileAt(index: number): BasePart?
	return tilesFolder:FindFirstChild(string.format("Tile_%02d", index))
end

stateUpdated.OnClientEvent:Connect(function(snapshot: any)
	if typeof(snapshot) ~= "table" then return end
	local inMatch = snapshot.phase == "Active" or snapshot.phase == "AwaitRoll"
		or snapshot.phase == "AwaitBuy" or snapshot.phase == "AwaitBuild"
		or snapshot.phase == "AwaitCardChoice"
	if not inMatch then return end

	local mySeat = 0
	if typeof(snapshot.players) == "table" then
		for s, p in ipairs(snapshot.players) do
			if p.userId == lp.UserId then
				mySeat = s
				break
			end
		end
	end
	if mySeat == 0 then return end

	local myPlayer = snapshot.players[mySeat]
	if not myPlayer then return end

	local currentPos = myPlayer.position or 1
	if currentPos ~= lastPawnPosition then
		local prevPos = lastPawnPosition
		lastPawnPosition = currentPos

		local tile = tileAt(currentPos)
		if tile then
			local kind = tile:GetAttribute("TileKind")
			if kind == "Court" and not isCourtQTEActive then
				startCourtMiniGame(function(_isFree)
					-- Mini-game diselesaikan pemain
				end)
			elseif kind == "Parking" then
				showParkingAlert()
			end
		end
	end
end)
