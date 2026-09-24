--!strict
-- RoleConfig.luau
-- Konfigurasi 4 Profesi Khas Nusantara dengan keahlian pasif (Passive Perks).

export type RoleDefinition = {
	id: string,
	name: string,
	desc: string,
	perkSummary: string,
	icon: string,
	badgeColor: Color3,
}

local ROLES: {[string]: RoleDefinition} = {
	PNS = {
		id = "PNS",
		name = "PNS Teladan",
		desc = "Aparatur sipil teladan dengan tunjangan kinerja stabil.",
		perkSummary = "Gaji START +25% (THR & Gaji ke-13)",
		icon = "🏛️",
		badgeColor = Color3.fromRGB(60, 140, 240),
	},
	JURAGAN = {
		id = "JURAGAN",
		name = "Juragan Tanah",
		desc = "Tuan tanah kawakan yang ahli menawar properti murah.",
		perkSummary = "Diskon 15% beli tanah & renovasi aset",
		icon = "🏰",
		badgeColor = Color3.fromRGB(240, 165, 40),
	},
	INFLUENCER = {
		id = "INFLUENCER",
		name = "Influencer Viral",
		desc = "Selebgram centang biru dengan jutaan followers setia.",
		perkSummary = "Bebas Pajak & Parkir (Bayar Pake Eksposur)",
		icon = "⭐",
		badgeColor = Color3.fromRGB(225, 60, 165),
	},
	PENGACARA = {
		id = "PENGACARA",
		name = "Pengacara Kondang",
		desc = "Pakar hukum lihai yang memahami seluk beluk praperadilan.",
		perkSummary = "Diskon 50% jaminan Lapas & ahli Sidang Tipikor",
		icon = "⚖️",
		badgeColor = Color3.fromRGB(40, 195, 125),
	},
}

local RoleConfig = {}

function RoleConfig.get(id: string): RoleDefinition
	return ROLES[id] or ROLES.PNS
end

function RoleConfig.all(): {RoleDefinition}
	return {
		ROLES.PNS,
		ROLES.JURAGAN,
		ROLES.INFLUENCER,
		ROLES.PENGACARA,
	}
end

function RoleConfig.assignRole(seatIndex: number): string
	local keys = {"PNS", "JURAGAN", "INFLUENCER", "PENGACARA"}
	local idx = ((seatIndex - 1) % #keys) + 1
	return keys[idx]
end

return RoleConfig
