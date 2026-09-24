--!strict
-- RoleBadgeUI.luau (LocalScript)
-- Menampilkan lencana profesi pemain dan modal pemilihan profesi Nusantara di lobi.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local roleConfigModule = shared:WaitForChild("RoleConfig", 10)
if not roleConfigModule or not roleConfigModule:IsA("ModuleScript") then return end
local RoleConfig = require(roleConfigModule)

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
screenGui.Name = "WNIRoleUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 25
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

local lastRevision = 0
local currentPhase = "Waiting"

-- Tombol Buka Pemilih Profesi (Hanya muncul saat Waiting di Lobi)
local roleLobbyBtn = Instance.new("TextButton")
roleLobbyBtn.Name = "RoleLobbyBtn"
roleLobbyBtn.Size = UDim2.fromOffset(140, 36)
roleLobbyBtn.Position = UDim2.new(0, 20, 1, -120)
roleLobbyBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 50)
roleLobbyBtn.Text = "🎭 PILIH PROFESI"
roleLobbyBtn.TextColor3 = Color3.fromRGB(255, 220, 80)
roleLobbyBtn.Font = Enum.Font.GothamBold
roleLobbyBtn.TextSize = 12
roleLobbyBtn.Visible = false
roleLobbyBtn.Parent = screenGui

local rlbCorner = Instance.new("UICorner"); rlbCorner.CornerRadius = UDim.new(0, 10); rlbCorner.Parent = roleLobbyBtn
local rlbStroke = Instance.new("UIStroke"); rlbStroke.Color = Color3.fromRGB(255, 215, 60); rlbStroke.Thickness = 1.5; rlbStroke.Parent = roleLobbyBtn

-- Modal Pemilihan Profesi
local modal = Instance.new("Frame")
modal.Name = "RoleModal"
modal.Size = UDim2.fromOffset(460, 330)
modal.Position = UDim2.new(0.5, 0, 0.5, 0)
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
modal.Visible = false
modal.Parent = screenGui

local mCorner = Instance.new("UICorner"); mCorner.CornerRadius = UDim.new(0, 16); mCorner.Parent = modal
local mStroke = Instance.new("UIStroke"); mStroke.Color = Color3.fromRGB(255, 215, 60); mStroke.Thickness = 2.0; mStroke.Parent = modal

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "PILIH IDENTITAS / PROFESI WNI"
title.TextColor3 = Color3.fromRGB(255, 225, 90)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = modal

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(30, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(45, 30, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = modal
local cbc = Instance.new("UICorner"); cbc.CornerRadius = UDim.new(0, 8); cbc.Parent = closeBtn

closeBtn.Activated:Connect(function()
	modal.Visible = false
end)

local roleCardsContainer = Instance.new("Frame")
roleCardsContainer.Size = UDim2.new(1, -20, 1, -60)
roleCardsContainer.Position = UDim2.new(0, 10, 0, 52)
roleCardsContainer.BackgroundTransparency = 1
roleCardsContainer.Parent = modal

local roleLayout = Instance.new("UIGridLayout")
roleLayout.CellSize = UDim2.fromOffset(210, 120)
roleLayout.CellPadding = UDim2.fromOffset(12, 12)
roleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
roleLayout.Parent = roleCardsContainer

for _, role in ipairs(RoleConfig.all()) do
	local card = Instance.new("TextButton")
	card.Name = "RoleCard_" .. role.id
	card.BackgroundColor3 = Color3.fromRGB(25, 30, 46)
	card.Text = ""
	card.AutoButtonColor = true
	card.Parent = roleCardsContainer

	local cardCorner = Instance.new("UICorner"); cardCorner.CornerRadius = UDim.new(0, 12); cardCorner.Parent = card
	local cardStroke = Instance.new("UIStroke"); cardStroke.Color = role.badgeColor; cardStroke.Thickness = 1.5; cardStroke.Parent = card

	local rIcon = Instance.new("TextLabel")
	rIcon.Size = UDim2.new(0, 36, 0, 36)
	rIcon.Position = UDim2.new(0, 10, 0, 8)
	rIcon.BackgroundTransparency = 1
	rIcon.Text = role.icon
	rIcon.TextSize = 24
	rIcon.Parent = card

	local rName = Instance.new("TextLabel")
	rName.Size = UDim2.new(1, -54, 0, 24)
	rName.Position = UDim2.new(0, 50, 0, 14)
	rName.BackgroundTransparency = 1
	rName.Text = role.name
	rName.TextColor3 = role.badgeColor
	rName.Font = Enum.Font.GothamBold
	rName.TextSize = 13
	rName.TextXAlignment = Enum.TextXAlignment.Left
	rName.Parent = card

	local rSummary = Instance.new("TextLabel")
	rSummary.Size = UDim2.new(1, -20, 0, 48)
	rSummary.Position = UDim2.new(0, 10, 0, 52)
	rSummary.BackgroundTransparency = 1
	rSummary.Text = role.perkSummary
	rSummary.TextColor3 = Color3.fromRGB(210, 220, 240)
	rSummary.Font = Enum.Font.Gotham
	rSummary.TextSize = 11
	rSummary.TextWrapped = true
	rSummary.TextXAlignment = Enum.TextXAlignment.Left
	rSummary.Parent = card

	card.Activated:Connect(function()
		modal.Visible = false
		requestAction:FireServer("SelectRole", lastRevision, currentVersion, role.id)
	end)
end

roleLobbyBtn.Activated:Connect(function()
	modal.Visible = not modal.Visible
end)

-- Banner Info Perk Pasif Pemain Lokal Saat Match Berlangsung
local myPerkBadge = Instance.new("Frame")
myPerkBadge.Name = "MyPerkBadge"
myPerkBadge.Size = UDim2.fromOffset(240, 38)
myPerkBadge.Position = UDim2.new(0, 20, 0, 130)
myPerkBadge.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
myPerkBadge.BackgroundTransparency = 0.15
myPerkBadge.Visible = false
myPerkBadge.Parent = screenGui

local mpbCorner = Instance.new("UICorner"); mpbCorner.CornerRadius = UDim.new(0, 10); mpbCorner.Parent = myPerkBadge
local mpbStroke = Instance.new("UIStroke"); mpbStroke.Color = Color3.fromRGB(255, 215, 60); mpbStroke.Thickness = 1.2; mpbStroke.Parent = myPerkBadge

local mpbText = Instance.new("TextLabel")
mpbText.Name = "BadgeText"
mpbText.Size = UDim2.new(1, -16, 1, 0)
mpbText.Position = UDim2.new(0, 8, 0, 0)
mpbText.BackgroundTransparency = 1
mpbText.TextColor3 = Color3.fromRGB(255, 235, 170)
mpbText.Font = Enum.Font.GothamMedium
mpbText.TextSize = 11
mpbText.TextXAlignment = Enum.TextXAlignment.Left
mpbText.Parent = myPerkBadge

stateUpdated.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then return end
	lastRevision = payload.revision or lastRevision
	currentPhase = payload.phase or currentPhase

	if currentPhase == "Waiting" then
		roleLobbyBtn.Visible = true
		myPerkBadge.Visible = false
	else
		roleLobbyBtn.Visible = false
		modal.Visible = false
		-- Cari peran lokal player
		if typeof(payload.players) == "table" then
			for _, p in ipairs(payload.players) do
				if p.userId == lp.UserId and p.role then
					local roleDef = RoleConfig.get(p.role)
					mpbText.Text = roleDef.icon .. " " .. roleDef.name .. ": " .. roleDef.perkSummary
					mpbStroke.Color = roleDef.badgeColor
					myPerkBadge.Visible = true
					break
				end
			end
		end
	end
end)
