--!strict
-- ProgressionConfig.luau
-- Konfigurasi XP, level, gelar kehormatan Nusantara, dan katalog skin dadu 3D.

export type DiceSkin = {
	Name: string,
	Material: Enum.Material,
	Color: Color3,
	DotColor: Color3,
	RequiredLevel: number,
}

local ProgressionConfig = {
	-- Batas XP untuk naik level
	XP_PER_LEVEL = 350,

	-- Level maksimum yang dapat dicapai
	MAX_LEVEL = 25,

	-- Gelar Kehormatan berdasarkan Level Pemain
	TITLES = {
		{ MinLevel = 1,  Title = "Warga Biasa" },
		{ MinLevel = 3,  Title = "Warga Teladan" },
		{ MinLevel = 6,  Title = "Pedagang Pasar" },
		{ MinLevel = 10, Title = "Juragan Tanah" },
		{ MinLevel = 15, Title = "Cukong Properti" },
		{ MinLevel = 20, Title = "Konglomerat" },
		{ MinLevel = 25, Title = "Sultan Nusantara 👑" },
	},

	-- Katalog Skin Dadu 3D
	DICE_SKINS = {
		Classic = {
			Name = "Klasik Putih",
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(245, 245, 245),
			DotColor = Color3.fromRGB(25, 25, 25),
			RequiredLevel = 1,
		},
		Mahogany = {
			Name = "Kayu Mahoni Emas",
			Material = Enum.Material.WoodPlanks,
			Color = Color3.fromRGB(115, 65, 35),
			DotColor = Color3.fromRGB(240, 200, 90),
			RequiredLevel = 3,
		},
		NeonCyan = {
			Name = "Kristal Neon Cyan",
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(45, 220, 200),
			DotColor = Color3.fromRGB(255, 255, 255),
			RequiredLevel = 7,
		},
		GoldSultan = {
			Name = "Emas Batangan Sultan",
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(245, 195, 50),
			DotColor = Color3.fromRGB(50, 40, 20),
			RequiredLevel = 12,
		},
	} :: {[string]: DiceSkin},
}

function ProgressionConfig.getTitleForLevel(level: number): string
	local selected = "Warga Biasa"
	for _, entry in ipairs(ProgressionConfig.TITLES) do
		if level >= entry.MinLevel then
			selected = entry.Title
		end
	end
	return selected
end

-- Returns (cappedLevel, currentLevelXP, xpNeededForNextLevel)
function ProgressionConfig.calculateLevel(totalXP: number): (number, number, number)
	local raw = math.floor(totalXP / ProgressionConfig.XP_PER_LEVEL) + 1
	local level = math.min(raw, ProgressionConfig.MAX_LEVEL)
	local currentLevelXP = if level >= ProgressionConfig.MAX_LEVEL
		then ProgressionConfig.XP_PER_LEVEL  -- show full bar at max level
		else totalXP % ProgressionConfig.XP_PER_LEVEL
	local neededXP = ProgressionConfig.XP_PER_LEVEL
	return level, currentLevelXP, neededXP
end

-- Returns ordered list of {key, skin} that player has unlocked at given level
function ProgressionConfig.getUnlockedSkins(level: number): {{key: string, skin: DiceSkin}}
	local ORDER = {"Classic", "Mahogany", "NeonCyan", "GoldSultan"}
	local unlocked: {{key: string, skin: DiceSkin}} = {}
	for _, key in ipairs(ORDER) do
		local skin = ProgressionConfig.DICE_SKINS[key]
		if skin and level >= skin.RequiredLevel then
			table.insert(unlocked, {key = key, skin = skin})
		end
	end
	return unlocked
end

return table.freeze(ProgressionConfig)

