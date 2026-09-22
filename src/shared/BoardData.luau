--!strict
-- BoardData.luau
-- Katalog data petak dan properti resmi WNI Simulator

export type PropertyLevel = "Empty" | "Subsidi1" | "Subsidi2" | "OKB"
export type TileType = "START" | "Property" | "LAPAS" | "Pajak" | "Pengadilan" | "Pungli" | "Takdir" | "Musibah" | "Bekasi"

export type TileData = {
    id: number,
    name: string,
    tileType: TileType,
    region: string?, -- "Sumatera", "Kalimantan", "Sulawesi", "Papua", "Jawa", "Khusus"
    price: number?,
    rent: {
        Empty: number,
        Subsidi1: number,
        Subsidi2: number,
        OKB: number,
    }?,
    costSubsidi: number?,
    costOKB: number?,
}

local BoardData: { [number]: TileData } = {
    [1] = {
        id = 1,
        name = "START",
        tileType = "START",
        region = "Khusus",
    },
    -- Wilayah Sumatera
    [2] = {
        id = 2,
        name = "Padang",
        tileType = "Property",
        region = "Sumatera",
        price = 1500000,
        rent = {
            Empty = 400000,
            Subsidi1 = 700000,
            Subsidi2 = 1200000,
            OKB = 2000000,
        },
        costSubsidi = 350000,
        costOKB = 500000,
    },
    [3] = {
        id = 3,
        name = "Takdir Sumatera",
        tileType = "Takdir",
        region = "Sumatera",
    },
    [4] = {
        id = 4,
        name = "Medan",
        tileType = "Property",
        region = "Sumatera",
        price = 2000000,
        rent = {
            Empty = 550000,
            Subsidi1 = 1000000,
            Subsidi2 = 1800000,
            OKB = 2800000,
        },
        costSubsidi = 400000,
        costOKB = 600000,
    },
    -- Sudut 1: LAPAS
    [5] = {
        id = 5,
        name = "LAPAS",
        tileType = "LAPAS",
        region = "Khusus",
    },
    -- Wilayah Kalimantan
    [6] = {
        id = 6,
        name = "Pontianak",
        tileType = "Property",
        region = "Kalimantan",
        price = 2200000,
        rent = {
            Empty = 600000,
            Subsidi1 = 1100000,
            Subsidi2 = 2000000,
            OKB = 3000000,
        },
        costSubsidi = 450000,
        costOKB = 700000,
    },
    [7] = {
        id = 7,
        name = "Musibah Kalimantan",
        tileType = "Musibah",
        region = "Kalimantan",
    },
    [8] = {
        id = 8,
        name = "Balikpapan",
        tileType = "Property",
        region = "Kalimantan",
        price = 2800000,
        rent = {
            Empty = 750000,
            Subsidi1 = 1500000,
            Subsidi2 = 2600000,
            OKB = 3800000,
        },
        costSubsidi = 500000,
        costOKB = 800000,
    },
    -- Sudut 2: Pajak Tahunan
    [9] = {
        id = 9,
        name = "Pajak Tahunan",
        tileType = "Pajak",
        region = "Khusus",
    },
    -- Wilayah Sulawesi
    [10] = {
        id = 10,
        name = "Palu",
        tileType = "Property",
        region = "Sulawesi",
        price = 2500000,
        rent = {
            Empty = 700000,
            Subsidi1 = 1400000,
            Subsidi2 = 2500000,
            OKB = 3600000,
        },
        costSubsidi = 500000,
        costOKB = 800000,
    },
    [11] = {
        id = 11,
        name = "Makassar",
        tileType = "Property",
        region = "Sulawesi",
        price = 3000000,
        rent = {
            Empty = 850000,
            Subsidi1 = 1700000,
            Subsidi2 = 3000000,
            OKB = 4200000,
        },
        costSubsidi = 600000,
        costOKB = 900000,
    },
    -- Sudut 3: Pengadilan
    [12] = {
        id = 12,
        name = "Pengadilan",
        tileType = "Pengadilan",
        region = "Khusus",
    },
    -- Wilayah Papua
    [13] = {
        id = 13,
        name = "Jayapura",
        tileType = "Property",
        region = "Papua",
        price = 3200000,
        rent = {
            Empty = 900000,
            Subsidi1 = 1900000,
            Subsidi2 = 3200000,
            OKB = 4500000,
        },
        costSubsidi = 650000,
        costOKB = 950000,
    },
    [14] = {
        id = 14,
        name = "Takdir Papua",
        tileType = "Takdir",
        region = "Papua",
    },
    -- Sudut 4: Parkiran Pungli
    [15] = {
        id = 15,
        name = "Parkiran Pungli",
        tileType = "Pungli",
        region = "Khusus",
    },
    -- Wilayah Jawa
    [16] = {
        id = 16,
        name = "Surabaya",
        tileType = "Property",
        region = "Jawa",
        price = 4000000,
        rent = {
            Empty = 1200000,
            Subsidi1 = 2500000,
            Subsidi2 = 4000000,
            OKB = 5500000,
        },
        costSubsidi = 750000,
        costOKB = 1200000,
    },
    [17] = {
        id = 17,
        name = "Musibah Jawa",
        tileType = "Musibah",
        region = "Jawa",
    },
    [18] = {
        id = 18,
        name = "Jakarta",
        tileType = "Property",
        region = "Jawa",
        price = 4000000,
        rent = {
            Empty = 1200000,
            Subsidi1 = 2500000,
            Subsidi2 = 4000000,
            OKB = 5500000,
        },
        costSubsidi = 800000,
        costOKB = 1200000,
    },
    -- Area Khusus Terpisah
    [99] = {
        id = 99,
        name = "Bekasi (Area Banjir)",
        tileType = "Bekasi",
        region = "Khusus",
    }
}

return BoardData
