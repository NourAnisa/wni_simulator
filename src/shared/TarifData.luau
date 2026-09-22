--!strict
-- Tarif tanah per petak WNI Simulator. Sumber: README bagian 2, 15, 25, 27.
-- verified=true = terbaca dari sertifikat/papan. verified=false = PERKIRAAN, bukan aturan asli.
export type Tarif = {price: number, rents: {number}, buildSubsidi: number, buildOKB: number, verified: boolean, source: string}
local T: {[number]: Tarif} = {}
local function add(i: number, price: number, r: {number}, bs: number, bo: number, v: boolean, src: string)
	T[i] = {price = price, rents = r, buildSubsidi = bs, buildOKB = bo, verified = v, source = src}
end
-- SUMATERA (petak 2-8): profil sertifikat Padang; harga 1,5jt sementara (tertutup jari).
add(2, 1500000, {400000, 700000, 1200000, 2000000}, 350000, 500000, true, "Sertifikat Padang; harga sementara")
add(3, 1500000, {400000, 700000, 1200000, 2000000}, 350000, 500000, false, "Harga papan README 27; tarif profil Padang")
add(5, 1500000, {400000, 700000, 1200000, 2000000}, 350000, 500000, false, "Perkiraan profil Sumatera")
add(6, 1500000, {400000, 700000, 1200000, 2000000}, 350000, 500000, false, "Perkiraan profil Sumatera")
add(8, 1500000, {400000, 700000, 1200000, 2000000}, 350000, 500000, false, "Perkiraan profil Sumatera")
-- KALIMANTAN (petak 10-16): harga 2jt terbaca; tarif profil IKN sementara.
add(10, 2000000, {500000, 1000000, 1500000, 3000000}, 450000, 650000, false, "Harga papan README 27; tarif profil IKN sementara")
add(11, 2000000, {500000, 1000000, 1500000, 3000000}, 450000, 650000, false, "Harga papan README 25; tarif perkiraan")
add(13, 2000000, {500000, 1000000, 1500000, 3000000}, 450000, 650000, false, "Harga papan README 25; tarif perkiraan")
add(14, 2000000, {500000, 1000000, 1500000, 3000000}, 450000, 650000, false, "Sertifikat IKN buram, semua sementara README 25")
add(16, 2000000, {500000, 1000000, 1500000, 3000000}, 450000, 650000, false, "Perkiraan profil Kalimantan")
-- SULAWESI (petak 18-24): harga 2,5jt terbaca; tarif profil sertifikat Palu.
add(18, 2500000, {700000, 1400000, 2500000, 3600000}, 500000, 800000, true, "Sertifikat + papan cocok README 2 dan 15")
add(19, 2500000, {700000, 1400000, 2500000, 3600000}, 500000, 800000, false, "Harga papan README 15; tarif profil Palu")
add(21, 2500000, {700000, 1400000, 2500000, 3600000}, 500000, 800000, false, "Harga papan README 15; tarif perkiraan")
add(22, 2500000, {700000, 1400000, 2500000, 3600000}, 500000, 800000, false, "Perkiraan band Sulawesi")
add(24, 2500000, {700000, 1400000, 2500000, 3600000}, 500000, 800000, false, "Perkiraan band Sulawesi")
-- PAPUA (petak 26-32): belum ada bukti tarif; formula band 3jt, ditandai perkiraan.
add(26, 3000000, {850000, 1650000, 3000000, 4200000}, 650000, 950000, false, "PERKIRAAN formula, belum ada bukti Papua")
add(27, 3000000, {850000, 1650000, 3000000, 4200000}, 650000, 950000, false, "PERKIRAAN formula")
add(29, 3000000, {850000, 1650000, 3000000, 4200000}, 650000, 950000, false, "PERKIRAAN formula")
add(30, 3000000, {850000, 1650000, 3000000, 4200000}, 650000, 950000, false, "PERKIRAAN formula")
add(32, 3000000, {850000, 1650000, 3000000, 4200000}, 650000, 950000, false, "PERKIRAAN formula")
-- JAWA (petak 34-40): harga 4jt terbaca; tarif profil Jakarta/Surabaya.
add(34, 4000000, {1200000, 2500000, 4000000, 5500000}, 900000, 1200000, true, "Sertifikat Jakarta README 2; subsidi perkiraan")
add(35, 4000000, {1200000, 2500000, 4000000, 5500000}, 750000, 1200000, false, "Harga papan README 25; tarif profil Surabaya")
add(37, 4000000, {1200000, 2500000, 4000000, 5500000}, 750000, 1200000, false, "Harga papan README 25; tarif perkiraan")
add(38, 4000000, {1200000, 2500000, 4000000, 5500000}, 750000, 1200000, false, "Harga papan README 25; tarif perkiraan")
add(40, 4000000, {1200000, 2500000, 4000000, 5500000}, 750000, 1200000, true, "Analisis gameplay README 2; OKB kurang jelas")
local Tarif = {}
function Tarif.get(index: number): Tarif
	local t = T[index]
	if t then return t end
	return {price = 2000000, rents = {560000, 1100000, 2000000, 2800000}, buildSubsidi = 450000, buildOKB = 650000, verified = false, source = "Fallback"}
end
function Tarif.all(): {[number]: Tarif}
	return T
end
return table.freeze(Tarif)
