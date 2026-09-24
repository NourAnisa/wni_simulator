--!strict
-- TeamAssistanceUI.luau (LocalScript)
-- Tombol aksi bantuan gotong royong rekan 2v2: Transfer Kas Darurat & Tebus Lapas.

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
screenGui.Name = "WNITeamAssistanceUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 13
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

local container = Instance.new("Frame")
container.Name = "AssistanceContainer"
container.Size = UDim2.fromOffset(260, 80)
container.Position = UDim2.new(0, 20, 1, -260)
container.BackgroundTransparency = 1
container.Visible = false
container.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = container

-- 1. Tombol Bantu Kas (Bailout)
local bailoutBtn = Instance.new("TextButton")
bailoutBtn.Name = "BailoutBtn"
bailoutBtn.Size = UDim2.new(1, 0, 0, 36)
bailoutBtn.BackgroundColor3 = Color3.fromRGB(24, 60, 40)
bailoutBtn.Text = "🤝 KIRIM BANTUAN KAS (Rp1.000.000)"
bailoutBtn.TextColor3 = Color3.fromRGB(160, 255, 180)
bailoutBtn.Font = Enum.Font.GothamBold
bailoutBtn.TextSize = 11
bailoutBtn.Visible = false
bailoutBtn.Parent = container

local bbc = Instance.new("UICorner"); bbc.CornerRadius = UDim.new(0, 8); bbc.Parent = bailoutBtn
local bbs = Instance.new("UIStroke"); bbs.Color = Color3.fromRGB(60, 220, 120); bbs.Thickness = 1.2; bbs.Parent = bailoutBtn

-- 2. Tombol Tebus Lapas
local jailBailBtn = Instance.new("TextButton")
jailBailBtn.Name = "JailBailBtn"
jailBailBtn.Size = UDim2.new(1, 0, 0, 36)
jailBailBtn.BackgroundColor3 = Color3.fromRGB(65, 30, 25)
jailBailBtn.Text = "🔓 TEBUS REKAN DARI LAPAS"
jailBailBtn.TextColor3 = Color3.fromRGB(255, 180, 160)
jailBailBtn.Font = Enum.Font.GothamBold
jailBailBtn.TextSize = 11
jailBailBtn.Visible = false
jailBailBtn.Parent = container

local jbc = Instance.new("UICorner"); jbc.CornerRadius = UDim.new(0, 8); jbc.Parent = jailBailBtn
local jbs = Instance.new("UIStroke"); jbs.Color = Color3.fromRGB(255, 100, 80); jbs.Thickness = 1.2; jbs.Parent = jailBailBtn

local lastRevision = 0

bailoutBtn.Activated:Connect(function()
	requestAction:FireServer("BailoutTeammate", lastRevision, currentVersion)
end)

jailBailBtn.Activated:Connect(function()
	requestAction:FireServer("BailTeammateFromJail", lastRevision, currentVersion)
end)

stateUpdated.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then return end
	lastRevision = payload.revision or lastRevision

	-- Hanya aktif saat game berlangsung dan mode 2v2
	if payload.phase == "Waiting" or payload.phase == "Finished" or payload.gameMode == "SoloFFA" then
		container.Visible = false
		return
	end

	local myPlayer = nil
	local teammate = nil

	if typeof(payload.players) == "table" then
		for _, p in ipairs(payload.players) do
			if p.userId == lp.UserId then
				myPlayer = p
				break
			end
		end

		if myPlayer then
			for _, p in ipairs(payload.players) do
				if p.userId ~= lp.UserId and p.team == myPlayer.team and not p.eliminated then
					teammate = p
					break
				end
			end
		end
	end

	if myPlayer and teammate and not myPlayer.eliminated then
		local showBailout = teammate.cash < 2000000 and myPlayer.cash >= 1500000
		local showJailBail = teammate.inJail == true and myPlayer.cash >= 1500000

		bailoutBtn.Visible = showBailout
		jailBailBtn.Visible = showJailBail
		container.Visible = showBailout or showJailBail
	else
		container.Visible = false
	end
end)
