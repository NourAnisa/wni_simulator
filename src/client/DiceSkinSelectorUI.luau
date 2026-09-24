--!strict
-- DiceSkinSelectorUI.luau (LocalScript)
-- Panel pemilihan skin dadu yang muncul di Lobby (phase Waiting).
-- Mengirim pilihan ke server via RequestAction("SetDiceSkin", skinKey).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local Remotes = shared:WaitForChild("Remotes", 10)
if not Remotes then return end
local stateUpdated = Remotes:WaitForChild("StateUpdated", 10)
local requestAction = Remotes:WaitForChild("RequestAction", 10)
local ProgressionConfig = require(shared:WaitForChild("ProgressionConfig", 5))

-- ─── DATA ────────────────────────────────────────────────────────────────────

local SKIN_ORDER = {"Classic", "Mahogany", "NeonCyan", "GoldSultan"}
local SKIN_COLORS = {
	Classic   = Color3.fromRGB(245, 245, 245),
	Mahogany  = Color3.fromRGB(115, 65, 35),
	NeonCyan  = Color3.fromRGB(45, 220, 200),
	GoldSultan = Color3.fromRGB(245, 195, 50),
}
local SKIN_EMOJIS = {Classic = "⬜", Mahogany = "🟫", NeonCyan = "🩵", GoldSultan = "🟡"}

-- ─── BUILD UI ────────────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WNIDiceSkinUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = pgui

-- Toggle button (kanan bawah)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "DiceSkinToggle"
toggleBtn.Size = UDim2.new(0, 44, 0, 44)
toggleBtn.Position = UDim2.new(1, -56, 1, -130)
toggleBtn.AnchorPoint = Vector2.new(1, 1)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
toggleBtn.TextColor3 = Color3.fromRGB(245, 195, 50)
toggleBtn.Text = "🎲"
toggleBtn.TextSize = 22
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Visible = false
toggleBtn.Parent = screenGui
local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 22); tc.Parent = toggleBtn
local ts = Instance.new("UIStroke"); ts.Color = Color3.fromRGB(245, 195, 50); ts.Thickness = 2; ts.Parent = toggleBtn

-- Panel utama
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 260, 0, 300)
panel.Position = UDim2.new(1, -56, 1, -180)
panel.AnchorPoint = Vector2.new(1, 1)
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
titleL.TextSize = 14; titleL.TextColor3 = Color3.fromRGB(245, 195, 50)
titleL.BackgroundTransparency = 1; titleL.Font = Enum.Font.GothamBold
titleL.LayoutOrder = 0; titleL.Parent = panel

local subL = Instance.new("TextLabel")
subL.Name = "SubLabel"
subL.Size = UDim2.new(1, 0, 0, 16)
subL.Text = "Level kamu: ?"
subL.TextSize = 11; subL.TextColor3 = Color3.fromRGB(160, 160, 160)
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
	btn.Size = UDim2.new(1, 0, 0, 44)
	btn.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
	btn.TextColor3 = Color3.fromRGB(230, 230, 230)
	btn.Text = SKIN_EMOJIS[key] .. "  " .. skin.Name .. "  (Lv." .. skin.RequiredLevel .. ")"
	btn.TextSize = 12; btn.Font = Enum.Font.GothamBold
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = i + 1
	btn.Parent = panel
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = btn
	local bs = Instance.new("UIStroke"); bs.Thickness = 1; bs.Color = Color3.fromRGB(60, 80, 100); bs.Parent = btn
	local bp = Instance.new("UIPadding"); bp.PaddingLeft = UDim.new(0, 10); bp.Parent = btn
	skinButtons[key] = btn

	btn.Activated:Connect(function()
		if playerLevel < skin.RequiredLevel then
			-- Flash merah jika terkunci
			TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(100, 30, 30)}):Play()
			task.delay(0.3, function()
				TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
			end)
			return
		end
		selectedSkin = key
		refreshButtons()
		-- Kirim ke server
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

	-- Ambil level & diceSkin dari profile pemain lokal
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
