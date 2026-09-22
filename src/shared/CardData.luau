--!strict
-- CardData.luau
-- Katalog Kartu Takdir (Biru) dan Kartu Musibah (Merah)

export type CardCategory = "Takdir" | "Musibah"

export type CardData = {
    id: string,
    title: string,
    category: CardCategory,
    description: string,
    requiresDice: boolean,
}

local CardData: { [string]: CardData } = {
    -- KARTU MUSIBAH
    ["kpk"] = {
        id = "kpk",
        title = "Penggeledahan KPK",
        category = "Musibah",
        description = "Lempar 1 Dadu: 5-6 bayar Rp300.000 ke Negara, 3-4 sewa dinonaktifkan 1 putaran, 1-2 masuk LAPAS & bayar Rp500.000.",
        requiresDice = true,
    },
    ["banjir_bekasi"] = {
        id = "banjir_bekasi",
        title = "Banjir Bandang",
        category = "Musibah",
        description = "Pion dipindahkan ke Bekasi dan melewatkan 1 giliran.",
        requiresDice = false,
    },
    ["pajak_kaget"] = {
        id = "pajak_kaget",
        title = "Pajak Kaget",
        category = "Musibah",
        description = "Bayar Rp500.000 ke Negara untuk setiap rumah subsidi dan Rp1.000.000 untuk rumah OKB yang dimiliki.",
        requiresDice = false,
    },

    -- KARTU TAKDIR
    ["tambang_ilegal"] = {
        id = "tambang_ilegal",
        title = "Tambang Ilegal",
        category = "Takdir",
        description = "Lempar 1 Dadu: Genap (2,4,6) pilih 1 tanah lawan disita Negara. Ganjil (1,3,5) tanah termahal sendiri diubah jadi Jalan Tol permanen.",
        requiresDice = true,
    },
    ["bansos"] = {
        id = "bansos",
        title = "Pencairan Bansos",
        category = "Takdir",
        description = "Terima bantuan tunai Rp1.000.000 dari Negara.",
        requiresDice = false,
    },
    ["jalan_tol"] = {
        id = "jalan_tol",
        title = "Proyek Strategis Tol",
        category = "Takdir",
        description = "Bangun Jalan Tol gratis pada salah satu tanah milik Anda.",
        requiresDice = false,
    }
}

return CardData
