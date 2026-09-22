--!strict
-- Explicit test rules. These values do not represent verified original board-game rules.
local Rules = {
	Version = "prototype-0.1",
	PrototypeOnly = true,
	PlayerCount = 4,
	TileCount = 40,
	StartingCash = 10000000,
	StartSalary = 1000000,
	PropertyPrice = 1000000,
	PropertyRent = 250000,
	LiquidationValue = 500000,
	TaxAmount = 500000,
	ParkingAmount = 250000,
	PracticeFateReward = 200000,
	PracticeDisasterCharge = 200000,
	MaxRounds = 8,
	DecisionSeconds = 30,
	RequestInterval = 0.2,
	JailBailAmount = 1500000,
	CourtCompensation = 1000000,
	CourtFine = 1500000,
	Description = "PROTOTIPE UJI: 4 pemain, 2v2, modal Rp10 juta, gaji START Rp1 juta, batas 8 ronde. Harga tanah, sewa per level, biaya Subsidi/OKB, dan nilai likuidasi mengikuti TarifData per petak; sebagian tarif masih ditandai perkiraan/adaptasi. Saldo dan aset tetap pribadi; rekan satu tim bebas sewa kecuali aturan khusus seperti pemilik ditahan. Skor akhir menghitung uang tunai dan nilai likuidasi aset sesuai tarif prototipe. Likuidasi otomatis terjadi saat dana kurang; gagal bayar menyebabkan eliminasi dan aset terkait dilepas. Keluar saat match aktif membatalkan sesi lokal tanpa hasil akun tersimpan. Kartu Takdir dan Musibah memiliki efek per kartu dengan status verified/partial/adapted di CardData. LAPAS: dadu kembar, titipan Rp1,5 juta, atau bebas otomatis pada percobaan ketiga; sewa pemilik tahanan masuk Negara. Pengadilan: 5-6 menerima Rp1 juta, 3-4 bayar Rp1,5 juta lalu LAPAS, 1-2 bayar 50% uang tunai lalu LAPAS. Tanah dapat menjadi TOL permanen melalui kartu. Banjir Bandang mengevakuasi pion ke Bekasi, melewati 1 giliran, dan memakai denda/kepulangan yang masih ditandai sebagai adaptasi prototipe.",
}

function Rules.teamForSeat(seat: number): string
	return if seat % 2 == 1 then "A" else "B"
end

function Rules.formatMoney(amount: number): string
	local digits = tostring(math.floor(math.abs(amount)))
	local reversed = string.reverse(digits)
	local grouped = string.gsub(reversed, "(%d%d%d)", "%1.")
	grouped = string.reverse(grouped)
	if string.sub(grouped, 1, 1) == "." then
		grouped = string.sub(grouped, 2)
	end
	return (if amount < 0 then "-Rp" else "Rp") .. grouped
end

return table.freeze(Rules)
