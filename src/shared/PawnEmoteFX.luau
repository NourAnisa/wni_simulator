--!strict
-- PawnEmoteFX (client): overhead reaction emoji bubbles for pawns and avatar models. Visual+audio only.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local PawnEmoteFX = {}

local function findPawnPart(pawnOrSeat: Instance | number): BasePart?
	if typeof(pawnOrSeat) == "number" then
		local board = Workspace:FindFirstChild("WNIBoard")
		local pawnsFolder = board and board:FindFirstChild("Pawns")
		if not pawnsFolder then return nil end

		local miniMe = pawnsFolder:FindFirstChild("MiniMe_" .. tostring(pawnOrSeat))
		if miniMe and miniMe:IsA("Model") then
			local root = miniMe.PrimaryPart or miniMe:FindFirstChild("HumanoidRootPart") or miniMe:FindFirstChild("Head")
			if root and root:IsA("BasePart") then return root end
		end

		local fallback = pawnsFolder:FindFirstChild("Pawn_" .. tostring(pawnOrSeat))
		if fallback and fallback:IsA("BasePart") then return fallback end
		return nil
	elseif typeof(pawnOrSeat) == "Instance" then
		if pawnOrSeat:IsA("BasePart") then
			return pawnOrSeat
		elseif pawnOrSeat:IsA("Model") then
			local root = pawnOrSeat.PrimaryPart or pawnOrSeat:FindFirstChild("HumanoidRootPart") or pawnOrSeat:FindFirstChild("Head")
			if root and root:IsA("BasePart") then return root end
			return pawnOrSeat:FindFirstChildWhichIsA("BasePart", true)
		end
	end
	return nil
end

function PawnEmoteFX.showEmote(pawnOrSeat: Instance | number, emojiText: string, bubbleColor: Color3?)
	local targetPart = findPawnPart(pawnOrSeat)
	if not targetPart or not targetPart:IsDescendantOf(Workspace) then return end

	local isQuickChat = #emojiText > 4
	local textLen = utf8.len(emojiText) or #emojiText
	local bubbleWidth = if isQuickChat then math.clamp(textLen * 11 + 36, 110, 220) else 58
	local bubbleHeight = if isQuickChat then 42 else 58

	local bb = Instance.new("BillboardGui")
	bb.Name = "EmoteBubble_" .. emojiText
	bb.Adornee = targetPart
	bb.Size = UDim2.new(0, bubbleWidth, 0, bubbleHeight)
	bb.StudsOffset = Vector3.new(0, 3.4, 0)
	bb.AlwaysOnTop = true
	bb.Parent = targetPart
	Debris:AddItem(bb, 2.8)

	local bubble = Instance.new("Frame")
	bubble.Name = "Bubble"
	bubble.Size = UDim2.new(1, 0, 1, 0)
	bubble.AnchorPoint = Vector2.new(0.5, 0.5)
	bubble.Position = UDim2.new(0.5, 0, 0.5, 0)
	bubble.BackgroundColor3 = bubbleColor or Color3.fromRGB(24, 28, 38)
	bubble.BorderSizePixel = 0
	bubble.Parent = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = if isQuickChat then UDim.new(0, 12) else UDim.new(1, 0)
	corner.Parent = bubble

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 60)
	stroke.Thickness = 2.0
	stroke.Parent = bubble

	local label = Instance.new("TextLabel")
	label.Name = "Emoji"
	label.Size = UDim2.new(0.9, 0, 0.85, 0)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(0.5, 0, 0.5, 0)
	label.BackgroundTransparency = 1
	label.Text = emojiText
	label.TextScaled = not isQuickChat
	label.TextSize = if isQuickChat then 14 else 28
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.Parent = bubble

	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = bubble

	-- Animasi Pop Bounce-in (0 -> 1.25 -> 1.0)
	local popTween = TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.0})
	popTween:Play()

	-- Mengambang perlahan ke atas (StudsOffset)
	local floatTween = TweenService:Create(bb, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 4.9, 0)
	})
	floatTween:Play()

	-- Suara pop ceria
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/switch.wav"
	sound.Volume = 0.35
	sound.PlaybackSpeed = 1.45 + (math.random() * 0.2)
	sound.Parent = targetPart
	sound:Play()
	Debris:AddItem(sound, 1.5)

	-- Fade Out di 0.5 detik terakhir
	task.delay(1.3, function()
		if bubble.Parent then
			TweenService:Create(bubble, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
			TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
		end
	end)
end

return PawnEmoteFX
