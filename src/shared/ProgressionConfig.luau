--!strict
-- ProgressionConfig.luau
-- Konfigurasi XP, level, gelar kehormatan Nusantara, dan katalog skin dadu 3D.

export type DiceSkin = {
	Name: string,
	Material: Enum.Material,
	Color: Color3,
	DotColor: Color3,
	RequiredLevel: number,
	Price: number,
	Icon: string,
	Desc: string,
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

	-- Urutan Tampilan di Toko Kosmetik
	SKIN_ORDER = {"Classic", "Mahogany", "BatuAkik", "NeonCyan", "TahuBulat", "MerahPutih", "GoldSultan"},

	-- Katalog Skin Dadu 3D Khas Nusantara
	DICE_SKINS = {
		Classic = {
			Name = "Klasik Putih",
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(245, 245, 245),
			DotColor = Color3.fromRGB(25, 25, 25),
			RequiredLevel = 1,
			Price = 0,
			Icon = "⬜",
			Desc = "Dadu standar andalan warga nusantara.",
		},
		Mahogany = {
			Name = "Kayu Jati Jepara",
			Material = Enum.Material.WoodPlanks,
			Color = Color3.fromRGB(115, 65, 35),
			DotColor = Color3.fromRGB(240, 200, 90),
			RequiredLevel = 2,
			Price = 500,
			Icon = "🪵",
			Desc = "Ukiran kayu jati asli Jepara nan berwibawa.",
		},
		BatuAkik = {
			Name = "Batu Akik Bacan",
			Material = Enum.Material.Glass,
			Color = Color3.fromRGB(35, 160, 110),
			DotColor = Color3.fromRGB(255, 255, 255),
			RequiredLevel = 4,
			Price = 1200,
			Icon = "💎",
			Desc = "Pancaran hijau giok pembawa hoki dan berkah.",
		},
		NeonCyan = {
			Name = "Kristal Monas",
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(45, 220, 200),
			DotColor = Color3.fromRGB(255, 255, 255),
			RequiredLevel = 6,
			Price = 2500,
			Icon = "🩵",
			Desc = "Cahaya neon futuristik kebanggaan ibu kota.",
		},
		TahuBulat = {
			Name = "Tahu Bulat Gurih",
			Material = Enum.Material.Sand,
			Color = Color3.fromRGB(215, 150, 65),
			DotColor = Color3.fromRGB(60, 35, 15),
			RequiredLevel = 8,
			Price = 4500,
			Icon = "🧆",
			Desc = "Digoreng dadakan di mobil lima ratusan, gurih!",
		},
		MerahPutih = {
			Name = "Garuda Merah Putih",
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(220, 45, 45),
			DotColor = Color3.fromRGB(255, 255, 255),
			RequiredLevel = 10,
			Price = 7500,
			Icon = "🇮🇩",
			Desc = "Kobaran semangat juang persatuan Nusantara.",
		},
		GoldSultan = {
			Name = "Emas Antam 24K",
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(245, 195, 50),
			DotColor = Color3.fromRGB(50, 40, 20),
			RequiredLevel = 15,
			Price = 15000,
			Icon = "👑",
			Desc = "Kemewahan mutlak sang Sultan sejati Nusantara.",
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
	local unlocked: {{key: string, skin: DiceSkin}} = {}
	for _, key in ipairs(ProgressionConfig.SKIN_ORDER) do
		local skin = ProgressionConfig.DICE_SKINS[key]
		if skin and level >= skin.RequiredLevel then
			table.insert(unlocked, {key = key, skin = skin})
		end
	end
	return unlocked
end

return table.freeze(ProgressionConfig)

