--!strict
-- HazardVisualizer.luau (LocalScript)
-- Visualisasi 3D di papan untuk petak yang dilanda Bencana & Kemacetan (Banjir & Macet Pantura).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("WNI", 10)
if not shared then return end
local remotes = shared:WaitForChild("Remotes", 10)
if not remotes then return end
local stateUpdated = remotes:WaitForChild("StateUpdated", 10)
if not stateUpdated then return end

local board = Workspace:WaitForChild("WNIBoard", 10)
if not board then return end
local tileFolder = board:WaitForChild("Tiles", 10)
if not tileFolder then return end

local activeMarkers: {[number]: BillboardGui} = {}

local function createHazardMarker(tilePart: BasePart, hazard: {kind: string, name: string, roundsLeft: number}): BillboardGui
	local bb = Instance.new("BillboardGui")
	bb.Name = "HazardMarker_" .. hazard.kind
	bb.Adornee = tilePart
	bb.Size = UDim2.fromOffset(130, 42)
	bb.StudsOffset = Vector3.new(0, 3.8, 0)
	bb.AlwaysOnTop = true
	bb.Parent = tilePart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.BackgroundColor3 = if hazard.kind == "Banjir" then Color3.fromRGB(20, 60, 110) else Color3.fromRGB(110, 40, 20)
	frame.BackgroundTransparency = 0.15
	frame.Parent = bb

	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 10); corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = if hazard.kind == "Banjir" then Color3.fromRGB(80, 180, 255) else Color3.fromRGB(255, 120, 50)
	stroke.Thickness = 2.0
	stroke.Parent = frame

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size = UDim2.new(0, 30, 1, 0)
	iconLbl.Position = UDim2.new(0, 4, 0, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Text = if hazard.kind == "Banjir" then "🌊" else "🚗"
	iconLbl.TextSize = 20
	iconLbl.Parent = frame

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -38, 0, 20)
	titleLbl.Position = UDim2.new(0, 34, 0, 3)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = if hazard.kind == "Banjir" then "BANJIR AIR" else "MACET TOTAL"
	titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 11
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = frame

	local subLbl = Instance.new("TextLabel")
	subLbl.Size = UDim2.new(1, -38, 0, 16)
	subLbl.Position = UDim2.new(0, 34, 0, 22)
	subLbl.BackgroundTransparency = 1
	subLbl.Text = "(" .. tostring(hazard.roundsLeft) .. " ronde lagi)"
	subLbl.TextColor3 = Color3.fromRGB(255, 220, 120)
	subLbl.Font = Enum.Font.GothamMedium
	subLbl.TextSize = 9
	subLbl.TextXAlignment = Enum.TextXAlignment.Left
	subLbl.Parent = frame

	-- Animasi denyut / mengambang
	local tween = TweenService:Create(bb, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		StudsOffset = Vector3.new(0, 4.4, 0)
	})
	tween:Play()

	return bb
end

stateUpdated.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then return end
	local hazards = payload.activeHazards or {}

	-- Hapus marker lama yang sudah tidak aktif
	for tileIdx, marker in pairs(activeMarkers) do
		if not hazards[tileIdx] then
			marker:Destroy()
			activeMarkers[tileIdx] = nil
		end
	end

	-- Buat atau perbarui marker baru
	for tileIdx, hazard in pairs(hazards) do
		local tilePart = tileFolder:FindFirstChild(string.format("Tile_%02d", tileIdx))
		if tilePart and tilePart:IsA("BasePart") then
			if not activeMarkers[tileIdx] then
				activeMarkers[tileIdx] = createHazardMarker(tilePart, hazard)
			else
				-- Update teks durasi ronde tersisa
				local subLbl = activeMarkers[tileIdx]:FindFirstChild("Frame") and activeMarkers[tileIdx].Frame:FindFirstChild("TextLabel")
				if subLbl then
					subLbl.Text = "(" .. tostring(hazard.roundsLeft) .. " ronde lagi)"
				end
			end
		end
	end
end)
