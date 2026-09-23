--!strict
-- EmoteWheelController.luau
-- Antarmuka interaktif pemilih emotikon (Emote Wheel) untuk pemain WNI Simulator.
-- Tombol melayang di layar + hotkey keyboard [E] untuk mengekspresikan reaksi komik di atas pion 3D.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
if not localPlayer then return end

local sharedFolder = ReplicatedStorage:WaitForChild("WNI", 10)
if not sharedFolder then return end

local emoteFXModule = sharedFolder:WaitForChild("PawnEmoteFX", 10)
if not emoteFXModule or not emoteFXModule:IsA("ModuleScript") then return end
local PawnEmoteFX = require(emoteFXModule)

local remotes = sharedFolder:WaitForChild("Remotes", 10)
if not remotes then return end

local emoteRemote = remotes:WaitForChild("PlayerEmote", 10)
if not emoteRemote or not emoteRemote:IsA("RemoteEvent") then return end

local EMOJI_LIST = {"😂", "😭", "😎", "🔥", "💀", "👑", "💸", "👋"}

-- Buat GUI Pemilih Emotikon
local playerGui = localPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WNIEmoteUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 15
screenGui.Parent = playerGui

-- 1. Tombol Pemicu Mengambang (Floating Emote Button)
local triggerBtn = Instance.new("TextButton")
triggerBtn.Name = "EmoteTriggerBtn"
triggerBtn.Size = UDim2.fromOffset(48, 48)
triggerBtn.Position = UDim2.new(1, -64, 1, -180)
triggerBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
triggerBtn.BackgroundTransparency = 0.2
triggerBtn.Text = "💬"
triggerBtn.TextSize = 24
triggerBtn.Font = Enum.Font.FredokaOne
triggerBtn.Parent = screenGui

local triggerCorner = Instance.new("UICorner")
triggerCorner.CornerRadius = UDim.new(1, 0)
triggerCorner.Parent = triggerBtn

local triggerStroke = Instance.new("UIStroke")
triggerStroke.Color = Color3.fromRGB(245, 195, 55)
triggerStroke.Thickness = 2.5
triggerStroke.Parent = triggerBtn

-- 2. Panel Palet Emotikon
local palette = Instance.new("Frame")
palette.Name = "EmotePalette"
palette.Size = UDim2.fromOffset(220, 120)
palette.Position = UDim2.new(1, -250, 1, -315)
palette.BackgroundColor3 = Color3.fromRGB(24, 20, 18)
palette.BackgroundTransparency = 0.15
palette.Visible = false
palette.Parent = screenGui

local paletteCorner = Instance.new("UICorner")
paletteCorner.CornerRadius = UDim.new(0, 12)
paletteCorner.Parent = palette

local paletteStroke = Instance.new("UIStroke")
paletteStroke.Color = Color3.fromRGB(245, 195, 55)
paletteStroke.Thickness = 2.5
paletteStroke.Parent = palette

local paletteScale = Instance.new("UIScale")
paletteScale.Scale = 0.01
paletteScale.Parent = palette

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(45, 45)
grid.CellPadding = UDim2.fromOffset(6, 6)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.VerticalAlignment = Enum.VerticalAlignment.Center
grid.Parent = palette

local function playClickSound()
	local s = Instance.new("Sound")
	s.SoundId = "rbxasset://sounds/switch.wav"
	s.Volume = 0.3
	s.PlaybackSpeed = 1.3
	s.Parent = screenGui
	s:Play()
	game:GetService("Debris"):AddItem(s, 0.8)
end

local isOpen = false
local function setPaletteOpen(open: boolean)
	isOpen = open
	if open then
		palette.Visible = true
		paletteScale.Scale = 0.1
		local tween = TweenService:Create(
			paletteScale,
			TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Scale = 1.0}
		)
		tween:Play()
	else
		local tween = TweenService:Create(
			paletteScale,
			TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Scale = 0.01}
		)
		tween:Play()
		tween.Completed:Once(function()
			if not isOpen then
				palette.Visible = false
			end
		end)
	end
end

triggerBtn.Activated:Connect(function()
	playClickSound()
	setPaletteOpen(not isOpen)
end)

-- Tombol Tiap Emoji
for _, emoji in ipairs(EMOJI_LIST) do
	local btn = Instance.new("TextButton")
	btn.Name = "Emoji_" .. emoji
	btn.BackgroundColor3 = Color3.fromRGB(45, 38, 30)
	btn.BackgroundTransparency = 0.4
	btn.Text = emoji
	btn.TextSize = 24
	btn.Font = Enum.Font.FredokaOne
	btn.Parent = palette

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(120, 100, 70)
	btnStroke.Thickness = 1.2
	btnStroke.Parent = btn

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(80, 65, 45)
		btnStroke.Color = Color3.fromRGB(255, 215, 80)
	end)

	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(45, 38, 30)
		btnStroke.Color = Color3.fromRGB(120, 100, 70)
	end)

	btn.Activated:Connect(function()
		playClickSound()
		emoteRemote:FireServer(emoji)
		setPaletteOpen(false)
	end)
end

-- Dukungan Hotkey Keyboard [E]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E then
		playClickSound()
		setPaletteOpen(not isOpen)
	end
end)

-- Penerimaan Reaksi dari Server untuk Ditampilkan di Atas Pion 3D
emoteRemote.OnClientEvent:Connect(function(seat: number, emojiText: string)
	if typeof(seat) == "number" and typeof(emojiText) == "string" then
		PawnEmoteFX.showEmote(seat, emojiText)
	end
end)
