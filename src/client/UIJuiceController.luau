--!strict
-- UIJuiceController.luau
-- Memberikan animasi mikro, hover bounce, press squash, breathing pulse glow,
-- rolling number odometer pada saldo, dan avatar headshot thumbnail dinamis di WNIGameUI.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local localPlayer = Players.LocalPlayer
if not localPlayer then return end

local playerGui = localPlayer:WaitForChild("PlayerGui")
local gameUI = playerGui:WaitForChild("WNIGameUI", 10)
if not gameUI then return end

local root = gameUI:WaitForChild("Root", 10) :: Frame?
if not root then return end

-- 1. Efek Suara Taktil
local function playTactileClick()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/switch.wav"
	sound.Volume = 0.25
	sound.PlaybackSpeed = 1.25 + (math.random() * 0.1)
	sound.Parent = gameUI
	sound:Play()
	Debris:AddItem(sound, 0.6)
end

-- 2. Spring Hover & Press Squash untuk Tombol Interaktif
local function attachButtonJuice(btn: TextButton)
	local scale = btn:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Scale = 1.0
		scale.Parent = btn
	end

	local hoverTween = TweenService:Create(
		scale,
		TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Scale = 1.06}
	)
	local normalTween = TweenService:Create(
		scale,
		TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Scale = 1.0}
	)
	local pressTween = TweenService:Create(
		scale,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Scale = 0.94}
	)

	btn.MouseEnter:Connect(function()
		if btn.Active and btn.Visible then
			hoverTween:Play()
		end
	end)

	btn.MouseLeave:Connect(function()
		normalTween:Play()
	end)

	btn.MouseButton1Down:Connect(function()
		if btn.Active and btn.Visible then
			pressTween:Play()
			playTactileClick()
		end
	end)

	btn.MouseButton1Up:Connect(function()
		hoverTween:Play()
	end)
end

for _, descendant in ipairs(root:GetDescendants()) do
	if descendant:IsA("TextButton") then
		attachButtonJuice(descendant)
	end
end

root.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("TextButton") then
		attachButtonJuice(descendant)
	end
end)

-- 3. Breathing Pulse untuk RollButton (Menarik Perhatian Pemain Saat Giliran Tiba)
local actionPanel = root:FindFirstChild("ActionPanel")
local rollBtn = actionPanel and actionPanel:FindFirstChild("RollButton") :: TextButton?

if rollBtn then
	local scale = rollBtn:FindFirstChildOfClass("UIScale")
	if scale then
		local pulseTween = TweenService:Create(
			scale,
			TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Scale = 1.04}
		)

		rollBtn:GetPropertyChangedSignal("Visible"):Connect(function()
			if rollBtn.Visible and rollBtn.Active then
				pulseTween:Play()
			else
				pulseTween:Cancel()
				scale.Scale = 1.0
			end
		end)

		if rollBtn.Visible and rollBtn.Active then
			pulseTween:Play()
		end
	end
end

-- 4. Dynamic Avatar Headshot Resolver & Rolling Balance Numbers di Roster
local roster = root:FindFirstChild("Roster")
if roster then
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local sharedFolder = ReplicatedStorage:WaitForChild("WNI", 10)
	local remotes = sharedFolder and sharedFolder:WaitForChild("Remotes", 10)
	local stateUpdated = remotes and remotes:WaitForChild("StateUpdated", 10) :: RemoteEvent?

	local displayedCash: {[number]: number} = {}

	local function formatMoney(amount: number): string
		local digits = tostring(math.floor(math.abs(amount)))
		local reversed = string.reverse(digits)
		local grouped = string.gsub(reversed, "(%d%d%d)", "%1.")
		grouped = string.reverse(grouped)
		if string.sub(grouped, 1, 1) == "." then grouped = string.sub(grouped, 2) end
		return (if amount < 0 then "-Rp" else "Rp ") .. grouped
	end

	if stateUpdated then
		stateUpdated.OnClientEvent:Connect(function(snapshot: any)
			if typeof(snapshot) ~= "table" then return end
			local players = snapshot.players
			if typeof(players) ~= "table" then return end

			-- Cari pemain dengan saldo tertinggi untuk mahkota Sultan
			local maxCash = -math.huge
			local richestSeat = -1
			for s = 1, 4 do
				local p = players[s]
				if typeof(p) == "table" and not p.eliminated and (p.cash or 0) > maxCash then
					maxCash = p.cash
					richestSeat = s
				end
			end

			for seat = 1, 4 do
				local seatFrame = roster:FindFirstChild(string.format("Seat%d", seat)) :: Frame?
				local p = players[seat]
				if seatFrame and typeof(p) == "table" then
					-- A. Avatar Headshot
					local avatarImg = seatFrame:FindFirstChild("AvatarIcon") :: ImageLabel?
					if avatarImg then
						if typeof(p.userId) == "number" and p.userId > 0 then
							avatarImg.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", p.userId)
						else
							-- Avatar Bot Robot
							avatarImg.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
						end
					end

					-- B. Crown Icon untuk Pemain Terkaya
					local crown = seatFrame:FindFirstChild("SultanCrown") :: TextLabel?
					if not crown then
						crown = Instance.new("TextLabel")
						crown.Name = "SultanCrown"
						crown.Size = UDim2.fromOffset(20, 20)
						crown.Position = UDim2.new(0, 32, 0, 2)
						crown.BackgroundTransparency = 1
						crown.Text = "👑"
						crown.TextSize = 14
						crown.Parent = seatFrame
					end
					crown.Visible = (seat == richestSeat and maxCash > 0)

					-- C. Rolling Cash Odometer
					local balLabel = seatFrame:FindFirstChild("Balance") :: TextLabel?
					local targetCash = typeof(p.cash) == "number" and p.cash or 0
					local currentCash = displayedCash[seat] or targetCash

					if balLabel and currentCash ~= targetCash then
						local tweenVal = Instance.new("NumberValue")
						tweenVal.Value = currentCash
						local tw = TweenService:Create(
							tweenVal,
							TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{Value = targetCash}
						)
						tw:Play()

						local conn: RBXScriptConnection? = nil
						conn = tweenVal.Changed:Connect(function(v)
							balLabel.Text = formatMoney(math.floor(v))
						end)

						tw.Completed:Once(function()
							if conn then conn:Disconnect() end
							tweenVal:Destroy()
							balLabel.Text = formatMoney(targetCash)
							displayedCash[seat] = targetCash
						end)
					else
						displayedCash[seat] = targetCash
					end
				end
			end
		end)
	end
end
