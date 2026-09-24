--!strict
-- StockMarketUI.luau (LocalScript)
-- Tampilan antarmuka Pasar Modal Mini: Saham BUMN & Kripto Gorengan.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local stockConfigModule = shared:WaitForChild("StockMarketConfig", 10)
if not stockConfigModule or not stockConfigModule:IsA("ModuleScript") then return end
local StockMarket = require(stockConfigModule)

local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
local requestAction = remotes:WaitForChild("RequestAction", 10)
if not stateUpdated or not requestAction then return end

local rulesModule = shared:WaitForChild("PrototypeRules", 10)
local Rules = if rulesModule and rulesModule:IsA("ModuleScript") then require(rulesModule) else nil
local currentVersion = if Rules then Rules.Version else "prototype-0.1"

local function formatMoney(amount: number): string
	if Rules then return Rules.formatMoney(amount) end
	return "Rp" .. tostring(amount)
end

-- Screen GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WNIStockMarketUI"
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

-- Tombol Buka Bursa Saham Mengambang
local triggerBtn = Instance.new("TextButton")
triggerBtn.Name = "StockTriggerBtn"
triggerBtn.Size = UDim2.fromOffset(48, 48)
triggerBtn.Position = UDim2.new(1, -64, 1, -240)
triggerBtn.BackgroundColor3 = Color3.fromRGB(20, 32, 45)
triggerBtn.Text = "📈"
triggerBtn.TextSize = 22
triggerBtn.Font = Enum.Font.GothamBold
triggerBtn.Parent = screenGui

local tbc = Instance.new("UICorner"); tbc.CornerRadius = UDim.new(1, 0); tbc.Parent = triggerBtn
local tbs = Instance.new("UIStroke"); tbs.Color = Color3.fromRGB(60, 210, 140); tbs.Thickness = 2.0; tbs.Parent = triggerBtn

-- Modal Window Bursa Efek
local modal = Instance.new("Frame")
modal.Name = "StockModal"
modal.Size = UDim2.fromOffset(450, 360)
modal.Position = UDim2.new(0.5, 0, 0.5, 0)
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.BackgroundColor3 = Color3.fromRGB(16, 22, 34)
modal.Visible = false
modal.Parent = screenGui

local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 16); mc.Parent = modal
local ms = Instance.new("UIStroke"); ms.Color = Color3.fromRGB(60, 210, 140); ms.Thickness = 2.0; ms.Parent = modal

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 36)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "📈 BURSA EFEK & PASAR MODAL NUSANTARA"
title.TextColor3 = Color3.fromRGB(255, 230, 100)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = modal

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(45, 30, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.Parent = modal
local cbc = Instance.new("UICorner"); cbc.CornerRadius = UDim.new(0, 8); cbc.Parent = closeBtn

closeBtn.Activated:Connect(function()
	modal.Visible = false
end)

triggerBtn.Activated:Connect(function()
	modal.Visible = not modal.Visible
end)

-- Container Saham
local stocksContainer = Instance.new("Frame")
stocksContainer.Size = UDim2.new(1, -24, 0, 220)
stocksContainer.Position = UDim2.new(0, 12, 0, 48)
stocksContainer.BackgroundTransparency = 1
stocksContainer.Parent = modal

local sLayout = Instance.new("UIListLayout")
sLayout.Padding = UDim.new(0, 10)
sLayout.Parent = stocksContainer

-- Dynamic labels cache
local stockCardRefs: {[string]: {priceLbl: TextLabel, ownedLbl: TextLabel, buyBtn: TextButton, sellBtn: TextButton}} = {}

for _, item in ipairs(StockMarket.getAll()) do
	local card = Instance.new("Frame")
	card.Name = "Card_" .. item.id
	card.Size = UDim2.new(1, 0, 0, 100)
	card.BackgroundColor3 = Color3.fromRGB(24, 30, 45)
	card.Parent = stocksContainer

	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 12); cc.Parent = card
	local cs = Instance.new("UIStroke"); cs.Color = Color3.fromRGB(50, 70, 95); cs.Thickness = 1.2; cs.Parent = card

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size = UDim2.fromOffset(36, 36)
	iconLbl.Position = UDim2.new(0, 10, 0, 10)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Text = item.icon
	iconLbl.TextSize = 24
	iconLbl.Parent = card

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(0.55, 0, 0, 20)
	nameLbl.Position = UDim2.new(0, 52, 0, 10)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = item.ticker .. " — " .. item.name
	nameLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 12
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = card

	local descLbl = Instance.new("TextLabel")
	descLbl.Size = UDim2.new(0.55, 0, 0, 28)
	descLbl.Position = UDim2.new(0, 52, 0, 32)
	descLbl.BackgroundTransparency = 1
	descLbl.Text = item.desc
	descLbl.TextColor3 = Color3.fromRGB(170, 185, 210)
	descLbl.Font = Enum.Font.Gotham
	descLbl.TextSize = 10
	descLbl.TextWrapped = true
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.Parent = card

	local priceLbl = Instance.new("TextLabel")
	priceLbl.Size = UDim2.new(0.35, -10, 0, 22)
	priceLbl.Position = UDim2.new(0.65, 0, 0, 10)
	priceLbl.BackgroundTransparency = 1
	priceLbl.Text = formatMoney(item.basePrice)
	priceLbl.TextColor3 = Color3.fromRGB(60, 230, 140)
	priceLbl.Font = Enum.Font.GothamBold
	priceLbl.TextSize = 13
	priceLbl.TextXAlignment = Enum.TextXAlignment.Right
	priceLbl.Parent = card

	local ownedLbl = Instance.new("TextLabel")
	ownedLbl.Size = UDim2.new(0.35, -10, 0, 18)
	ownedLbl.Position = UDim2.new(0.65, 0, 0, 34)
	ownedLbl.BackgroundTransparency = 1
	ownedLbl.Text = "Dimiliki: 0 lot"
	ownedLbl.TextColor3 = Color3.fromRGB(255, 220, 100)
	ownedLbl.Font = Enum.Font.GothamMedium
	ownedLbl.TextSize = 11
	ownedLbl.TextXAlignment = Enum.TextXAlignment.Right
	ownedLbl.Parent = card

	local btnContainer = Instance.new("Frame")
	btnContainer.Size = UDim2.new(1, -20, 0, 28)
	btnContainer.Position = UDim2.new(0, 10, 0, 64)
	btnContainer.BackgroundTransparency = 1
	btnContainer.Parent = card

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0.48, 0, 1, 0)
	buyBtn.Position = UDim2.new(0, 0, 0, 0)
	buyBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 50)
	buyBtn.Text = "BELI 1 LOT"
	buyBtn.TextColor3 = Color3.fromRGB(160, 255, 190)
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.TextSize = 11
	buyBtn.Parent = btnContainer
	local bbc = Instance.new("UICorner"); bbc.CornerRadius = UDim.new(0, 6); bbc.Parent = buyBtn

	local sellBtn = Instance.new("TextButton")
	sellBtn.Size = UDim2.new(0.48, 0, 1, 0)
	sellBtn.Position = UDim2.new(0.52, 0, 0, 0)
	sellBtn.BackgroundColor3 = Color3.fromRGB(80, 35, 40)
	sellBtn.Text = "JUAL 1 LOT"
	sellBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
	sellBtn.Font = Enum.Font.GothamBold
	sellBtn.TextSize = 11
	sellBtn.Parent = btnContainer
	local sbc = Instance.new("UICorner"); sbc.CornerRadius = UDim.new(0, 6); sbc.Parent = sellBtn

	buyBtn.Activated:Connect(function()
		requestAction:FireServer("BuyStock", lastRevision, currentVersion, {stockId = item.id, count = 1})
	end)

	sellBtn.Activated:Connect(function()
		requestAction:FireServer("SellStock", lastRevision, currentVersion, {stockId = item.id, count = 1})
	end)

	stockCardRefs[item.id] = {priceLbl = priceLbl, ownedLbl = ownedLbl, buyBtn = buyBtn, sellBtn = sellBtn}
end

-- News Ticker & Valuation Footer
local newsLbl = Instance.new("TextLabel")
newsLbl.Size = UDim2.new(1, -24, 0, 32)
newsLbl.Position = UDim2.new(0, 12, 1, -78)
newsLbl.BackgroundColor3 = Color3.fromRGB(20, 26, 38)
newsLbl.Text = "📢 Berita: Bursa saham dibuka stabil."
newsLbl.TextColor3 = Color3.fromRGB(255, 230, 150)
newsLbl.Font = Enum.Font.GothamMedium
newsLbl.TextSize = 10
newsLbl.TextWrapped = true
newsLbl.Parent = modal
local nlc = Instance.new("UICorner"); nlc.CornerRadius = UDim.new(0, 8); nlc.Parent = newsLbl

local totalValuationLbl = Instance.new("TextLabel")
totalValuationLbl.Size = UDim2.new(1, -24, 0, 24)
totalValuationLbl.Position = UDim2.new(0, 12, 1, -38)
totalValuationLbl.BackgroundTransparency = 1
totalValuationLbl.Text = "Total Nilai Portofolio: Rp0"
totalValuationLbl.TextColor3 = Color3.fromRGB(255, 215, 60)
totalValuationLbl.Font = Enum.Font.GothamBold
totalValuationLbl.TextSize = 12
totalValuationLbl.Parent = modal

stateUpdated.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then return end
	lastRevision = payload.revision or lastRevision

	-- Update news
	if payload.stockNews and payload.stockNews ~= "" then
		newsLbl.Text = "📢 " .. payload.stockNews
	end

	-- Update prices
	local prices = payload.stockPrices or {}
	for stockId, ref in pairs(stockCardRefs) do
		local p = prices[stockId]
		if p then
			ref.priceLbl.Text = formatMoney(p)
		end
	end

	-- Update local player portfolio
	local myPlayer = nil
	if typeof(payload.players) == "table" then
		for _, p in ipairs(payload.players) do
			if p.userId == lp.UserId then
				myPlayer = p
				break
			end
		end
	end

	if myPlayer and myPlayer.portfolio then
		local totalVal = 0
		for stockId, ref in pairs(stockCardRefs) do
			local shares = myPlayer.portfolio[stockId] or 0
			local curPrice = prices[stockId] or 0
			ref.ownedLbl.Text = "Dimiliki: " .. tostring(shares) .. " lot"
			totalVal += shares * curPrice
		end
		totalValuationLbl.Text = "Total Nilai Portofolio: " .. formatMoney(totalVal)
	end
end)
