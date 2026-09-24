--!strict
-- SpectatorController.luau (LocalScript)
-- Mode Penonton "Ronda Malam / CCTV RT" untuk pemain yang tereliminasi atau menonton match:
-- Memberikan panel reaksi penonton (Tomat Busuk 🍅, Tabur Bunga 🌸, Kopi Ronda ☕) dengan efek 3D.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
local cheerRemote = remotes:WaitForChild("SpectatorCheer", 10)
local requestAction = remotes:WaitForChild("RequestAction", 10)
if not stateUpdated or not cheerRemote then return end

local rulesModule = shared:WaitForChild("PrototypeRules", 10)
local Rules = if rulesModule and rulesModule:IsA("ModuleScript") then require(rulesModule) else nil
local currentVersion = if Rules then Rules.Version else "prototype-0.1"

-- Screen GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WNISpectatorUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 14
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

-- Panel Penonton
local specBar = Instance.new("Frame")
specBar.Name = "SpectatorBar"
specBar.Size = UDim2.fromOffset(320, 46)
specBar.Position = UDim2.new(0.5, 0, 1, -75)
specBar.AnchorPoint = Vector2.new(0.5, 1)
specBar.BackgroundColor3 = Color3.fromRGB(18, 24, 36)
specBar.BackgroundTransparency = 0.15
specBar.Visible = false
specBar.Parent = screenGui

local sbc = Instance.new("UICorner"); sbc.CornerRadius = UDim.new(0, 14); sbc.Parent = specBar
local sbs = Instance.new("UIStroke"); sbs.Color = Color3.fromRGB(255, 215, 60); sbs.Thickness = 1.5; sbs.Parent = specBar

local barTitle = Instance.new("TextLabel")
barTitle.Size = UDim2.new(0, 80, 1, 0)
barTitle.Position = UDim2.new(0, 10, 0, 0)
barTitle.BackgroundTransparency = 1
barTitle.Text = "☕ RONDA:"
barTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
barTitle.Font = Enum.Font.GothamBold
barTitle.TextSize = 11
barTitle.TextXAlignment = Enum.TextXAlignment.Left
barTitle.Parent = specBar

local btnContainer = Instance.new("Frame")
btnContainer.Size = UDim2.new(1, -95, 1, -10)
btnContainer.Position = UDim2.new(0, 85, 0, 5)
btnContainer.BackgroundTransparency = 1
btnContainer.Parent = specBar

local bLayout = Instance.new("UIListLayout")
bLayout.FillDirection = Enum.FillDirection.Horizontal
bLayout.Padding = UDim.new(0, 8)
bLayout.Parent = btnContainer

local REACTIONS = {
	{emoji = "🍅", label = "Tomat", sound = "rbxasset://sounds/splat.wav", speed = 1.0},
	{emoji = "🌸", label = "Bunga", sound = "rbxasset://sounds/electronicpingshort.wav", speed = 1.2},
	{emoji = "☕", label = "Kopi", sound = "rbxasset://sounds/button.wav", speed = 1.5},
}

local lastRevision = 0

for _, r in ipairs(REACTIONS) do
	local btn = Instance.new("TextButton")
	btn.Name = "React_" .. r.label
	btn.Size = UDim2.fromOffset(68, 36)
	btn.BackgroundColor3 = Color3.fromRGB(28, 38, 56)
	btn.Text = r.emoji .. " " .. r.label
	btn.TextColor3 = Color3.fromRGB(240, 245, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Parent = btnContainer

	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = btn
	local bs = Instance.new("UIStroke"); bs.Color = Color3.fromRGB(60, 80, 110); bs.Thickness = 1.0; bs.Parent = btn

	btn.Activated:Connect(function()
		if requestAction then
			requestAction:FireServer("SpectatorCheer", lastRevision, currentVersion, r.emoji)
		end
	end)
end

-- Menampilkan efek 3D saat SpectatorCheer diterima
cheerRemote.OnClientEvent:Connect(function(userId: number, cheererName: string, reaction: any)
	local emoji = if typeof(reaction) == "string" then reaction else "🌸"

	-- Suara reaksi
	local s = Instance.new("Sound")
	s.SoundId = if emoji == "🍅" then "rbxasset://sounds/splat.wav" elseif emoji == "☕" then "rbxasset://sounds/button.wav" else "rbxasset://sounds/electronicpingshort.wav"
	s.Volume = 0.5
	s.PlaybackSpeed = 1.1
	s.Parent = screenGui
	s:Play()
	Debris:AddItem(s, 1.5)

	-- Floating toast di layar
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.fromOffset(260, 32)
	toast.Position = UDim2.new(0.5, 0, 0.25, 0)
	toast.AnchorPoint = Vector2.new(0.5, 0.5)
	toast.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
	toast.BackgroundTransparency = 0.1
	toast.Text = emoji .. " " .. cheererName .. " melempar reaksi penonton!"
	toast.TextColor3 = Color3.fromRGB(255, 235, 160)
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 12
	toast.Parent = screenGui
	Debris:AddItem(toast, 2.5)

	local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 10); tc.Parent = toast
	local ts = Instance.new("UIStroke"); ts.Color = Color3.fromRGB(255, 215, 60); ts.Thickness = 1.5; ts.Parent = toast

	TweenService:Create(toast, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.18, 0)
	}):Play()
	task.delay(1.5, function()
		if toast.Parent then
			TweenService:Create(toast, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		end
	end)
end)

stateUpdated.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then return end
	lastRevision = payload.revision or lastRevision

	-- Cek apakah local player adalah penonton atau tereliminasi
	if payload.phase == "Waiting" or payload.phase == "Finished" then
		specBar.Visible = false
		return
	end

	local isPlayerActive = false
	if typeof(payload.players) == "table" then
		for _, p in ipairs(payload.players) do
			if p.userId == lp.UserId and not p.eliminated then
				isPlayerActive = true
				break
			end
		end
	end

	-- Jika tidak aktif bermain (tereliminasi atau tamu di server), munculkan panel penonton
	specBar.Visible = not isPlayerActive
end)
