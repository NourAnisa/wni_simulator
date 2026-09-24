--!strict
-- EndgameFX (client): bankruptcy doom FX + victory confetti celebration. Visual+audio only.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local EndgameFX = {}

local TEAM_PALETTE: {[string]: {Color3}} = {
	A = {Color3.fromRGB(80, 200, 160), Color3.fromRGB(90, 215, 255), Color3.fromRGB(255, 208, 84)},
	B = {Color3.fromRGB(255, 130, 90), Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 208, 84)},
	SULTAN = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 255), Color3.fromRGB(245, 185, 45)},
}

local function tempAnchor(position: Vector3, life: number): BasePart
	local part = Instance.new("Part")
	part.Name = "EndgameFX_Anchor"
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Position = position
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = Workspace
	Debris:AddItem(part, life)
	return part
end

local function getUISound(soundName: string): Sound?
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer and localPlayer:FindFirstChild("PlayerGui")
	local gameUI = playerGui and playerGui:FindFirstChild("WNIGameUI")
	local uiSounds = gameUI and gameUI:FindFirstChild("UISounds")
	if not uiSounds then
		local starterUI = game:GetService("StarterGui"):FindFirstChild("WNIGameUI")
		uiSounds = starterUI and starterUI:FindFirstChild("UISounds")
	end
	if uiSounds then
		local found = uiSounds:FindFirstChild(soundName)
		if found and found:IsA("Sound") then
			return found
		end
	end
	return nil
end

local function playSoundAt(soundName: string, parentPart: Instance, life: number)
	local template = getUISound(soundName)
	if template and template.SoundId ~= "" then
		local voice = template:Clone()
		voice.Looped = false
		voice.Parent = parentPart
		voice:Play()
		Debris:AddItem(voice, life)
	end
end

-- =========================================================================
-- BANKRUPTCY FX
-- =========================================================================
function EndgameFX.playBankruptcy(target: Instance, playerName: string?)
	local pos: Vector3
	if target:IsA("BasePart") then
		pos = target.Position
	elseif target:IsA("Model") then
		pos = target:GetPivot().Position
	else
		return
	end

	local anchor = tempAnchor(pos + Vector3.new(0, 1.2, 0), 4)

	-- Asap Hitam Pekat (Dark smoke burst)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "BankruptcySmoke"
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(35, 35, 40))
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(0.4, 3.0),
		NumberSequenceKeypoint.new(1, 4.5),
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.6, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.Lifetime = NumberRange.new(1.2, 2.0)
	smoke.Rate = 0
	smoke.Speed = NumberRange.new(3, 7)
	smoke.SpreadAngle = Vector2.new(45, 45)
	smoke.Acceleration = Vector3.new(0, 4, 0)
	smoke.Parent = anchor
	smoke:Emit(30)

	-- Floating BillboardGui "💀 BANGKRUT!"
	local bb = Instance.new("BillboardGui")
	bb.Name = "BankruptcyGui"
	bb.Size = UDim2.new(0, 240, 0, 75)
	bb.StudsOffset = Vector3.new(0, 1.5, 0)
	bb.AlwaysOnTop = true
	bb.Parent = anchor

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.6, 0)
	title.BackgroundTransparency = 1
	title.Text = "💀 BANGKRUT!"
	title.TextColor3 = Color3.fromRGB(255, 65, 65)
	title.TextStrokeColor3 = Color3.fromRGB(15, 10, 10)
	title.TextStrokeTransparency = 0
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.Parent = bb

	local sub = Instance.new("TextLabel")
	sub.Name = "PlayerName"
	sub.Size = UDim2.new(1, 0, 0.4, 0)
	sub.Position = UDim2.new(0, 0, 0.6, 0)
	sub.BackgroundTransparency = 1
	sub.Text = playerName or "Peserta Tereliminasi"
	sub.TextColor3 = Color3.fromRGB(220, 220, 220)
	sub.TextStrokeColor3 = Color3.fromRGB(15, 10, 10)
	sub.TextStrokeTransparency = 0.2
	sub.TextScaled = true
	sub.Font = Enum.Font.GothamBold
	sub.Parent = bb

	-- Animasi Naik & Fade Out
	local riseTween = TweenService:Create(bb, TweenInfo.new(2.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 4.8, 0)
	})
	riseTween:Play()

	task.delay(1.4, function()
		if title.Parent then
			TweenService:Create(title, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			}):Play()
		end
		if sub.Parent then
			TweenService:Create(sub, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			}):Play()
		end
	end)

	-- Audio Kekalahan / Gugur
	playSoundAt("LoseJingle", anchor, 4)
end

-- =========================================================================
-- VICTORY CELEBRATION FX
-- =========================================================================
function EndgameFX.playVictory(winningTeam: string, centerPos: Vector3?)
	local pos = centerPos
	if not pos then
		local board = Workspace:FindFirstChild("WNIBoard")
		local tiles = board and board:FindFirstChild("Tiles")
		if tiles then
			local sum = Vector3.zero
			local count = 0
			for _, t in ipairs(tiles:GetChildren()) do
				if t:IsA("BasePart") then
					sum += t.Position
					count += 1
				end
			end
			if count > 0 then
				pos = sum / count
			end
		end
	end
	pos = pos or Vector3.new(9.2, 4.0, 8.6)

	local anchor = tempAnchor(pos + Vector3.new(0, 5.0, 0), 7)

	local colors = TEAM_PALETTE[winningTeam] or {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 255), Color3.fromRGB(100, 200, 255)}

	-- Air Mancur Konfeti (Fountain Confetti)
	for i, col in ipairs(colors) do
		local confetti = Instance.new("ParticleEmitter")
		confetti.Name = "Confetti_" .. tostring(i)
		confetti.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		confetti.Color = ColorSequence.new(col)
		confetti.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(0.5, 1.4),
			NumberSequenceKeypoint.new(1, 0.4),
		})
		confetti.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.8, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		confetti.Lifetime = NumberRange.new(2.5, 3.8)
		confetti.Rate = 0
		confetti.Speed = NumberRange.new(20, 35)
		confetti.SpreadAngle = Vector2.new(50, 50)
		confetti.Acceleration = Vector3.new(0, -22, 0)
		confetti.Drag = 0.5
		confetti.Parent = anchor

		task.spawn(function()
			for _ = 1, 4 do
				if not anchor:IsDescendantOf(Workspace) then break end
				confetti:Emit(35)
				task.wait(0.6)
			end
		end)
	end

	-- Billboard Kemenangan Akbar
	local bb = Instance.new("BillboardGui")
	bb.Name = "VictoryBanner"
	bb.Size = UDim2.new(0, 360, 0, 110)
	bb.StudsOffset = Vector3.new(0, 3.0, 0)
	bb.AlwaysOnTop = true
	bb.Parent = anchor

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.BackgroundTransparency = 1
	title.Text = "🏆 KEMENANGAN AKBAR! 🏆"
	title.TextColor3 = Color3.fromRGB(255, 220, 60)
	title.TextStrokeColor3 = Color3.fromRGB(20, 15, 5)
	title.TextStrokeTransparency = 0
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.Parent = bb

	local sub = Instance.new("TextLabel")
	sub.Name = "TeamName"
	sub.Size = UDim2.new(1, 0, 0.45, 0)
	sub.Position = UDim2.new(0, 0, 0.55, 0)
	sub.BackgroundTransparency = 1
	sub.Text = if winningTeam == "SULTAN" then "👑 SULTAN TERKAYA NUSANTARA! 👑" else ("SELAMAT KEPADA TIM " .. winningTeam .. "!")
	sub.TextColor3 = colors[1]
	sub.TextStrokeColor3 = Color3.fromRGB(20, 15, 5)
	sub.TextStrokeTransparency = 0
	sub.TextScaled = true
	sub.Font = Enum.Font.GothamBold
	sub.Parent = bb

	-- Animasi Banner Melayang & Berdenyut
	TweenService:Create(bb, TweenInfo.new(3.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 7.5, 0)
	}):Play()

	task.delay(4.5, function()
		if title.Parent then
			TweenService:Create(title, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			}):Play()
		end
		if sub.Parent then
			TweenService:Create(sub, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			}):Play()
		end
	end)

	-- Audio Fanfare Kemenangan
	playSoundAt("WinJingle", anchor, 6)
end

return EndgameFX
