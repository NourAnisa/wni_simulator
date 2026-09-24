--!strict
-- IslandEnvironmentService.luau
-- Bertanggung jawab membangun lingkungan 3D Nusantara yang hidup dan indah di sekeliling dan di tengah WNIBoard:
-- 1. Miniatur Monas Emas (Tugu Nasional) di tengah papan dengan lidah api neon bercahaya.
-- 2. Taman Rumput Nusantara & Pohon Kelapa Tropis di 4 sudut tengah.
-- 3. Laut Tropis Biru Toska di bawah papan dengan efek kepulauan.
-- 4. Umbul-Umbul Merah Putih di sudut-sudut perayaan.

local Workspace = game:GetService("Workspace")

local IslandEnvironmentService = {}

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, transparency: number?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = true
	p.Parent = parent
	return p
end

local function makeCylinder(parent: Instance, name: string, length: number, radius: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(length, radius * 2, radius * 2)
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
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

local function makeSphere(parent: Instance, name: string, diameter: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(diameter, diameter, diameter)
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

-- Membangun pohon kelapa bergaya kartun tropis
local function buildPalmTree(parent: Instance, basePos: Vector3, angleY: number)
	local trunkColor = Color3.fromRGB(130, 95, 60)
	local leafColor = Color3.fromRGB(50, 160, 65)
	local leafColor2 = Color3.fromRGB(65, 185, 75)

	local currentCF = CFrame.new(basePos) * CFrame.Angles(0, math.rad(angleY), 0)
	-- Batang melengkung bertahap (3 ruas silinder)
	local segHeight = 2.4
	for i = 1, 3 do
		local tilt = math.rad(i * 3.5)
		local segCF = currentCF * CFrame.new(0, segHeight * 0.5, i * 0.25) * CFrame.Angles(tilt, 0, 0)
		makeCylinder(parent, "Trunk_" .. i, segHeight, 0.45 - (i * 0.05), segCF, trunkColor, Enum.Material.Wood)
		currentCF = currentCF * CFrame.new(0, segHeight, i * 0.3) * CFrame.Angles(tilt, 0, 0)
	end

	-- Kelapa di pucuk (3 buah)
	for k = 1, 3 do
		local coconutCF = currentCF * CFrame.Angles(0, math.rad(k * 120), 0) * CFrame.new(0.4, -0.2, 0)
		makeSphere(parent, "Coconut", 0.55, coconutCF, Color3.fromRGB(90, 70, 45), Enum.Material.Wood)
	end

	-- Daun kelapa melengkung (6 pelepah)
	for j = 1, 6 do
		local rot = math.rad(j * 60)
		local leafCF = currentCF * CFrame.Angles(0, rot, 0) * CFrame.new(0, 0, 1.8) * CFrame.Angles(math.rad(-22), 0, 0)
		local col = if j % 2 == 0 then leafColor else leafColor2
		makeWedge(parent, "LeafWedge_" .. j, Vector3.new(0.9, 0.35, 3.8), leafCF, col, Enum.Material.Grass)
	end
end

-- Membangun Tugu Monas Megah (National Monument)
local function buildMonas(parent: Instance, centerPos: Vector3)
	local marbleWhite = Color3.fromRGB(245, 245, 248)
	local goldColor = Color3.fromRGB(255, 215, 35)

	-- 1. Pelataran Bawah (Candi Dasar Bertingkat)
	makePart(parent, "MonasPlaza1", Vector3.new(16, 0.6, 16), CFrame.new(centerPos + Vector3.new(0, 0.3, 0)), Color3.fromRGB(220, 220, 225), Enum.Material.Concrete)
	makePart(parent, "MonasPlaza2", Vector3.new(12, 0.8, 12), CFrame.new(centerPos + Vector3.new(0, 1.0, 0)), marbleWhite, Enum.Material.Concrete)

	-- 2. Cawan Bawah (Pelataran Museum Cawan Monas)
	makePart(parent, "MonasCawanBase", Vector3.new(8, 1.2, 8), CFrame.new(centerPos + Vector3.new(0, 2.0, 0)), marbleWhite, Enum.Material.Concrete)
	makePart(parent, "MonasCawanDeck", Vector3.new(10, 0.4, 10), CFrame.new(centerPos + Vector3.new(0, 2.8, 0)), Color3.fromRGB(210, 210, 218), Enum.Material.Concrete)

	-- 3. Tugu Tiang Obelisk Menjulang Tinggi
	local tower = makePart(parent, "MonasObelisk", Vector3.new(2.8, 15, 2.8), CFrame.new(centerPos + Vector3.new(0, 10.5, 0)), marbleWhite, Enum.Material.SmoothPlastic)

	-- 4. Pelataran Puncak (Observation Deck)
	makePart(parent, "MonasTopDeck", Vector3.new(4.2, 0.6, 4.2), CFrame.new(centerPos + Vector3.new(0, 18.3, 0)), Color3.fromRGB(215, 215, 222), Enum.Material.Concrete)

	-- 5. Lidah Api Kemerdekaan Emas Berkilau (Golden Flame)
	local flameCF = CFrame.new(centerPos + Vector3.new(0, 20.4, 0))
	local flame = makeSphere(parent, "MonasFlameBase", 2.2, flameCF, goldColor, Enum.Material.Neon)
	makeWedge(parent, "MonasFlameTip", Vector3.new(1.8, 2.4, 1.8), flameCF * CFrame.new(0, 1.4, 0), goldColor, Enum.Material.Neon)

	-- Cahaya Lilin Keemasan dari Api Monas
	local light = Instance.new("PointLight")
	light.Name = "MonasGlow"
	light.Color = Color3.fromRGB(255, 225, 120)
	light.Range = 32
	light.Brightness = 2.2
	light.Shadows = true
	light.Parent = flame

	-- Partikel Kilau Emas
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "FlameSparks"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 20)),
	})
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Lifetime = NumberRange.new(0.8, 1.6)
	pe.Rate = 12
	pe.Speed = NumberRange.new(1.5, 3.5)
	pe.SpreadAngle = Vector2.new(25, 25)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.Parent = flame
end

-- Membangun Umbul-Umbul / Bendera Merah Putih
local function buildFestivalPoles(parent: Instance, centerPos: Vector3)
	local offsets = {
		Vector3.new(18, 0, 18),
		Vector3.new(-18, 0, 18),
		Vector3.new(18, 0, -18),
		Vector3.new(-18, 0, -18),
	}

	for idx, offset in ipairs(offsets) do
		local polePos = centerPos + offset
		local pole = makeCylinder(parent, "FlagPole_" .. idx, 6.0, 0.08, CFrame.new(polePos + Vector3.new(0, 3.0, 0)), Color3.fromRGB(230, 230, 235), Enum.Material.Metal)
		-- Puncak Emas
		makeSphere(parent, "PoleFinial", 0.35, CFrame.new(polePos + Vector3.new(0, 6.15, 0)), Color3.fromRGB(255, 215, 50), Enum.Material.Neon)
		-- Bendera Merah Putih Berkibar
		local flagRed = makePart(parent, "FlagRed", Vector3.new(1.8, 0.6, 0.05), CFrame.new(polePos + Vector3.new(0.9, 5.5, 0)), Color3.fromRGB(215, 30, 30), Enum.Material.Fabric)
		local flagWhite = makePart(parent, "FlagWhite", Vector3.new(1.8, 0.6, 0.05), CFrame.new(polePos + Vector3.new(0.9, 4.9, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.Fabric)
	end
end

-- ============================================================================
-- MAIN ENTRY POINT: GENERATE NUSANTARA ENVIRONMENT
-- ============================================================================
function IslandEnvironmentService.generateEnvironment(board: Instance)
	if not board or not board:IsA("Model") then return end

	local decorations = board:FindFirstChild("Decorations")
	if not decorations then
		decorations = Instance.new("Folder")
		decorations.Name = "Decorations"
		decorations.Parent = board
	end

	-- Hapus lingkungan lama jika pernah dibuat sebelumnya
	local oldEnv = decorations:FindFirstChild("NusantaraEnvironment")
	if oldEnv then
		oldEnv:Destroy()
	end

	local envFolder = Instance.new("Folder")
	envFolder.Name = "NusantaraEnvironment"
	envFolder.Parent = decorations

	-- Cari titik pusat papan dari Tiles atau Pivot
	local tilesFolder = board:FindFirstChild("Tiles")
	local boardCenter = Vector3.new(0, 0, 0)
	if tilesFolder and #tilesFolder:GetChildren() >= 40 then
		local t1 = tilesFolder:FindFirstChild("Tile_01") :: BasePart?
		local t21 = tilesFolder:FindFirstChild("Tile_21") :: BasePart?
		if t1 and t21 then
			boardCenter = (t1.Position + t21.Position) * 0.5
		end
	else
		boardCenter = board:GetPivot().Position
	end

	local baseY = boardCenter.Y

	-- 1. Laut Tropis Biru Toska Luas di Bawah Papan
	local ocean = makePart(
		envFolder,
		"TropicalOcean",
		Vector3.new(220, 2.5, 220),
		CFrame.new(boardCenter.X, baseY - 3.2, boardCenter.Z),
		Color3.fromRGB(32, 160, 210),
		Enum.Material.Glass,
		0.2
	)

	-- Dasar Pasir Lautan
	makePart(
		envFolder,
		"OceanSeabed",
		Vector3.new(240, 1.0, 240),
		CFrame.new(boardCenter.X, baseY - 5.0, boardCenter.Z),
		Color3.fromRGB(235, 215, 175),
		Enum.Material.Sand
	)

	-- Busa Ombak Halus di Sekeliling Papan
	makePart(
		envFolder,
		"SurfFoamRing",
		Vector3.new(94, 0.4, 94),
		CFrame.new(boardCenter.X, baseY - 1.8, boardCenter.Z),
		Color3.fromRGB(245, 250, 255),
		Enum.Material.SmoothPlastic,
		0.4
	)

	-- 2. Taman Rumput Hijau Nusantara di Tengah Papan (Ukuran 48x48 stud)
	makePart(
		envFolder,
		"NusantaraCenterPlaza",
		Vector3.new(48, 0.35, 48),
		CFrame.new(boardCenter.X, baseY + 0.15, boardCenter.Z),
		Color3.fromRGB(85, 170, 75),
		Enum.Material.Grass
	)

	-- Lis Trotoar Marmer Halus di Sekitar Taman
	makePart(
		envFolder,
		"PlazaBorder",
		Vector3.new(50, 0.25, 50),
		CFrame.new(boardCenter.X, baseY + 0.1, boardCenter.Z),
		Color3.fromRGB(225, 225, 230),
		Enum.Material.Concrete
	)

	-- Jalan Setapak Silang Menuju Monas
	makePart(
		envFolder,
		"PathX",
		Vector3.new(46, 0.4, 3.6),
		CFrame.new(boardCenter.X, baseY + 0.18, boardCenter.Z),
		Color3.fromRGB(230, 215, 195),
		Enum.Material.Cobblestone
	)
	makePart(
		envFolder,
		"PathZ",
		Vector3.new(3.6, 0.4, 46),
		CFrame.new(boardCenter.X, baseY + 0.18, boardCenter.Z),
		Color3.fromRGB(230, 215, 195),
		Enum.Material.Cobblestone
	)

	-- 3. Monas Megah di Titik Pusat
	buildMonas(envFolder, Vector3.new(boardCenter.X, baseY, boardCenter.Z))

	-- 4. 4 Pohon Kelapa Tropis di 4 Sudut Taman Tengah
	local palmPositions = {
		Vector3.new(15, baseY + 0.3, 15),
		Vector3.new(-15, baseY + 0.3, 15),
		Vector3.new(15, baseY + 0.3, -15),
		Vector3.new(-15, baseY + 0.3, -15),
	}
	for i, pos in ipairs(palmPositions) do
		buildPalmTree(envFolder, boardCenter + pos, (i - 1) * 90)
	end

	-- 5. Tiang Umbul-Umbul Merah Putih
	buildFestivalPoles(envFolder, boardCenter)

	print("[IslandEnvironmentService] Sukses membangun lingkungan 3D Nusantara & Monas Centerpiece.")
end

return IslandEnvironmentService
