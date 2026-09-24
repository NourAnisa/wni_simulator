--!strict
-- CoinFlipMiniGame.luau
-- Mini-game interaktif 50:50 "Tebak Koin Sultan" (Garuda vs Angka 500).
-- Berada di ReplicatedStorage.WNI agar dapat diakses oleh seluruh client script.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local lp = Players.LocalPlayer

local CoinFlipMiniGame = {}

local activeOverlay: Frame? = nil
local isSpinning = false

local function playSound(parent: Instance, soundId: string, volume: number)
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volume
	s.Parent = parent
	s:Play()
	game:GetService("Debris"):AddItem(s, 3.5)
end

function CoinFlipMiniGame.start(parentGui: ScreenGui, onResult: ((won: boolean, choice: string, winningSide: string) -> ())?)
	if activeOverlay and activeOverlay.Parent then
		activeOverlay:Destroy()
		activeOverlay = nil
	end

	local overlay = Instance.new("Frame")
	overlay.Name = "CoinFlipOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.ZIndex = 50
	overlay.Parent = parentGui
	activeOverlay = overlay

	local modal = Instance.new("Frame")
	modal.Name = "CoinModal"
	modal.Size = UDim2.new(0, 390, 0, 320)
	modal.Position = UDim2.new(0.5, 0, 0.5, 0)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.BackgroundColor3 = Color3.fromRGB(18, 16, 26)
	modal.Parent = overlay

	local mCorner = Instance.new("UICorner")
	mCorner.CornerRadius = UDim.new(0, 20)
	mCorner.Parent = modal

	local mStroke = Instance.new("UIStroke")
	mStroke.Color = Color3.fromRGB(255, 210, 50)
	mStroke.Thickness = 3
	mStroke.Parent = modal

	-- Judul Atas
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 38)
	title.Position = UDim2.new(0, 0, 0, 12)
	title.Text = "🪙 TEBAK KOIN SULTAN 50:50 🪙"
	title.TextColor3 = Color3.fromRGB(255, 220, 60)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.BackgroundTransparency = 1
	title.Parent = modal

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -30, 0, 24)
	subtitle.Position = UDim2.new(0, 15, 0, 48)
	subtitle.Text = "Pilih sisi koin! Tebakan tepat gandakan hadiah taruhanmu!"
	subtitle.TextColor3 = Color3.fromRGB(210, 210, 220)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 11
	subtitle.BackgroundTransparency = 1
	subtitle.Parent = modal

	-- Hitung Mundur Waktu
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Size = UDim2.new(0, 100, 0, 24)
	timerLabel.Position = UDim2.new(0.5, 0, 0, 74)
	timerLabel.AnchorPoint = Vector2.new(0.5, 0)
	timerLabel.BackgroundColor3 = Color3.fromRGB(45, 25, 30)
	timerLabel.Text = "⏱️ 5 DETIK"
	timerLabel.TextColor3 = Color3.fromRGB(255, 110, 110)
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.TextSize = 11
	timerLabel.Parent = modal
	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(0, 12)
	tCorner.Parent = timerLabel

	-- Lingkaran Koin Animasi
	local coinFrame = Instance.new("Frame")
	coinFrame.Name = "CoinDisc"
	coinFrame.Size = UDim2.new(0, 96, 0, 96)
	coinFrame.Position = UDim2.new(0.5, 0, 0, 156)
	coinFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	coinFrame.BackgroundColor3 = Color3.fromRGB(255, 195, 30)
	coinFrame.Parent = modal

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(1, 0)
	cCorner.Parent = coinFrame

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(255, 245, 140)
	cStroke.Thickness = 4
	cStroke.Parent = coinFrame

	local coinSymbol = Instance.new("TextLabel")
	coinSymbol.Name = "CoinSymbol"
	coinSymbol.Size = UDim2.new(1, 0, 1, 0)
	coinSymbol.Text = "🦅"
	coinSymbol.TextSize = 46
	coinSymbol.BackgroundTransparency = 1
	coinSymbol.Parent = coinFrame

	-- Container 2 Tombol Pilihan
	local btnRow = Instance.new("Frame")
	btnRow.Size = UDim2.new(1, -30, 0, 52)
	btnRow.Position = UDim2.new(0, 15, 0, 230)
	btnRow.BackgroundTransparency = 1
	btnRow.Parent = modal

	local garudaBtn = Instance.new("TextButton")
	garudaBtn.Name = "GarudaBtn"
	garudaBtn.Size = UDim2.new(0.48, 0, 1, 0)
	garudaBtn.Position = UDim2.new(0, 0, 0, 0)
	garudaBtn.BackgroundColor3 = Color3.fromRGB(215, 145, 25)
	garudaBtn.Text = "🦅 GARUDA"
	garudaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	garudaBtn.Font = Enum.Font.GothamBold
	garudaBtn.TextSize = 13
	garudaBtn.Parent = btnRow
	local gCorner = Instance.new("UICorner")
	gCorner.CornerRadius = UDim.new(0, 12)
	gCorner.Parent = garudaBtn

	local angkaBtn = Instance.new("TextButton")
	angkaBtn.Name = "AngkaBtn"
	angkaBtn.Size = UDim2.new(0.48, 0, 1, 0)
	angkaBtn.Position = UDim2.new(0.52, 0, 0, 0)
	angkaBtn.BackgroundColor3 = Color3.fromRGB(70, 95, 135)
	angkaBtn.Text = "🪙 ANGKA 500"
	angkaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	angkaBtn.Font = Enum.Font.GothamBold
	angkaBtn.TextSize = 13
	angkaBtn.Parent = btnRow
	local aCorner = Instance.new("UICorner")
	aCorner.CornerRadius = UDim.new(0, 12)
	aCorner.Parent = angkaBtn

	local chosenSide: string? = nil
	local resolved = false

	local function onSelect(choice: string)
		if resolved then return end
		resolved = true
		chosenSide = choice
		garudaBtn.Active = false
		angkaBtn.Active = false

		if choice == "Garuda" then
			garudaBtn.BackgroundColor3 = Color3.fromRGB(255, 190, 40)
			angkaBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 70)
		else
			angkaBtn.BackgroundColor3 = Color3.fromRGB(100, 145, 220)
			garudaBtn.BackgroundColor3 = Color3.fromRGB(55, 45, 30)
		end

		timerLabel.Text = "MEMUTAR..."
		timerLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
		playSound(modal, "rbxasset://sounds/button.wav", 0.7)

		-- Animasi Putaran Koin (Flips)
		isSpinning = true
		task.spawn(function()
			local winningSide = if math.random() > 0.48 then "Garuda" else "Angka"
			local flips = 14
			for i = 1, flips do
				local side = if i % 2 == 1 then "Garuda" else "Angka"
				coinSymbol.Text = if side == "Garuda" then "🦅" else "500"
				coinFrame.BackgroundColor3 = if side == "Garuda" then Color3.fromRGB(255, 195, 30) else Color3.fromRGB(175, 190, 210)
				playSound(modal, "rbxasset://sounds/action_jump.mp3", 0.25)

				local squash = TweenService:Create(coinFrame, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 96, 0, 12),
				})
				squash:Play()
				squash.Completed:Wait()

				local stretch = TweenService:Create(coinFrame, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 96, 0, 96),
				})
				stretch:Play()
				stretch.Completed:Wait()
			end

			coinSymbol.Text = if winningSide == "Garuda" then "🦅" else "500"
			coinFrame.BackgroundColor3 = if winningSide == "Garuda" then Color3.fromRGB(255, 215, 40) else Color3.fromRGB(200, 220, 240)
			isSpinning = false

			local playerWon = (choice == winningSide)
			if playerWon then
				title.Text = "🎉 TEBAKAN TEPAT! MENANG!"
				title.TextColor3 = Color3.fromRGB(100, 255, 140)
				subtitle.Text = "Hasil koin: " .. winningSide .. "! Bonus keberuntungan berhasil diraih!"
				modal.BackgroundColor3 = Color3.fromRGB(16, 36, 24)
				mStroke.Color = Color3.fromRGB(80, 240, 120)
				playSound(modal, "rbxasset://sounds/victory.mp3", 0.8)
			else
				title.Text = "❌ YAH SALAH! ZONK!"
				title.TextColor3 = Color3.fromRGB(255, 110, 110)
				subtitle.Text = "Hasil koin: " .. winningSide .. ". Keberuntungan belum berpihak!"
				modal.BackgroundColor3 = Color3.fromRGB(36, 16, 20)
				mStroke.Color = Color3.fromRGB(240, 80, 80)
				playSound(modal, "rbxasset://sounds/electronicpingshort.wav", 0.6)
			end

			task.delay(2.4, function()
				if overlay.Parent then
					local outTween = TweenService:Create(modal, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						Size = UDim2.new(0, 300, 0, 200),
						BackgroundTransparency = 1,
					})
					outTween.Completed:Connect(function()
						overlay:Destroy()
						activeOverlay = nil
						if onResult then
							onResult(playerWon, choice, winningSide)
						end
					end)
					outTween:Play()
				end
			end)
		end)
	end

	garudaBtn.Activated:Connect(function() onSelect("Garuda") end)
	angkaBtn.Activated:Connect(function() onSelect("Angka") end)

	task.spawn(function()
		for sec = 5, 1, -1 do
			if resolved or not modal.Parent then break end
			timerLabel.Text = string.format("⏱️ %d DETIK", sec)
			task.wait(1.0)
		end
		if not resolved and modal.Parent then
			onSelect(if math.random() > 0.5 then "Garuda" else "Angka")
		end
	end)

	modal.Size = UDim2.new(0, 280, 0, 220)
	TweenService:Create(modal, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 390, 0, 320),
	}):Play()
end

return CoinFlipMiniGame
