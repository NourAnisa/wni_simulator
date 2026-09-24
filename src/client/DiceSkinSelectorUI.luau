--!strict
-- DiceSkinSelectorUI.luau (LocalScript)
-- Panel pemilihan skin dadu di Lobby: responsive dock di sisi kanan tengah.
-- Mengirim pilihan ke server via RequestAction("SetDiceSkin", skinKey).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local Remotes = shared:WaitForChild("Remotes", 10)
if not Remotes then return end
local stateUpdated = Remotes:WaitForChild("StateUpdated", 10)
local requestAction = Remotes:WaitForChild("RequestAction", 10)
local ProgressionConfig = require(shared:WaitForChild("ProgressionConfig", 5))

-- ─── RESPONSIVE SCREEN GUI ───────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WNIDiceSkinUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 6
screenGui.Parent = pgui

local uiScale = Instance.new("UIScale")
uiScale.Name = "InterfaceScale"
uiScale.Parent = screenGui

local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera") :: Camera
local function updateScale()
	local vp = camera.ViewportSize
	if vp.X <= 0 or vp.Y <= 0 then return end
	local target = math.min(vp.X / 1366, vp.Y / 768)
	uiScale.Scale = math.clamp(target, 0.52, 1.25)
end

camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local c = Workspace.CurrentCamera
	if c then
		camera = c
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
		updateScale()
	end
end)
task.spawn(updateScale)

-- ─── DATA ────────────────────────────────────────────────────────────────────

local SKIN_ORDER = {"Classic", "Mahogany", "NeonCyan", "GoldSultan"}
local SKIN_COLORS = {
	Classic    = Color3.fromRGB(245, 245, 245),
	Mahogany   = Color3.fromRGB(115, 65, 35),
	NeonCyan   = Color3.fromRGB(45, 220, 200),
	GoldSultan = Color3.fromRGB(245, 195, 50),
}
local SKIN_EMOJIS = {Classic = "⬜", Mahogany = "🟫", NeonCyan = "🩵", GoldSultan = "🟡"}

-- ─── BUILD UI ────────────────────────────────────────────────────────────────

-- Toggle button (kanan tengah, Y offset +55)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "DiceSkinToggle"
toggleBtn.Size = UDim2.new(0, 42, 0, 42)
toggleBtn.Position = UDim2.new(1, -12, 0.5, 55)
toggleBtn.AnchorPoint = Vector2.new(1, 0.5)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
toggleBtn.TextColor3 = Color3.fromRGB(245, 195, 50)
toggleBtn.Text = "🎲"
toggleBtn.TextSize = 20
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Visible = false
toggleBtn.Parent = screenGui
local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 21); tc.Parent = toggleBtn
local ts = Instance.new("UIStroke"); ts.Color = Color3.fromRGB(245, 195, 50); ts.Thickness = 2; ts.Parent = toggleBtn

-- Panel utama (slide in dari kanan, Y-centered)
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 260, 0, 290)
panel.Position = UDim2.new(1, -62, 0.5, 0)
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(14, 20, 28)
panel.BackgroundTransparency = 0.08
panel.Visible = false
panel.Parent = screenGui
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 14); pc.Parent = panel
local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(245, 195, 50); ps.Thickness = 2; ps.Parent = panel

local pList = Instance.new("UIListLayout"); pList.SortOrder = Enum.SortOrder.LayoutOrder
pList.Padding = UDim.new(0, 6); pList.HorizontalAlignment = Enum.HorizontalAlignment.Center; pList.Parent = panel
local pPad = Instance.new("UIPadding"); pPad.PaddingTop = UDim.new(0, 10); pPad.PaddingBottom = UDim.new(0, 10)
pPad.PaddingLeft = UDim.new(0, 10); pPad.PaddingRight = UDim.new(0, 10); pPad.Parent = panel

local titleL = Instance.new("TextLabel")
titleL.Size = UDim2.new(1, 0, 0, 22)
titleL.Text = "🎲 Pilih Skin Dadu"
titleL.TextSize = 13; titleL.TextColor3 = Color3.fromRGB(245, 195, 50)
titleL.BackgroundTransparency = 1; titleL.Font = Enum.Font.GothamBold
titleL.LayoutOrder = 0; titleL.Parent = panel

local subL = Instance.new("TextLabel")
subL.Name = "SubLabel"
subL.Size = UDim2.new(1, 0, 0, 16)
subL.Text = "Level kamu: ?"
subL.TextSize = 10; subL.TextColor3 = Color3.fromRGB(160, 160, 160)
subL.BackgroundTransparency = 1; subL.Font = Enum.Font.Gotham
subL.LayoutOrder = 1; subL.Parent = panel

-- ─── SKIN BUTTONS ────────────────────────────────────────────────────────────

local skinButtons: {[string]: TextButton} = {}
local selectedSkin = "Classic"
local playerLevel = 1

local function refreshButtons()
	for key, btn in pairs(skinButtons) do
		local skin = ProgressionConfig.DICE_SKINS[key]
		local locked = playerLevel < skin.RequiredLevel
		local selected = key == selectedSkin

		btn.BackgroundColor3 = if selected
			then SKIN_COLORS[key]
			elseif locked
			then Color3.fromRGB(30, 30, 40)
			else Color3.fromRGB(40, 50, 65)

		btn.TextColor3 = if locked then Color3.fromRGB(80, 80, 80) else Color3.fromRGB(230, 230, 230)
		local uis = btn:FindFirstChildOfClass("UIStroke")
		if uis then
			uis.Color = if selected then Color3.fromRGB(255, 255, 100) else Color3.fromRGB(60, 80, 100)
			uis.Thickness = if selected then 3 else 1
		end
	end
end

for i, key in ipairs(SKIN_ORDER) do
	local skin = ProgressionConfig.DICE_SKINS[key]
	local btn = Instance.new("TextButton")
	btn.Name = "Skin_" .. key
	btn.Size = UDim2.new(1, 0, 0, 42)
	btn.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
	btn.TextColor3 = Color3.fromRGB(230, 230, 230)
	btn.Text = SKIN_EMOJIS[key] .. "  " .. skin.Name .. "  (Lv." .. skin.RequiredLevel .. ")"
	btn.TextSize = 11; btn.Font = Enum.Font.GothamBold
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = i + 1
	btn.Parent = panel
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = btn
	local bs = Instance.new("UIStroke"); bs.Thickness = 1; bs.Color = Color3.fromRGB(60, 80, 100); bs.Parent = btn
	local bp = Instance.new("UIPadding"); bp.PaddingLeft = UDim.new(0, 10); bp.Parent = btn
	skinButtons[key] = btn

	btn.Activated:Connect(function()
		if playerLevel < skin.RequiredLevel then
			TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(100, 30, 30)}):Play()
			task.delay(0.3, function()
				TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
			end)
			return
		end
		selectedSkin = key
		refreshButtons()
		pcall(function()
			requestAction:FireServer("SetDiceSkin", skin.Name, key)
		end)
	end)
end

-- ─── SHOW/HIDE ────────────────────────────────────────────────────────────────

local function showPanel(v: boolean)
	panel.Visible = v
end

toggleBtn.Activated:Connect(function()
	showPanel(not panel.Visible)
end)

-- ─── STATE UPDATE ─────────────────────────────────────────────────────────────

stateUpdated.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then return end

	local inLobby = payload.phase == "Waiting"
	toggleBtn.Visible = inLobby
	if not inLobby then showPanel(false) end

	if typeof(payload.players) == "table" then
		local localUserId = lp.UserId
		for _, p in ipairs(payload.players) do
			if typeof(p) == "table" and p.userId == localUserId then
				local profile = p.profile or {}
				playerLevel = profile.level or 1
				local currentSkin = profile.diceSkin or "Classic"
				if ProgressionConfig.DICE_SKINS[currentSkin] then
					selectedSkin = currentSkin
				end
				subL.Text = "Level kamu: " .. playerLevel
				refreshButtons()
				break
			end
		end
	end
end)
