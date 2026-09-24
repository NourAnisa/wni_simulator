--!strict
-- AudioConfig.luau
-- Konfigurasi audio, ID musik latar (BGM) Nusantara, SFX, dan voice line meme reaksi cepat.

local AudioConfig = {
	-- Musik Latar Dinamis (Roblox Licensed Royalty-Free Tracks)
	BGM = {
		Lobby = {
			Id = "rbxassetid://9042549439", -- Down on the Farm 30 B (Acoustic / Warm Vibes)
			Volume = 0.32,
			Looped = true,
		},
		Match = {
			Id = "rbxassetid://9046053206", -- N'est-ce pas (Upbeat Retro Funk / Match Grooves)
			Volume = 0.30,
			Looped = true,
		},
		Climax = {
			Id = "rbxassetid://1843339357", -- Magic Mirrors 2 / Dramatic Tension (Rounds 6-8)
			Volume = 0.38,
			Looped = true,
		},
	},

	-- SFX Efek Suara Inti
	SFX = {
		RollDice = {
			Id = "rbxasset://sounds/switch.wav",
			Volume = 0.5,
		},
		CardDraw = {
			Id = "rbxasset://sounds/action_jump.mp3",
			Volume = 0.5,
		},
		SirenLapas = {
			Id = "rbxasset://sounds/electronicpingshort.wav",
			Volume = 0.6,
		},
		WinJingle = {
			Id = "rbxasset://sounds/victory.mp3",
			Volume = 0.7,
		},
		CoinClink = {
			Id = "rbxasset://sounds/electronicpingshort.wav",
			Volume = 0.45,
		},
		WaterSplash = {
			Id = "rbxasset://sounds/impact_water.mp3",
			Volume = 0.6,
		},
		ButtonClick = {
			Id = "rbxasset://sounds/button.wav",
			Volume = 0.35,
		},
	},

	-- Voice Chimes / Meme Soundboard Pitch Variations
	VoiceChimes = {
		Santai = { Text = "😎 Santai Dulu Gak Sih", Pitch = 1.0 },
		Bangkrut = { Text = "💀 Waduh Bangkrut!", Pitch = 0.8 },
		Sultan = { Text = "👑 Ampun Sultan!", Pitch = 1.25 },
		Bekasi = { Text = "🛸 Meluncur ke Bekasi!", Pitch = 1.4 },
	},
}

return table.freeze(AudioConfig)
