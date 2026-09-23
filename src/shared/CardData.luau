--!strict
-- Dek kartu WNI Simulator. Sumber: README bagian 3, 4, 11-14, 20-24, 29, 31, 33.
-- status: "verified" = teks kartu terbaca; "partial" = sebagian cabang belum terbaca;
-- "adapted" = adaptasi digital eksplisit, bukan aturan asli.
export type Card = {
	id: string,
	deck: string,
	name: string,
	dice: boolean,
	status: string,
	note: string,
}
local FATE = "Fate"
local DISASTER = "Disaster"
local D: {[string]: Card} = {}
local function add(id: string, deck: string, name: string, dice: boolean, status: string, note: string)
	D[id] = {id = id, deck = deck, name = name, dice = dice, status = status, note = note}
end
-- TAKDIR
add("TambangIlegal", FATE, "Tambang Ilegal", true, "partial", "Genap: tanah pilihan dikembalikan ke Negara. Ganjil: tanahmu termahal jadi tol permanen. Cabang tanpa pemilik tanah belum terverifikasi.")
add("WIBU", FATE, "WIBU", true, "partial", "Genap: pindah ke Bandung. Ganjil: lewati 1 giliran + bayar 500rb. Waktu skip belum terverifikasi.")
add("BateraiSekarat", FATE, "Baterai Sekarat", true, "adapted", "ADAPTASI: kategori via dadu (5-6 aman, 3-4 500rb, 1-2 1jt). Kartu asli memeriksa HP pemain.")
add("PembebasanLahan", FATE, "Pembebasan Lahan", false, "verified", "Boleh pilih satu tanah milik lawan; disita dan jadi tol permanen. Boleh dilewati.")
add("MafiaTanah", FATE, "Mafia Tanah", false, "verified", "Ambil gratis satu tanah belum dibeli. Semua terbeli: abaikan.")
-- MUSIBAH
add("KPK", DISASTER, "Penggeledahan KPK", true, "verified", "5-6 bayar 300rb admin; 3-4 sewa nonaktif sampai giliranmu kembali; 1-2 LAPAS + 500rb.")
add("PHK", DISASTER, "Kena PHK", true, "partial", "5-6 semua tanpa gaji 1 putaran; 3-4 semua larangan membeli 1 putaran; 1-2 semua ke Pengadilan. Definisi 1 putaran belum terverifikasi.")
add("SubsidiBBM", DISASTER, "Subsidi BBM Dicabut", true, "partial", "5-6 aman; 3-4 pengambil 400rb lain 200rb; 1-2 pengambil 600rb (sementara) lain 400rb.")
add("Sandwich", DISASTER, "Generasi Sandwich", true, "partial", "5-6 kamu+tertua 200rb ke termuda; 3-4 kamu 700rb ke termuda; 1-2 tanah termahalmu ke termuda, tanpa tanah bayar 2jt. Urutan usia = urutan kursi (adaptasi).")
add("Boomers", DISASTER, "Awas Ada Boomers!!!", true, "partial", "5-6 semua larangan membeli 1 putaran; 3-4 bayar 500rb ke tertua; 1-2 tanah termahalmu ke tertua, tanpa tanah 3,5jt.")
add("BanjirBandang", DISASTER, "Banjir Bandang", false, "partial", "Teramati: pion dikirim ke Bekasi + lewat 1 giliran (README 31). Denda 400rb dan kepulangan ke petak asal setelah giliran dilewati adalah adaptasi; cara kembali asli belum terverifikasi.")
add("Begal", DISASTER, "Korban Begal", false, "partial", "Lewati giliran berikutnya + 400rb ke Negara. Cabang Lampung terpotong di video.")
add("PengalihanIsu", DISASTER, "Pengalihan Isu", false, "verified", "Langsung masuk LAPAS.")
add("Buzzer", DISASTER, "Buzzer", true, "partial", "Genap +800rb dari Negara. Cabang ganjil tertutup jari (adaptasi: ganjil bayar 400rb, ditandai).")
-- Kartu tangan (simpanan): KaburAjaDulu & OrangDalam masuk hand, tidak langsung jalan.
add("KaburAjaDulu", FATE, "Kabur Aja Dulu", false, "verified", "Sekali pakai, main sebelum lempar dadu: pindah ke lokasi mana pun, efek lokasi tetap berlaku. Gaji START saat kabur belum terverifikasi (adaptasi: tanpa gaji).")
add("OrangDalam", FATE, "Orang Dalam", false, "partial", "ADAPTASI: gunakan sebelum lempar dadu pada giliranmu, pilih nilai 1-6 untuk Musibah berikutnya. Sekali pakai; tidak dapat ditumpuk selama pilihan sebelumnya belum terpakai. Waktu pemakaian dan dek belum terverifikasi sebagai aturan asli.")
add("TukarNasib", DISASTER, "Tukar Nasib", false, "partial", "Pemain dengan uang terbanyak dan paling sedikit bertukar SELURUH uang, bukan aset. Dek ditetapkan sebagai adaptasi; klausul seri belum terverifikasi (adaptasi: kursi terkecil diutamakan).")
add("Sengketa", FATE, "Sengketa", false, "partial", "Ambil tanah lawan beserta bangunannya (adaptasi: tanah termahal milik lawan; dek ditetapkan sebagai adaptasi). Teks lengkap belum terbaca.")
local CardData = {}
function CardData.get(id: string): Card
	return D[id]
end
function CardData.all(): {[string]: Card}
	return D
end
return table.freeze(CardData)
