--!strict
-- CardDeck3DFX.luau
-- Visualisasi 3D Dek Kartu Fisik (Takdir & Musibah) di atas papan WNI Simulator.
-- Menghadirkan prop dek 3D otentik di taman tengah papan + animasi penarikan kartu 3D yang dramatis.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local CardDeck3DFX = {}

local DECK_SPECS = {
	Takdir = {
		name = "TakdirDeck",
		title = "TAKDIR",
		subtitle = "KARTU KESEMPATAN",
		icon = "🔮",
		cardColor = Color3.fromRGB(224, 150, 40),
		trayColor = Color3.fromRGB(45, 35, 25),
		accentColor = Color3.fromRGB(255, 215, 0),
		position = Vector3.new(-8.775, 3.65, 2.0),
		rotation = Vector3.new(0, -15, 0),
	},
	Musibah = {
		name = "MusibahDeck",
		title = "MUSIBAH",
		subtitle = "KARTU TANTANGAN",
		icon = "⚡",
		cardColor = Color3.fromRGB(185, 45, 45),
		trayColor = Color3.fromRGB(35, 25, 25),
		accentColor = Color3.fromRGB(255, 80, 80),
		position = Vector3.new(-8.775, 3.65, 15.0),
		rotation = Vector3.new(0, 15, 0),
	},
}

local function getCardDecksFolder(): Folder?
	local board = Workspace:FindFirstChild("WNIBoard")
	if not board then return nil end
	local decos = board:FindFirstChild("Decorations")
	if not decos then return nil end
	local folder = decos:FindFirstChild("CardDecks")
	if not folder then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "CardDecks"
		newFolder.Parent = decos
		folder = newFolder
	end
	return folder :: Folder
end

local function createDeckProp(spec: typeof(DECK_SPECS.Takdir), parent: Folder): Model
	local model = Instance.new("Model")
	model.Name = spec.name

	-- 1. Base Tray
	local tray = Instance.new("Part")
	tray.Name = "Tray"
	tray.Size = Vector3.new(3.8, 0.25, 5.2)
	tray.CFrame = CFrame.new(spec.position) * CFrame.Angles(0, math.rad(spec.rotation.Y), 0)
	tray.Material = Enum.Material.WoodPlanks
	tray.Color = spec.trayColor
	tray.Anchored = true
	tray.CanCollide = false
	tray.CastShadow = true
	tray.Parent = model

	-- Tray Gold/Silver Rim
	local rim = Instance.new("SelectionBox")
	rim.Color3 = spec.accentColor
	rim.LineThickness = 0.03
	rim.Adornee = tray
	rim.Parent = tray

	-- 2. Card Stack (ivory paper sides)
	local stack = Instance.new("Part")
	stack.Name = "CardStack"
	stack.Size = Vector3.new(3.4, 0.65, 4.8)
	stack.CFrame = tray.CFrame * CFrame.new(0, 0.45, 0)
	stack.Material = Enum.Material.SmoothPlastic
	stack.Color = Color3.fromRGB(246, 242, 232) -- Ivory paper edge
	stack.Anchored = true
	stack.CanCollide = false
	stack.CastShadow = true
	stack.Parent = model

	-- 3. Top Card
	local topCard = Instance.new("Part")
	topCard.Name = "TopCard"
	topCard.Size = Vector3.new(3.42, 0.08, 4.82)
	topCard.CFrame = stack.CFrame * CFrame.new(0, 0.35, 0)
	topCard.Material = Enum.Material.SmoothPlastic
	topCard.Color = spec.cardColor
	topCard.Anchored = true
	topCard.CanCollide = false
	topCard.CastShadow = true
	topCard.Parent = model

	-- SurfaceGui for Card Art
	local sg = Instance.new("SurfaceGui")
	sg.Name = "CardArt"
	sg.Face = Enum.NormalId.Top
	sg.CanvasSize = Vector2.new(340, 480)
	sg.LightInfluence = 0.3
	sg.Parent = topCard

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = spec.cardColor
	frame.BorderSizePixel = 0
	frame.Parent = sg

	local stroke = Instance.new("UIStroke")
	stroke.Color = spec.accentColor
	stroke.Thickness = 5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame

	local innerFrame = Instance.new("Frame")
	innerFrame.Size = UDim2.new(1, -24, 1, -24)
	innerFrame.Position = UDim2.fromScale(0.5, 0.5)
	innerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	innerFrame.BackgroundTransparency = 0.85
	innerFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	innerFrame.BorderSizePixel = 0
	innerFrame.Parent = frame

	local innerStroke = Instance.new("UIStroke")
	innerStroke.Color = spec.accentColor
	innerStroke.Thickness = 1.5
	innerStroke.Parent = innerFrame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.fromScale(1, 0.35)
	iconLabel.Position = UDim2.fromScale(0.5, 0.28)
	iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = spec.icon
	iconLabel.TextSize = 58
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.fromScale(0.9, 0.2)
	titleLabel.Position = UDim2.fromScale(0.5, 0.6)
	titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = spec.title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextSize = 28
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.Parent = frame

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.new(0, 0, 0)
	titleStroke.Thickness = 2.5
	titleStroke.Parent = titleLabel

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.Size = UDim2.fromScale(0.9, 0.12)
	subtitleLabel.Position = UDim2.fromScale(0.5, 0.78)
	subtitleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = spec.subtitle
	subtitleLabel.TextColor3 = spec.accentColor
	subtitleLabel.TextSize = 13
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.Parent = frame

	-- Subtle ambient particle emitter
	local att = Instance.new("Attachment")
	att.Position = Vector3.new(0, 0.2, 0)
	att.Parent = topCard

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Aura"
	emitter.Rate = 2.5
	emitter.Lifetime = NumberRange.new(1.2, 2.0)
	emitter.Speed = NumberRange.new(0.2, 0.6)
	emitter.SpreadAngle = Vector2.new(20, 20)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.5, 0.28),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Color = ColorSequence.new(spec.accentColor)
	emitter.LightEmission = 0.8
	emitter.Parent = att

	model.PrimaryPart = tray
	model.Parent = parent
	return model
end

-- Pastikan kedua dek fisik Takdir & Musibah ada di papan
function CardDeck3DFX.ensureDecks(): boolean
	local folder = getCardDecksFolder()
	if not folder then return false end

	for key, spec in pairs(DECK_SPECS) do
		local existing = folder:FindFirstChild(spec.name)
		if not existing then
			createDeckProp(spec, folder)
		end
	end
	return true
end

-- Animasi saat kartu ditarik
function CardDeck3DFX.animateDraw(deckType: string, cardName: string, customDuration: number?)
	local folder = getCardDecksFolder()
	if not folder then return end

	local cleanType = if deckType:lower():find("musibah") or deckType:lower():find("disaster") then "Musibah" else "Takdir"
	local spec = DECK_SPECS[cleanType]
	local deckModel = folder:FindFirstChild(spec.name)
	if not deckModel or not deckModel:IsA("Model") then return end

	local topCard = deckModel:FindFirstChild("TopCard") :: BasePart?
	if not topCard then return end

	-- Buat kartu animasi yang melayang
	local flyingCard = topCard:Clone()
	flyingCard.Name = "FloatingCardDraw"
	flyingCard.CanCollide = false
	flyingCard.Anchored = true
	flyingCard.CFrame = topCard.CFrame
	flyingCard.Parent = folder

	-- Ubah teks kartu menjadi nama kartu yang ditarik
	local sg = flyingCard:FindFirstChild("CardArt") :: SurfaceGui?
	if sg then
		local frame = sg:FindFirstChildOfClass("Frame")
		if frame then
			local title = frame:FindFirstChild("Title") :: TextLabel?
			if title then
				title.Text = cardName
				title.TextSize = if #cardName > 14 then 20 else 24
			end
			local subtitle = frame:FindFirstChild("Subtitle") :: TextLabel?
			if subtitle then
				subtitle.Text = "KARTU TERPILIH"
			end
		end
	end

	-- Sound whoosh / snap
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.45
	sound.PlaybackSpeed = if cleanType == "Takdir" then 1.25 else 0.95
	sound.Parent = flyingCard
	sound:Play()

	-- Sparkle burst attachment
	local att = flyingCard:FindFirstChildOfClass("Attachment")
	if att then
		local burstEmitter = Instance.new("ParticleEmitter")
		burstEmitter.Rate = 0
		burstEmitter.Lifetime = NumberRange.new(0.8, 1.4)
		burstEmitter.Speed = NumberRange.new(3.0, 5.5)
		burstEmitter.SpreadAngle = Vector2.new(180, 180)
		burstEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 0),
		})
		burstEmitter.Color = ColorSequence.new(spec.accentColor)
		burstEmitter.LightEmission = 1.0
		burstEmitter.Parent = att
		burstEmitter:Emit(16)
	end

	-- Phase 1: Lift & Tilt towards center
	local targetCFrame = flyingCard.CFrame * CFrame.new(0, 3.2, 0) * CFrame.Angles(math.rad(22), 0, 0)
	local tweenUp = TweenService:Create(
		flyingCard,
		TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{CFrame = targetCFrame}
	)
	tweenUp:Play()

	-- Phase 2: Gentle hover float for 2.2s
	task.delay(0.45, function()
		if not flyingCard:IsDescendantOf(Workspace) then return end
		local hoverCFrame = targetCFrame * CFrame.new(0, 0.4, 0)
		local tweenHover = TweenService:Create(
			flyingCard,
			TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{CFrame = hoverCFrame}
		)
		tweenHover:Play()

		-- Phase 3: Dissolve / Fade out
		local totalHold = customDuration or 2.4
		task.delay(totalHold, function()
			if not flyingCard:IsDescendantOf(Workspace) then return end
			tweenHover:Cancel()
			local fadeOut = TweenService:Create(
				flyingCard,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Transparency = 1, CFrame = flyingCard.CFrame * CFrame.new(0, 1.0, 0)}
			)
			fadeOut:Play()
			Debris:AddItem(flyingCard, 0.4)
		end)
	end)
end

return CardDeck3DFX
