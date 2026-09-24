--!strict
-- EmoteWheelController.luau
-- Antarmuka interaktif pemilih emotikon & chat cepat (Quick Chat) untuk pemain WNI Simulator.
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
local QUICK_CHATS = {
	"Sewa please! 😭",
	"Monopoli kita! 👑",
	"Pungli lagi?! 💸",
	"Hoki banget! 🔥",
	"Ampun bang! 🙏",
	"GGWP! 🏆",
	"Begal nih bos! 💀",
	"Kabur dulu ah! 💨",
}
local SOUND_LIST = {
	"🎺 Telolet Basuri!",
	"🚨 Sirine KPK!",
	"🔨 Palu Hakim!",
	"🥳 Horeee Menang!",
	"💦 Kecebur Kali!",
	"🛵 Priiit Parkir!",
}

-- Buat GUI Pemilih Emotikon & Chat Cepat
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
triggerBtn.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
triggerBtn.BackgroundTransparency = 0.1
triggerBtn.Text = "💬"
triggerBtn.TextSize = 22
triggerBtn.Font = Enum.Font.GothamBold
triggerBtn.Parent = screenGui

local triggerCorner = Instance.new("UICorner")
triggerCorner.CornerRadius = UDim.new(1, 0)
triggerCorner.Parent = triggerBtn

local triggerStroke = Instance.new("UIStroke")
triggerStroke.Color = Color3.fromRGB(255, 215, 60)
triggerStroke.Thickness = 2.0
triggerStroke.Parent = triggerBtn

-- 2. Panel Palet
local palette = Instance.new("Frame")
palette.Name = "EmotePalette"
palette.Size = UDim2.fromOffset(270, 230)
palette.Position = UDim2.new(1, -300, 1, -425)
palette.BackgroundColor3 = Color3.fromRGB(16, 22, 36)
palette.BackgroundTransparency = 0.05
palette.Visible = false
palette.Parent = screenGui

local paletteCorner = Instance.new("UICorner")
paletteCorner.CornerRadius = UDim.new(0, 16)
paletteCorner.Parent = palette

local paletteStroke = Instance.new("UIStroke")
paletteStroke.Color = Color3.fromRGB(255, 215, 60)
paletteStroke.Thickness = 2.0
paletteStroke.Parent = palette

local paletteScale = Instance.new("UIScale")
paletteScale.Scale = 0.01
paletteScale.Parent = palette

-- Tab Bar
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -16, 0, 32)
tabBar.Position = UDim2.new(0, 8, 0, 8)
tabBar.BackgroundTransparency = 1
tabBar.Parent = palette

local emojiTabBtn = Instance.new("TextButton")
emojiTabBtn.Name = "EmojiTab"
emojiTabBtn.Size = UDim2.new(0.33, -3, 1, 0)
emojiTabBtn.Position = UDim2.new(0, 0, 0, 0)
emojiTabBtn.BackgroundColor3 = Color3.fromRGB(230, 175, 30)
emojiTabBtn.Text = "EMOJI"
emojiTabBtn.TextColor3 = Color3.fromRGB(15, 20, 30)
emojiTabBtn.Font = Enum.Font.GothamBold
emojiTabBtn.TextSize = 11
emojiTabBtn.Parent = tabBar
local etc = Instance.new("UICorner"); etc.CornerRadius = UDim.new(0, 8); etc.Parent = emojiTabBtn

local chatTabBtn = Instance.new("TextButton")
chatTabBtn.Name = "ChatTab"
chatTabBtn.Size = UDim2.new(0.33, -3, 1, 0)
chatTabBtn.Position = UDim2.new(0.33, 1, 0, 0)
chatTabBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
chatTabBtn.Text = "CHAT"
chatTabBtn.TextColor3 = Color3.fromRGB(180, 200, 230)
chatTabBtn.Font = Enum.Font.GothamBold
chatTabBtn.TextSize = 11
chatTabBtn.Parent = tabBar
local ctc = Instance.new("UICorner"); ctc.CornerRadius = UDim.new(0, 8); ctc.Parent = chatTabBtn

local soundTabBtn = Instance.new("TextButton")
soundTabBtn.Name = "SoundTab"
soundTabBtn.Size = UDim2.new(0.34, -3, 1, 0)
soundTabBtn.Position = UDim2.new(0.66, 2, 0, 0)
soundTabBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
soundTabBtn.Text = "SUARA 📢"
soundTabBtn.TextColor3 = Color3.fromRGB(180, 200, 230)
soundTabBtn.Font = Enum.Font.GothamBold
soundTabBtn.TextSize = 10
soundTabBtn.Parent = tabBar
local stc = Instance.new("UICorner"); stc.CornerRadius = UDim.new(0, 8); stc.Parent = soundTabBtn

-- Container Emoji
local emojiContainer = Instance.new("Frame")
emojiContainer.Name = "EmojiContainer"
emojiContainer.Size = UDim2.new(1, -16, 1, -52)
emojiContainer.Position = UDim2.new(0, 8, 0, 46)
emojiContainer.BackgroundTransparency = 1
emojiContainer.Visible = true
emojiContainer.Parent = palette

local emojiGrid = Instance.new("UIGridLayout")
emojiGrid.CellSize = UDim2.fromOffset(54, 54)
emojiGrid.CellPadding = UDim2.fromOffset(6, 6)
emojiGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
emojiGrid.VerticalAlignment = Enum.VerticalAlignment.Center
emojiGrid.Parent = emojiContainer

-- Container Quick Chat
local chatContainer = Instance.new("ScrollingFrame")
chatContainer.Name = "ChatContainer"
chatContainer.Size = UDim2.new(1, -16, 1, -52)
chatContainer.Position = UDim2.new(0, 8, 0, 46)
chatContainer.BackgroundTransparency = 1
chatContainer.ScrollBarThickness = 4
chatContainer.ScrollBarImageColor3 = Color3.fromRGB(230, 175, 30)
chatContainer.CanvasSize = UDim2.new(0, 0, 0, #QUICK_CHATS * 36)
chatContainer.Visible = false
chatContainer.Parent = palette

local chatList = Instance.new("UIListLayout")
chatList.Padding = UDim.new(0, 5)
chatList.HorizontalAlignment = Enum.HorizontalAlignment.Center
chatList.Parent = chatContainer

-- Container Suara Meme
local soundContainer = Instance.new("ScrollingFrame")
soundContainer.Name = "SoundContainer"
soundContainer.Size = UDim2.new(1, -16, 1, -52)
soundContainer.Position = UDim2.new(0, 8, 0, 46)
soundContainer.BackgroundTransparency = 1
soundContainer.ScrollBarThickness = 4
soundContainer.ScrollBarImageColor3 = Color3.fromRGB(230, 175, 30)
soundContainer.CanvasSize = UDim2.new(0, 0, 0, #SOUND_LIST * 36)
soundContainer.Visible = false
soundContainer.Parent = palette

local soundList = Instance.new("UIListLayout")
soundList.Padding = UDim.new(0, 5)
soundList.HorizontalAlignment = Enum.HorizontalAlignment.Center
soundList.Parent = soundContainer

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

-- Tab Switch
local function switchTab(tabIndex: number)
	playClickSound()
	emojiContainer.Visible = tabIndex == 1
	chatContainer.Visible = tabIndex == 2
	soundContainer.Visible = tabIndex == 3

	emojiTabBtn.BackgroundColor3 = if tabIndex == 1 then Color3.fromRGB(230, 175, 30) else Color3.fromRGB(35, 45, 65)
	emojiTabBtn.TextColor3 = if tabIndex == 1 then Color3.fromRGB(15, 20, 30) else Color3.fromRGB(180, 200, 230)

	chatTabBtn.BackgroundColor3 = if tabIndex == 2 then Color3.fromRGB(230, 175, 30) else Color3.fromRGB(35, 45, 65)
	chatTabBtn.TextColor3 = if tabIndex == 2 then Color3.fromRGB(15, 20, 30) else Color3.fromRGB(180, 200, 230)

	soundTabBtn.BackgroundColor3 = if tabIndex == 3 then Color3.fromRGB(230, 175, 30) else Color3.fromRGB(35, 45, 65)
	soundTabBtn.TextColor3 = if tabIndex == 3 then Color3.fromRGB(15, 20, 30) else Color3.fromRGB(180, 200, 230)
end

emojiTabBtn.Activated:Connect(function() switchTab(1) end)
chatTabBtn.Activated:Connect(function() switchTab(2) end)
soundTabBtn.Activated:Connect(function() switchTab(3) end)

triggerBtn.Activated:Connect(function()
	playClickSound()
	setPaletteOpen(not isOpen)
end)

-- Tombol Tiap Emoji
for _, emoji in ipairs(EMOJI_LIST) do
	local btn = Instance.new("TextButton")
	btn.Name = "Emoji_" .. emoji
	btn.BackgroundColor3 = Color3.fromRGB(28, 36, 54)
	btn.BackgroundTransparency = 0.2
	btn.Text = emoji
	btn.TextSize = 24
	btn.Font = Enum.Font.GothamBold
	btn.Parent = emojiContainer

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = btn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(50, 65, 95)
	btnStroke.Thickness = 1.2
	btnStroke.Parent = btn

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(45, 60, 90)
		btnStroke.Color = Color3.fromRGB(255, 215, 80)
	end)

	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(28, 36, 54)
		btnStroke.Color = Color3.fromRGB(50, 65, 95)
	end)

	btn.Activated:Connect(function()
		playClickSound()
		emoteRemote:FireServer(emoji)
		setPaletteOpen(false)
	end)
end

-- Tombol Tiap Chat Cepat
for _, chatText in ipairs(QUICK_CHATS) do
	local btn = Instance.new("TextButton")
	btn.Name = "Chat_" .. chatText
	btn.Size = UDim2.new(1, -8, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(28, 36, 54)
	btn.BackgroundTransparency = 0.2
	btn.Text = "  " .. chatText
	btn.TextColor3 = Color3.fromRGB(240, 245, 255)
	btn.TextSize = 12
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Font = Enum.Font.GothamBold
	btn.Parent = chatContainer

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(50, 65, 95)
	btnStroke.Thickness = 1.0
	btnStroke.Parent = btn

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(45, 60, 90)
		btnStroke.Color = Color3.fromRGB(255, 215, 80)
	end)

	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(28, 36, 54)
		btnStroke.Color = Color3.fromRGB(50, 65, 95)
	end)

	btn.Activated:Connect(function()
		playClickSound()
		emoteRemote:FireServer(chatText)
		setPaletteOpen(false)
	end)
end

-- Tombol Tiap Suara Meme
for _, soundText in ipairs(SOUND_LIST) do
	local btn = Instance.new("TextButton")
	btn.Name = "Sound_" .. soundText
	btn.Size = UDim2.new(1, -8, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(28, 36, 54)
	btn.BackgroundTransparency = 0.2
	btn.Text = "  " .. soundText
	btn.TextColor3 = Color3.fromRGB(255, 230, 150)
	btn.TextSize = 12
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Font = Enum.Font.GothamBold
	btn.Parent = soundContainer

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(70, 60, 40)
	btnStroke.Thickness = 1.0
	btnStroke.Parent = btn

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(55, 50, 35)
		btnStroke.Color = Color3.fromRGB(255, 215, 80)
	end)

	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(28, 36, 54)
		btnStroke.Color = Color3.fromRGB(70, 60, 40)
	end)

	btn.Activated:Connect(function()
		playClickSound()
		emoteRemote:FireServer(soundText)
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
