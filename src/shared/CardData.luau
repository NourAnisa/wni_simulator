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
add("Begal", DISASTER, "Korban Begal", true, "partial", "Lempar 1 dadu. 5/6: motor hilang + skip giliran berikutnya + bayar 400rb ke Negara. 1/2: pindah ke Lampung (seperti Bekasi, adaptasi) + skip giliran. 3/4: adaptasi digital, bayar 200rb ke Negara.")
add("PengalihanIsu", FATE, "Pengalihan Isu", false, "verified", "Langsung masuk LAPAS (Nusakambangan). Jenis: Takdir – biru.")
add("Buzzer", FATE, "Buzzer", true, "partial", "Genap (2/4/6): +800rb dari Negara. Ganjil (1/3/5): adaptasi bayar 400rb (bagian ganjil tertutup jari di video).")
-- Kartu tangan (simpanan): KaburAjaDulu & OrangDalam masuk hand, tidak langsung jalan.
add("KaburAjaDulu", FATE, "Kabur Aja Dulu", false, "verified", "Sekali pakai, main sebelum lempar dadu: pindah ke lokasi mana pun, efek lokasi tetap berlaku. Gaji START saat kabur belum terverifikasi (adaptasi: tanpa gaji).")
add("OrangDalam", FATE, "Orang Dalam", false, "partial", "ADAPTASI: gunakan sebelum lempar dadu pada giliranmu, pilih nilai 1-6 untuk Musibah berikutnya. Sekali pakai; tidak dapat ditumpuk selama pilihan sebelumnya belum terpakai. Waktu pemakaian dan dek belum terverifikasi sebagai aturan asli.")
add("DoaOrangTua", FATE, "Doa Orang Tua", false, "verified", "Sekali pakai. Saat menjalankan efek Kartu Musibah, kamu BOLEH memilih tier hukuman (high=5-6, mid=3-4, low=1-2) tanpa melempar dadu. Gunakan sebelum menarik Musibah di giliranmu.")
add("TukarNasib", FATE, "Tukar Nasib", false, "verified", "Pemain dengan uang terbanyak dan paling sedikit bertukar SELURUH uang. Jenis: Takdir – biru.")
add("Sengketa", FATE, "Sengketa", false, "partial", "Ambil tanah lawan beserta bangunannya (adaptasi: tanah termahal milik lawan; dek ditetapkan sebagai adaptasi). Teks lengkap belum terbaca.")
-- KARTU TAMBAHAN BARU
add("BPJSNunggak", DISASTER, "BPJS Perusahaan Menunggak", false, "verified", "BPJS Perusahaanmu menunggak. Bayar denda Rp1.000.000 atau masuk penjara jika uang tidak mencukupi.")
add("JalurMandiri", DISASTER, "Jalur Mandiri PTN", false, "verified", "Anakmu tidak lulus SNBP! Bayar uang pangkal Rp20.000.000 untuk masuk jalur mandiri.")
add("TahananRumahKPK", DISASTER, "Tahanan Rumah KPK", false, "verified", "Surat penetapan tahanan rumah diterbitkan KPK. Sewa tanah nonaktif dan lewati 1 giliran.")
add("PungliAKAMSI", DISASTER, "Pungli AKAMSI", false, "verified", "Semua usaha didatangi AKAMSI. Seluruh pemain membayar uang keamanan Rp1.000.000.")
add("DitabrakEmakEmak", FATE, "Santunan Ditabrak Emak-Emak", false, "verified", "Ditabrak ibu-ibu pasang sen kanan tapi belok kiri. Menerima dana santunan Rp50.000.")
add("WhooshBandung", FATE, "Tiket Kereta Cepat Whoosh", false, "verified", "Mendapatkan tiket Kereta Cepat Whoosh! Langsung melesat ke Bandung (Petak 37).")
add("SeranganFajar", FATE, "Serangan Fajar", false, "verified", "Pemilu sudah dekat! Menerima uang serangan fajar Rp50.000 dari amplop caleg.")
add("TanahTerlantar", DISASTER, "Penertiban Tanah Terlantar", false, "verified", "Tanah milikmu yang belum dibangun (level 0) disita oleh Negara karena ditelantarkan.")
add("TenderKoperasi", FATE, "Tender Koperasi Merah Putih", false, "verified", "Selamat! Menang tender proyek Koperasi Merah Putih. Dana Rp1.000.000 dipotong pajak 11% (bersih Rp890.000).")
add("MagnetSultan", FATE, "Magnet Sultan", false, "verified", "Tarik lawan terdekat untuk mendarat tepat di tanah termahal milikmu!")
add("BegalProperti", FATE, "Begal Properti", false, "verified", "Rebut paksa satu petak tanah milik lawan yang belum ber-Landmark!")
local CardData = {}
function CardData.get(id: string): Card
	return D[id]
end
function CardData.all(): {[string]: Card}
	return D
end
return table.freeze(CardData)
