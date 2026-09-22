--!strict
-- BuildingVisualService.luau
-- Bertanggung jawab membuat dan memperbarui visualisasi 3D bangunan properti dan gerbang tol di atas petak WNI Simulator.
-- Tingkat Bangunan:
-- Level 1: Rumah Subsidi 1 (Rumah mungil atap genteng bata, pintu kayu, lis tim)
-- Level 2: Rumah Subsidi 2 (Ekspansi rumah + kanopi baja ringan/carport, AC outdoor)
-- Level 3: Rumah OKB (Villa modern mewah 2 lantai, balkon kaca, atap miring arsitektur)
-- Toll Gate: Gerbang Tol Otomatis (Gantry palang tol merah-putih, plang G-TOLL, sensor)

local BuildingVisualService = {}

local TEAM_COLORS: {[string]: Color3} = {
	A = Color3.fromRGB(80, 185, 160),  -- Tim A (Mint / Emerald)
	B = Color3.fromRGB(240, 130, 90),  -- Tim B (Coral / Warm Orange)
}

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = true
	p.Parent = parent
	return p
end

local function makeWedge(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.CFrame = cf
	w.Color = color
	w.Material = mat or Enum.Material.SmoothPlastic
	w.Anchored = true
	w.CanCollide = false
	w.CanTouch = false
	w.CanQuery = false
	w.CastShadow = true
	w.Parent = parent
	return w
end

-- =========================================================================
-- LEVEL 1: RUMAH SUBSIDI 1
-- =========================================================================
local function createSubsidi1(tileCF: CFrame, teamColor: Color3): Model
	local m = Instance.new("Model")
	m.Name = "RumahSubsidi1"

	-- Offset sedikit ke arah dalam papan (Z + 1.8) agar pion di tengah (PawnAnchor) tidak tertabrak
	local origin = tileCF * CFrame.new(0, 0.4 + 0.65, 1.7)

	-- Pondasi & Dinding Utama (Krem plaster khas perumahan subsidi)
	local wallColor = Color3.fromRGB(245, 240, 230)
	local mainBody = makePart(m, "MainBody", Vector3.new(2.4, 1.3, 1.8), origin, wallColor, Enum.Material.Concrete)

	-- Atap Genteng Pelana (Terracotta)
	local roofColor = Color3.fromRGB(185, 65, 40)
	local roofHeight = 0.7
	local roofWedgeWidth = 1.35
	local roofL = makeWedge(m, "RoofLeft", Vector3.new(2.0, roofHeight, roofWedgeWidth),
		origin * CFrame.new(-0.65, 0.65 + roofHeight / 2, 0) * CFrame.Angles(0, math.rad(90), 0),
		roofColor, Enum.Material.CorrodedMetal)
	local roofR = makeWedge(m, "RoofRight", Vector3.new(2.0, roofHeight, roofWedgeWidth),
		origin * CFrame.new(0.65, 0.65 + roofHeight / 2, 0) * CFrame.Angles(0, math.rad(-90), 0),
		roofColor, Enum.Material.CorrodedMetal)

	-- Nok Atap (Ridge Cap)
	makePart(m, "RoofRidge", Vector3.new(0.18, 0.15, 2.05), origin * CFrame.new(0, 1.02, 0), Color3.fromRGB(150, 50, 30))

	-- Pintu Depan (Kayu sederhana)
	makePart(m, "Door", Vector3.new(0.55, 0.9, 0.05), origin * CFrame.new(-0.45, -0.2, -0.91), Color3.fromRGB(110, 65, 35), Enum.Material.Wood)

	-- Jendela Kaca Depan
	makePart(m, "Window", Vector3.new(0.55, 0.55, 0.05), origin * CFrame.new(0.5, 0.05, -0.91), Color3.fromRGB(160, 215, 240), Enum.Material.Glass)

	-- Kanopi Kecil Atas Pintu (Teras mini)
	makePart(m, "Canopy", Vector3.new(0.85, 0.08, 0.4), origin * CFrame.new(-0.45, 0.35, -1.05), Color3.fromRGB(220, 220, 220))

	-- Lis Indikator Tim (Aksen warna pemilik tim)
	makePart(m, "TeamStripe", Vector3.new(2.44, 0.12, 0.06), origin * CFrame.new(0, 0.55, -0.91), teamColor, Enum.Material.Neon)

	m.PrimaryPart = mainBody
	return m
end

-- =========================================================================
-- LEVEL 2: RUMAH SUBSIDI 2 (Upgrade + Kanopi Baja Ringan & AC)
-- =========================================================================
local function createSubsidi2(tileCF: CFrame, teamColor: Color3): Model
	local m = Instance.new("Model")
	m.Name = "RumahSubsidi2"

	local origin = tileCF * CFrame.new(0, 0.4 + 0.7, 1.7)

	-- Rumah Utama
	local mainColor = Color3.fromRGB(240, 242, 235)
	local mainBody = makePart(m, "MainBody", Vector3.new(2.5, 1.4, 2.0), origin, mainColor, Enum.Material.Concrete)

	-- Atap Genteng
	local roofColor = Color3.fromRGB(175, 55, 35)
	local roofHeight = 0.75
	makeWedge(m, "RoofL", Vector3.new(2.2, roofHeight, 1.4),
		origin * CFrame.new(-0.7, 0.7 + roofHeight / 2, 0) * CFrame.Angles(0, math.rad(90), 0),
		roofColor, Enum.Material.CorrodedMetal)
	makeWedge(m, "RoofR", Vector3.new(2.2, roofHeight, 1.4),
		origin * CFrame.new(0.7, 0.7 + roofHeight / 2, 0) * CFrame.Angles(0, math.rad(-90), 0),
		roofColor, Enum.Material.CorrodedMetal)
	makePart(m, "RoofRidge", Vector3.new(0.2, 0.16, 2.25), origin * CFrame.new(0, 1.1, 0), Color3.fromRGB(140, 40, 25))

	-- Pintu & Kusen Elegan
	makePart(m, "Door", Vector3.new(0.6, 0.95, 0.05), origin * CFrame.new(-0.55, -0.22, -1.01), Color3.fromRGB(85, 45, 20), Enum.Material.WoodPlanks)

	-- Dua Jendela Kaca dengan Teralis
	makePart(m, "Window1", Vector3.new(0.55, 0.6, 0.05), origin * CFrame.new(0.25, 0.05, -1.01), Color3.fromRGB(150, 210, 245), Enum.Material.Glass)
	makePart(m, "Window2", Vector3.new(0.55, 0.6, 0.05), origin * CFrame.new(0.85, 0.05, -1.01), Color3.fromRGB(150, 210, 245), Enum.Material.Glass)

	-- Kanopi Baja Ringan Khas Perumahan Indonesia (Carport depan)
	local canopyRoof = makePart(m, "CanopyRoof", Vector3.new(1.5, 0.06, 1.1), origin * CFrame.new(0.55, 0.45, -1.5), Color3.fromRGB(90, 140, 190), Enum.Material.SmoothPlastic)
	-- Tiang Kanopi
	makePart(m, "CanopyPole1", Vector3.new(0.08, 0.95, 0.08), origin * CFrame.new(-0.15, -0.05, -2.0), Color3.fromRGB(160, 160, 160), Enum.Material.Metal)
	makePart(m, "CanopyPole2", Vector3.new(0.08, 0.95, 0.08), origin * CFrame.new(1.25, -0.05, -2.0), Color3.fromRGB(160, 160, 160), Enum.Material.Metal)

	-- Outdoor AC Unit di Dinding Samping
	makePart(m, "ACUnit", Vector3.new(0.35, 0.3, 0.5), origin * CFrame.new(-1.3, 0.2, -0.2), Color3.fromRGB(240, 240, 240), Enum.Material.Metal)

	-- Lis Indikator Tim (Garis neon ganda)
	makePart(m, "TeamStripe", Vector3.new(2.55, 0.15, 0.06), origin * CFrame.new(0, 0.62, -1.01), teamColor, Enum.Material.Neon)

	m.PrimaryPart = mainBody
	return m
end

-- =========================================================================
-- LEVEL 3: RUMAH OKB (Orang Kaya Baru - Modern Luxury Villa 2 Lantai)
-- =========================================================================
local function createOKB(tileCF: CFrame, teamColor: Color3): Model
	local m = Instance.new("Model")
	m.Name = "RumahOKB"

	local origin = tileCF * CFrame.new(0, 0.4 + 1.25, 1.6)

	-- Lantai 1 (Granit modern abu gelap & marmer putih)
	local firstFloor = makePart(m, "Floor1", Vector3.new(2.8, 1.2, 2.2), origin * CFrame.new(0, -0.65, 0), Color3.fromRGB(60, 65, 75), Enum.Material.Concrete)

	-- Lantai 2 (Kamar mewah + balkon)
	local secondFloor = makePart(m, "Floor2", Vector3.new(2.6, 1.2, 1.8), origin * CFrame.new(0.1, 0.55, 0.2), Color3.fromRGB(250, 250, 252), Enum.Material.SmoothPlastic)

	-- Atap Miring Modern Minimalis
	local roofWedge = makeWedge(m, "ModernRoof", Vector3.new(2.1, 0.55, 2.9),
		origin * CFrame.new(0.1, 1.35, 0.15) * CFrame.Angles(0, math.rad(180), 0),
		Color3.fromRGB(40, 42, 48), Enum.Material.Metal)

	-- Balkon Lantai 2 (Kaca Tempered & Stainless)
	makePart(m, "BalconyFloor", Vector3.new(1.8, 0.1, 0.8), origin * CFrame.new(0.2, -0.05, -0.9), Color3.fromRGB(45, 50, 58), Enum.Material.Metal)
	makePart(m, "BalconyGlass", Vector3.new(1.8, 0.4, 0.05), origin * CFrame.new(0.2, 0.2, -1.3), Color3.fromRGB(140, 220, 245), Enum.Material.Glass)

	-- Jendela Panorama Lantai 2
	makePart(m, "PanoWindow", Vector3.new(1.4, 0.65, 0.05), origin * CFrame.new(0.2, 0.6, -0.71), Color3.fromRGB(140, 220, 245), Enum.Material.Glass)

	-- Pintu Mewah Utama Lantai 1 (Pintu geser kayu lebar)
	makePart(m, "LuxuryDoor", Vector3.new(0.85, 0.95, 0.05), origin * CFrame.new(-0.65, -0.75, -1.11), Color3.fromRGB(45, 25, 15), Enum.Material.WoodPlanks)

	-- Pilar Teras Marmer
	makePart(m, "Pillar", Vector3.new(0.2, 1.2, 0.2), origin * CFrame.new(1.2, -0.65, -1.1), Color3.fromRGB(230, 230, 230), Enum.Material.Marble)

	-- Lampu Warm / Sorot Fasad
	makePart(m, "WarmLightStrip", Vector3.new(1.5, 0.08, 0.08), origin * CFrame.new(0.2, -0.1, -1.11), Color3.fromRGB(255, 230, 160), Enum.Material.Neon)

	-- Aksen Emas & Lis Tim Mewah
	makePart(m, "GoldTrim", Vector3.new(2.85, 0.12, 0.06), origin * CFrame.new(0, -0.05, -1.11), Color3.fromRGB(230, 190, 70), Enum.Material.Metal)
	makePart(m, "TeamBadge", Vector3.new(0.7, 0.7, 0.08), origin * CFrame.new(0.9, 0.55, -0.72), teamColor, Enum.Material.Neon)

	m.PrimaryPart = firstFloor
	return m
end

-- =========================================================================
-- GERBANG JALAN TOL (G-TOLL BARRICADE GATEWAY)
-- =========================================================================
local function createGerbangTol(tileCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "GerbangTol"

	-- Diletakkan melintang pas di atas petak
	local origin = tileCF * CFrame.new(0, 0.4 + 1.2, 0)

	-- Tiang Kiri & Kanan (Hazard Yellow / Black Striped)
	local pL = makePart(m, "PillarLeft", Vector3.new(0.5, 2.4, 0.5), origin * CFrame.new(-2.2, 0, 0), Color3.fromRGB(240, 190, 30), Enum.Material.Metal)
	local pR = makePart(m, "PillarRight", Vector3.new(0.5, 2.4, 0.5), origin * CFrame.new(2.2, 0, 0), Color3.fromRGB(240, 190, 30), Enum.Material.Metal)

	-- Palang Atap Gantry Tol (Biru Highway PUPR)
	local gantry = makePart(m, "GantryBeam", Vector3.new(5.2, 0.7, 0.9), origin * CFrame.new(0, 1.2, 0), Color3.fromRGB(25, 75, 165), Enum.Material.Metal)

	-- Plang Teks G-TOLL
	local sign = makePart(m, "SignGTOLL", Vector3.new(2.4, 0.45, 0.1), origin * CFrame.new(0, 1.2, -0.46), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)

	-- SurfaceGui untuk teks G-TOLL
	local sg = Instance.new("SurfaceGui")
	sg.Name = "GTOLLGui"
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(240, 60)
	sg.Parent = sign

	local tb = Instance.new("TextLabel")
	tb.Size = UDim2.new(1, 0, 1, 0)
	tb.BackgroundTransparency = 1
	tb.Text = "G-TOLL OTOMATIS"
	tb.TextColor3 = Color3.fromRGB(20, 50, 130)
	tb.TextScaled = true
	tb.Font = Enum.Font.GothamBlack
	tb.Parent = sg

	-- Palang Tol (Boom Barrier) Merah Putih Menutup Jalan
	local barrierBar = makePart(m, "BoomBarrier", Vector3.new(3.8, 0.18, 0.18), origin * CFrame.new(0, -0.4, -0.3), Color3.fromRGB(220, 40, 30), Enum.Material.Neon)

	-- Garis Putih pada Palang Tol
	makePart(m, "Stripe1", Vector3.new(0.6, 0.2, 0.2), origin * CFrame.new(-1.0, -0.4, -0.3), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	makePart(m, "Stripe2", Vector3.new(0.6, 0.2, 0.2), origin * CFrame.new(0.3, -0.4, -0.3), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)

	-- Mesin Tapping Kartu Tol
	makePart(m, "TapBooth", Vector3.new(0.4, 0.8, 0.5), origin * CFrame.new(-1.6, -0.8, -0.3), Color3.fromRGB(40, 45, 50), Enum.Material.Metal)
	makePart(m, "TapCardReader", Vector3.new(0.25, 0.25, 0.05), origin * CFrame.new(-1.6, -0.6, -0.56), Color3.fromRGB(50, 200, 100), Enum.Material.Neon)

	m.PrimaryPart = gantry
	return m
end

-- =========================================================================
-- API UTAMA
-- =========================================================================

-- Memperbarui visual petak: jika level/tol/tim sama, tidak dibuat ulang agar efisien.
function BuildingVisualService.update(
	buildingsFolder: Folder,
	tile: BasePart,
	index: number,
	level: number,
	isToll: boolean,
	team: string?
)
	local modelName = "B_" .. tostring(index)
	local existing = buildingsFolder:FindFirstChild(modelName)

	-- Jika tidak ada bangunan dan bukan tol, bersihkan jika ada
	if level == 0 and not isToll then
		if existing then
			existing:Destroy()
		end
		return
	end

	-- Periksa apakah tampilan saat ini sudah cocok
	if existing and existing:IsA("Model") then
		local curLevel = existing:GetAttribute("Level")
		local curToll = existing:GetAttribute("IsToll")
		local curTeam = existing:GetAttribute("Team")
		if curLevel == level and curToll == isToll and curTeam == (team or "NONE") then
			return -- Sudah pas, lewati pembuatan ulang
		end
		existing:Destroy()
	elseif existing then
		existing:Destroy()
	end

	local teamColor = (team and TEAM_COLORS[team]) or Color3.fromRGB(200, 200, 200)
	local newModel: Model? = nil

	if isToll then
		newModel = createGerbangTol(tile.CFrame)
	elseif level == 1 then
		newModel = createSubsidi1(tile.CFrame, teamColor)
	elseif level == 2 then
		newModel = createSubsidi2(tile.CFrame, teamColor)
	elseif level >= 3 then
		newModel = createOKB(tile.CFrame, teamColor)
	end

	if newModel then
		newModel.Name = modelName
		newModel:SetAttribute("Level", level)
		newModel:SetAttribute("IsToll", isToll)
		newModel:SetAttribute("Team", team or "NONE")
		newModel.Parent = buildingsFolder
	end
end

-- Menghapus semua visualisasi bangunan di board (misal saat restart/rematch)
function BuildingVisualService.clearAll(buildingsFolder: Folder)
	for _, child in ipairs(buildingsFolder:GetChildren()) do
		child:Destroy()
	end
end

return BuildingVisualService
