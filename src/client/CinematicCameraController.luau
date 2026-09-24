--!strict
-- CinematicCameraController.luau
-- Kamera aksi dinamis saat lempar dadu, evakuasi Bekasi, Lapas, serta mode penonton (spectator) interaktif.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local sharedFolder = ReplicatedStorage:WaitForChild("WNI", 10)
if not sharedFolder then return end
local remotes = sharedFolder:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10) :: RemoteEvent
local requestAction = remotes:WaitForChild("RequestAction", 10) :: RemoteEvent?
local cheerRemote = remotes:WaitForChild("SpectatorCheer", 10) :: RemoteEvent?
local rulesModule = sharedFolder:FindFirstChild("PrototypeRules")
local Rules = if rulesModule and rulesModule:IsA("ModuleScript") then require(rulesModule) else nil
local gameVersion = if Rules then Rules.Version else "1.5.3"

local board = Workspace:WaitForChild("WNIBoard", 10)
if not board then return end
local pawnsFolder = board:WaitForChild("Pawns", 10)
local tilesFolder = board:WaitForChild("Tiles", 10)

local currentTween: Tween? = nil
local isCinematicActive = false
local spectatorTargetSeat: number? = nil

local function getBoardCenter(): Vector3
	local pivot = board:GetPivot()
	return pivot.Position
end

local function tweenCamera(targetCF: CFrame, duration: number, easingStyle: Enum.EasingStyle?)
	if not camera then return end
	if currentTween then currentTween:Cancel() end
	local style = easingStyle or Enum.EasingStyle.Quad
	currentTween = TweenService:Create(camera, TweenInfo.new(duration, style, Enum.EasingDirection.Out), {
		CFrame = targetCF
	})
	currentTween:Play()
end

local function getPawnPart(seat: number): BasePart?
	if not pawnsFolder then return nil end
	local mini = pawnsFolder:FindFirstChild("MiniMe_" .. seat)
	if mini and mini:IsA("Model") then
		local root = mini.PrimaryPart or mini:FindFirstChild("HumanoidRootPart") or mini:FindFirstChild("Head")
		if root and root:IsA("BasePart") then return root end
	end
	local fallback = pawnsFolder:FindFirstChild("Pawn_" .. seat)
	if fallback and fallback:IsA("BasePart") then return fallback end
	return nil
end

local function getTilePart(index: number): BasePart?
	if not tilesFolder then return nil end
	local t = tilesFolder:FindFirstChild(string.format("Tile_%02d", index))
	if t and t:IsA("BasePart") then return t end
	return nil
end

-- =========================================================================
-- AKSI SINEMATIK DINAMIS
-- =========================================================================

-- Kamera Zoom Lempar Dadu (Dramatic Roll Cam)
local function playDiceRollCam()
	if isCinematicActive then return end
	isCinematicActive = true
	local center = getBoardCenter()
	-- Sudut miring dekat di atas meja dadu tengah
	local diceCamCF = CFrame.new(center + Vector3.new(0, 26, 22), center + Vector3.new(0, 4, 0))
	tweenCamera(diceCamCF, 0.85, Enum.EasingStyle.Back)

	task.delay(1.6, function()
		isCinematicActive = false
	end)
end

-- Kamera Dramatis Masuk Lapas
local function playJailCam(tileIndex: number)
	isCinematicActive = true
	local tile = getTilePart(tileIndex)
	if tile then
		local tPos = tile.Position
		local jailCamCF = CFrame.new(tPos + Vector3.new(0, 10, 14), tPos + Vector3.new(0, 3, 0))
		tweenCamera(jailCamCF, 1.2, Enum.EasingStyle.Sine)
	end
	task.delay(2.2, function()
		isCinematicActive = false
	end)
end

-- Kamera Panorama Evakuasi Bekasi
local function playBekasiCam()
	isCinematicActive = true
	local bekasi = board:FindFirstChild("Decorations") and board.Decorations:FindFirstChild("BekasiDisplay")
	if bekasi and bekasi:IsA("BasePart") then
		local bPos = bekasi.Position
		local bekasiCamCF = CFrame.new(bPos + Vector3.new(12, 16, 12), bPos + Vector3.new(0, 2, 0))
		tweenCamera(bekasiCamCF, 1.5, Enum.EasingStyle.Sine)
	end
	task.delay(2.8, function()
		isCinematicActive = false
	end)
end

-- =========================================================================
-- SPECTATOR MODE (MODE PENONTON)
-- =========================================================================
local playerGui = localPlayer:WaitForChild("PlayerGui")
local spectatorGui: ScreenGui? = nil

local function showCheerBanner(cheererName: string)
	if not spectatorGui then return end
	local banner = Instance.new("Frame")
	banner.Name = "CheerBanner"
	banner.Size = UDim2.new(0, 340, 0, 46)
	banner.Position = UDim2.new(0.5, -170, 0, -60)
	banner.BackgroundColor3 = Color3.fromRGB(26, 20, 36)
	banner.BackgroundTransparency = 0.08
	banner.Parent = spectatorGui
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 23)
	bc.Parent = banner
	local bs = Instance.new("UIStroke")
	bs.Color = Color3.fromRGB(255, 195, 60)
	bs.Thickness = 2
	bs.Parent = banner

	local iconL = Instance.new("TextLabel")
	iconL.Size = UDim2.new(0, 42, 1, 0)
	iconL.Text = "🎉"
	iconL.TextSize = 22
	iconL.BackgroundTransparency = 1
	iconL.Parent = banner

	local textL = Instance.new("TextLabel")
	textL.Size = UDim2.new(1, -50, 1, 0)
	textL.Position = UDim2.new(0, 42, 0, 0)
	textL.Text = tostring(cheererName) .. " bersorak memberi semangat! 👏"
	textL.TextColor3 = Color3.fromRGB(255, 235, 175)
	textL.TextSize = 11
	textL.Font = Enum.Font.GothamBold
	textL.TextXAlignment = Enum.TextXAlignment.Left
	textL.BackgroundTransparency = 1
	textL.Parent = banner

	-- Slide In Anim
	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -170, 0, 16)
	}):Play()

	-- Floating Confetti Dots FX
	local colors = {
		Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 220, 60),
		Color3.fromRGB(90, 220, 255), Color3.fromRGB(120, 255, 140),
		Color3.fromRGB(255, 130, 220)
	}
	for _ = 1, 10 do
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, math.random(5, 8), 0, math.random(5, 8))
		dot.Position = UDim2.new(math.random(15, 85) / 100, 0, 0.5, 0)
		dot.BackgroundColor3 = colors[math.random(1, #colors)]
		dot.Rotation = math.random(0, 360)
		dot.Parent = banner
		local dc = Instance.new("UICorner")
		dc.CornerRadius = UDim.new(0, 3)
		dc.Parent = dot

		local endX = dot.Position.X.Scale + (math.random(-20, 20) / 100)
		local endY = (math.random(-120, 160) / 100)
		TweenService:Create(dot, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(endX, 0, endY, 0),
			BackgroundTransparency = 1,
			Rotation = dot.Rotation + math.random(-180, 180)
		}):Play()
	end

	-- Sound FX
	local s = Instance.new("Sound")
	s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	s.Volume = 0.5
	s.Parent = spectatorGui
	s:Play()
	game:GetService("Debris"):AddItem(s, 2)

	task.delay(3, function()
		if banner.Parent then
			local out = TweenService:Create(banner, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, -170, 0, -60)
			})
			out.Completed:Connect(function() banner:Destroy() end)
			out:Play()
		end
	end)
end

local function createSpectatorUI()
	if spectatorGui then return end
	spectatorGui = Instance.new("ScreenGui")
	spectatorGui.Name = "WNISpectatorUI"
	spectatorGui.ResetOnSpawn = false
	spectatorGui.Parent = playerGui

	local bar = Instance.new("Frame")
	bar.Name = "SpectatorBar"
	bar.Size = UDim2.new(0, 420, 0, 46)
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 68)
	bar.BackgroundColor3 = Color3.fromRGB(18, 24, 32)
	bar.BackgroundTransparency = 0.15
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.Parent = spectatorGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = bar

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(240, 200, 110)
	stroke.Thickness = 2
	stroke.Parent = bar

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0, 110, 1, 0)
	title.Position = UDim2.new(0, 14, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🎥 PENONTON"
	title.TextColor3 = Color3.fromRGB(255, 235, 170)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = bar

	for seat = 1, 4 do
		local btn = Instance.new("TextButton")
		btn.Name = "BtnSeat" .. seat
		btn.Size = UDim2.new(0, 32, 0, 30)
		btn.Position = UDim2.new(0, 128 + (seat - 1) * 36, 0.5, 0)
		btn.AnchorPoint = Vector2.new(0, 0.5)
		btn.BackgroundColor3 = (seat % 2 == 1) and Color3.fromRGB(45, 95, 85) or Color3.fromRGB(115, 65, 45)
		btn.Text = "P" .. seat
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBlack
		btn.TextSize = 12
		btn.Parent = bar

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(1, 0)
		bCorner.Parent = btn

		btn.Activated:Connect(function()
			spectatorTargetSeat = seat
			local targetPart = getPawnPart(seat)
			if targetPart then
				local pPos = targetPart.Position
				tweenCamera(CFrame.new(pPos + Vector3.new(0, 16, 20), pPos), 0.8)
			end
		end)
	end

	-- Tombol Sorak / Cheer
	local cheerBtn = Instance.new("TextButton")
	cheerBtn.Name = "CheerBtn"
	cheerBtn.Size = UDim2.new(0, 96, 0, 32)
	cheerBtn.Position = UDim2.new(1, -10, 0.5, 0)
	cheerBtn.AnchorPoint = Vector2.new(1, 0.5)
	cheerBtn.BackgroundColor3 = Color3.fromRGB(215, 60, 70)
	cheerBtn.Text = "🎉 SORAK!"
	cheerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cheerBtn.Font = Enum.Font.GothamBold
	cheerBtn.TextSize = 12
	cheerBtn.Parent = bar

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(1, 0)
	cCorner.Parent = cheerBtn

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(255, 220, 90)
	cStroke.Thickness = 1.5
	cStroke.Parent = cheerBtn

	local lastCheer = 0
	cheerBtn.Activated:Connect(function()
		local now = os.clock()
		if now - lastCheer < 3 then return end
		lastCheer = now
		if requestAction then
			requestAction:FireServer("SpectatorCheer", 0, gameVersion, nil)
		end
		TweenService:Create(cheerBtn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
			Size = UDim2.new(0, 102, 0, 34)
		}):Play()
	end)

	if cheerRemote then
		cheerRemote.OnClientEvent:Connect(function(_userId: number, cheererName: string)
			showCheerBanner(cheererName)
		end)
	end
end

createSpectatorUI()

-- =========================================================================
-- LISTENER PERUBAHAN STATE
-- =========================================================================
local lastDice = {0, 0}
local lastActiveSeat = 0
local lastSnapshot: any = nil

stateUpdated.OnClientEvent:Connect(function(snapshot)
	if typeof(snapshot) ~= "table" then return end
	local previous = lastSnapshot
	lastSnapshot = snapshot

	-- Cek apakah pemain lokal pemain aktif atau penonton
	local mySeat = 0
	if typeof(snapshot.players) == "table" then
		for s, p in ipairs(snapshot.players) do
			if p.userId == localPlayer.UserId then
				mySeat = s
				break
			end
		end
	end

	-- Tampilkan spectator bar jika pemain tereliminasi atau di lobi menonton match aktif
	if spectatorGui then
		local bar = spectatorGui:FindFirstChild("SpectatorBar")
		if bar and bar:IsA("Frame") then
			local shouldShow = snapshot.phase == "Active" and (mySeat == 0 or (snapshot.players[mySeat] and snapshot.players[mySeat].isEliminated == true))
			bar.Visible = shouldShow
		end
	end

	-- Deteksi Lemparan Dadu Baru
	if typeof(snapshot.dice) == "table" and snapshot.dice[1] and snapshot.dice[1] > 0 then
		if snapshot.dice[1] ~= lastDice[1] or snapshot.dice[2] ~= lastDice[2] then
			lastDice = {snapshot.dice[1], snapshot.dice[2]}
			if not isCinematicActive and snapshot.phase == "Active" then
				playDiceRollCam()
			end
		end
	end

	-- Deteksi Masuk Lapas
	if previous and typeof(previous.players) == "table" and typeof(snapshot.players) == "table" then
		for seat = 1, math.min(#previous.players, #snapshot.players) do
			local prevP = previous.players[seat]
			local curP = snapshot.players[seat]
			if prevP and curP and prevP.inJail ~= true and curP.inJail == true then
				playJailCam(9)
				break
			end
			if prevP and curP and prevP.inBekasi ~= true and curP.inBekasi == true then
				playBekasiCam()
				break
			end
		end
	end
end)
