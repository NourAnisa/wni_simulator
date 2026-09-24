--!strict
-- SoloModeLobbyUI.luau (LocalScript)
-- Tombol pengalih mode permainan di lobi: Mode Tim 2v2 vs Mode Solo Sultan (1v1v1v1 FFA).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
local requestAction = remotes:WaitForChild("RequestAction", 10)
if not stateUpdated or not requestAction then return end

local rulesModule = shared:WaitForChild("PrototypeRules", 10)
local Rules = if rulesModule and rulesModule:IsA("ModuleScript") then require(rulesModule) else nil
local currentVersion = if Rules then Rules.Version else "prototype-0.1"

-- Screen GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WNIGameModeUI"
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

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "GameModeToggleBtn"
toggleBtn.Size = UDim2.fromOffset(200, 36)
toggleBtn.Position = UDim2.new(0, 170, 1, -120)
toggleBtn.BackgroundColor3 = Color3.fromRGB(26, 34, 52)
toggleBtn.Text = "🎮 MODE: 🤝 TIM 2v2"
toggleBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 11
toggleBtn.Visible = false
toggleBtn.Parent = screenGui

local tbc = Instance.new("UICorner"); tbc.CornerRadius = UDim.new(0, 10); tbc.Parent = toggleBtn
local tbs = Instance.new("UIStroke"); tbs.Color = Color3.fromRGB(90, 140, 220); tbs.Thickness = 1.5; tbs.Parent = toggleBtn

local lastRevision = 0
local currentMode = "Team2v2"

toggleBtn.Activated:Connect(function()
	local nextMode = if currentMode == "Team2v2" then "SoloFFA" else "Team2v2"
	requestAction:FireServer("SetGameMode", lastRevision, currentVersion, nextMode)
end)

stateUpdated.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then return end
	lastRevision = payload.revision or lastRevision

	if payload.phase == "Waiting" then
		toggleBtn.Visible = true
		currentMode = payload.gameMode or "Team2v2"
		if currentMode == "SoloFFA" then
			toggleBtn.Text = "🎮 MODE: 👑 SOLO SULTAN (FFA)"
			toggleBtn.TextColor3 = Color3.fromRGB(255, 215, 60)
			tbs.Color = Color3.fromRGB(255, 215, 60)
		else
			toggleBtn.Text = "🎮 MODE: 🤝 TIM 2v2"
			toggleBtn.TextColor3 = Color3.fromRGB(160, 205, 255)
			tbs.Color = Color3.fromRGB(70, 130, 220)
		end
	else
		toggleBtn.Visible = false
	end
end)
