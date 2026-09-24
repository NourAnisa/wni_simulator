--!strict
-- StockMarketConfig.luau
-- Konfigurasi Pasar Modal Mini Nusantara: Saham BUMN & Token Kripto Lokal.

export type StockItem = {
	id: string,
	name: string,
	ticker: string,
	desc: string,
	basePrice: number,
	minPrice: number,
	maxPrice: number,
	dividendRate: number, -- persentase dividen kas per ronde
	volatility: number,   -- persentase fluktuasi harga
	icon: string,
}

local STOCKS: {[string]: StockItem} = {
	BBUMN = {
		id = "BBUMN",
		name = "PT Tambang & Energi Nusantara",
		ticker = "BBUMN",
		desc = "Saham BUMN terpercaya dengan dividen kas rutin 8% per putaran.",
		basePrice = 500000,
		minPrice = 250000,
		maxPrice = 1200000,
		dividendRate = 0.08,
		volatility = 0.15,
		icon = "🏛️",
	},
	KRIPTO = {
		id = "KRIPTO",
		name = "Token Koin Gajah Mada",
		ticker = "GAJAH",
		desc = "Koin kripto spekulatif! Fluktuasi ekstrem tanpa dividen.",
		basePrice = 250000,
		minPrice = 50000,
		maxPrice = 2000000,
		dividendRate = 0.0,
		volatility = 0.50,
		icon = "🪙",
	},
}

local NEWS_TICKERS = {
	BUMN_UP = {
		"📈 Proyek strategis nasional BUMN temukan cadangan nikel jumbo!",
		"📈 Laporan keuangan BUMN kuartal ini mencatat rekor laba bersih!",
	},
	BUMN_DOWN = {
		"📉 Evaluasi tarif energi menahan pertumbuhan saham BUMN.",
		"📉 Koreksi wajar indeks harga saham BUMN di pasar reguler.",
	},
	KRIPTO_UP = {
		"🚀 KOL ternama endorse Token GAJAH! Harga meroket ke bulan!",
		"🚀 Komunitas whale memborong suplai Token GAJAH, to the moon!",
	},
	KRIPTO_DOWN = {
		"📉 Isu regulasi ketat aset kripto bikin pasar panik jual!",
		"📉 Founder token dikabarkan liburan ke luar negeri, harga dump!",
	},
}

local StockMarketConfig = {}

function StockMarketConfig.getAll(): {StockItem}
	return {STOCKS.BBUMN, STOCKS.KRIPTO}
end

function StockMarketConfig.get(id: string): StockItem
	return STOCKS[id] or STOCKS.BBUMN
end

function StockMarketConfig.getNews(stockId: string, isUp: boolean): string
	local key = if stockId == "BBUMN" then (if isUp then "BUMN_UP" else "BUMN_DOWN") else (if isUp then "KRIPTO_UP" else "KRIPTO_DOWN")
	local list = NEWS_TICKERS[key]
	return list[math.random(1, #list)]
end

return StockMarketConfig
