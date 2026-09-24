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
	-- Batas XP untuk setiap level (Level 1 sampai 25)
	XP_PER_LEVEL = 350,

	-- Gelar Kehormatan berdasarkan Level Pemain
	TITLES = {
		{ MinLevel = 1, Title = "Warga Biasa" },
		{ MinLevel = 3, Title = "Warga Teladan" },
		{ MinLevel = 6, Title = "Pedagang Pasar" },
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

function ProgressionConfig.calculateLevel(totalXP: number): (number, number, number)
	local level = math.floor(totalXP / ProgressionConfig.XP_PER_LEVEL) + 1
	local currentLevelXP = totalXP % ProgressionConfig.XP_PER_LEVEL
	local neededXP = ProgressionConfig.XP_PER_LEVEL
	return level, currentLevelXP, neededXP
end

return table.freeze(ProgressionConfig)
