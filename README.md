# WNI Simulator — Acuan Pengembangan Godot

Dokumentasi analisis papan dan video referensi untuk pengembangan adaptasi digital di Godot.

**Status: tahap analisis dan spesifikasi. Repositori ini belum berisi game Godot yang dapat dimainkan.** Data yang belum terbaca atau aturan yang belum terverifikasi ditandai secara eksplisit.

## Referensi

- [Video tutorial](https://www.youtube.com/watch?v=OEyiAVH1OaU)
- [Video pendek](https://www.youtube.com/shorts/IEihkCUZTwI)
- [Referensi Instagram 1](https://www.instagram.com/p/DdVhylZgdFx/)
- [Referensi Instagram 2](https://www.instagram.com/p/DdLv_dRvo1-/)
- Foto papan yang diberikan pengguna.
- Unggahan video unboxing berdurasi sekitar 3 menit yang dianalisis melalui frame dan teks yang tampil.
- Unggahan gameplay “Monopoli versi Indonesia (WNI SIMULATOR) Part 1”.

Timestamp di bawah mengacu pada unggahan unboxing, bukan jaminan timestamp yang sama pada seluruh tautan. Dokumen ini merangkum analisis percakapan; bukan salinan buku aturan resmi. Video, gambar, dan aset visual asli tidak disertakan.

## 1. Bentuk permainan dan papan

Permainan papan ekonomi berbasis giliran dengan pergerakan pion, pembelian properti, pembangunan, sewa, kartu Takdir dan Musibah, serta pembayaran kepada Negara.

Foto memperlihatkan lintasan berbentuk segi lima di atas papan persegi panjang. Kelompok wilayahnya mencakup Sumatera, Kalimantan, Sulawesi, Papua, dan Jawa. Tutorial menyebut 25 properti; angka ini bukan jumlah seluruh petak.

Urutan kelompok dari START yang dicatat dalam analisis:
START → Sumatera → LAPAS → Kalimantan → Pajak Tahunan → Sulawesi → Pengadilan → Papua → Parkiran Pungli → Jawa → START.

Urutan lengkap setiap petak belum dikunci. Bekasi terlihat sebagai area terpisah dari lintasan utama, tetapi mekanismenya belum terverifikasi.

Komponen yang terlihat:
- Papan, uang permainan, sertifikat tanah, dan buku aturan.
- Dua dadu hijau.
- Pion karakter dengan dudukan.
- Kartu Takdir biru dan Musibah merah.
- Penanda bangunan dan jalan tol.

Penampilan karakter belum menjadi bukti bahwa setiap karakter memiliki kemampuan khusus.

## 2. Harga properti dan sewa

Semua nominal berikut adalah rupiah dalam permainan, bukan harga produk board game.

| Data | Padang (~02:09) | Palu (~02:13) | Jakarta (~02:22–02:23) |
| --- | ---: | ---: | ---: |
| Wilayah | Sumatera | Sulawesi | Jawa |
| Harga tanah | 1.500.000* | 2.500.000 | 4.000.000 |
| Sewa kosong | 400.000 | 700.000 | 1.200.000 |
| Sewa Subsidi 1 | 700.000 | 1.400.000 | 2.500.000 |
| Sewa Subsidi 2 | 1.200.000 | 2.500.000 | 4.000.000 |
| Sewa Rumah OKB | 2.000.000 | 3.600.000 | 5.500.000 |
| Biaya bangunan subsidi | 350.000 | 500.000 | Belum terbaca |
| Biaya bangunan OKB | 500.000 | 800.000 | 1.200.000 |

*Angka 1,5 pada harga Padang terlihat; kelanjutannya tertutup jari. Pembacaan 1,5 juta masih sementara. Beberapa bagian label nominal Padang juga tertutup sebagian.*

**Koreksi:** pembacaan lama harga Jakarta Rp6 juta dibatalkan. Sertifikat dalam video memperlihatkan Rp4 juta.

Biaya bangunan di tabel adalah nominal yang tertulis pada sertifikat. Mekanisme pembayaran ketika meningkatkan dua subsidi menjadi OKB harus diverifikasi dari aturan pembangunan. Angka tersebut tidak otomatis merupakan total biaya dari tanah kosong sampai OKB.

Dari analisis video gameplay sebelumnya, Surabaya tercatat memiliki harga tanah Rp4 juta dan sewa Rp1,2 juta / Rp2,5 juta / Rp4 juta / Rp5,5 juta. Biaya subsidi tercatat Rp750 ribu; pembacaan biaya OKB Rp1,2 juta lebih kurang jelas. Data Surabaya tidak boleh dipakai untuk mengisi otomatis biaya subsidi Jakarta.

### Implikasi ekonomi

Dengan gaji START Rp1 juta:
- Sewa Jakarta kosong setara 1,2 kali gaji.
- Sewa Jakarta OKB setara 5,5 kali gaji.
- Sewa Palu OKB setara 3,6 kali gaji.

Sewa kosong Palu adalah 28% harga tanah, sedangkan Jakarta 30%. Rasio tersebut menunjukkan bahwa tarif perlu disimpan per properti, bukan diturunkan dari satu persentase tetap.

Rasio sewa terhadap harga tanah bukan keuntungan bersih: belum memasukkan biaya pembangunan, peluang pendaratan, pajak, dan efek kartu.

## 3. Musibah: Penggeledahan KPK

Terlihat sekitar 01:58. Kartu meminta satu dadu.

| Dadu | Efek |
| --- | --- |
| 5–6 | Tidak terbukti bersalah; bayar Rp300.000 kepada Negara sebagai biaya administrasi. |
| 3–4 | Sewa seluruh Surat Tanah pemain tidak berlaku sampai giliran pemain itu tiba kembali. |
| 1–2 | Pion masuk LAPAS dan membayar Rp500.000 kepada Negara. |

Demonstrasi memperlihatkan hasil 4.

Konsekuensi implementasi:
- Penonaktifan sewa tidak memindahkan kepemilikan tanah.
- Efek berakhir ketika giliran berikutnya milik pemain terdampak datang, bukan setelah sejumlah detik.
- Jangan mengganti efek ini dengan pengalihan sewa ke Negara.
- Denda kartu Rp500.000 tidak otomatis ditambah denda petak Pengadilan.
- Perpindahan paksa ke LAPAS harus dibedakan dari pergerakan biasa.
- Urutan aksi ketika pembayaran menyebabkan kebangkrutan perlu mengikuti aturan yang terverifikasi.

## 4. Takdir: Tambang Ilegal

Terlihat sekitar 02:27–02:38. Kartu memiliki ikon jam dan meminta satu dadu.

| Kondisi / dadu | Pembacaan efek |
| --- | --- |
| Belum ada pemain memiliki Surat Tanah | Teks tampak meminta mengabaikan efek dan membuka kartu Takdir lagi; bagian kecil ini perlu konfirmasi lebih tajam. |
| 2, 4, 6 | Pilih satu Surat Tanah milik pemain lain, lalu kembalikan kepada Negara. |
| 1, 3, 5 | Surat Tanah paling mahal milik sendiri diubah menjadi jalan tol secara permanen. |

Frame bergerak dan subtitle menutup sebagian teks. Efek ganjil didukung oleh bagian kartu yang terlihat serta subtitle tentang penyitaan, konversi jalan tol, dan sifat permanen.

Konsekuensi:
- Hasil genap tidak memberi tanah lawan kepada pemain penarik kartu.
- Hasil ganjil mengubah fungsi petak, bukan sekadar pemilik.
- Penanda tol harus mengikuti perubahan logika petak.
- Jangan menambahkan kompensasi atau aturan bangunan yang tidak terbaca.

Belum terverifikasi:
- Pemain penarik kartu tidak mempunyai tanah.
- Tidak ada lawan yang mempunyai tanah.
- Ada beberapa tanah dengan harga tertinggi yang sama.
- Apakah “paling mahal” memakai harga tanah saja atau termasuk bangunan.
- Penanganan bangunan pada tanah yang dikembalikan atau dikonversi.

Hubungan ikon jam dengan penggabungan kartu setelah semua pemain menyelesaikan dua putaran berasal dari catatan tutorial sebelumnya, bukan penjelasan lengkap pada video unboxing.

## 5. Aturan lain dari analisis referensi sebelumnya

Bagian ini merupakan catatan lintas referensi. Detail pelaksanaan yang belum jelas tetap harus dikonfirmasi sebelum aturan dianggap final.

| Sistem | Catatan |
| --- | --- |
| START | Gaji Rp1 juta. |
| Pembangunan | Tutorial mengaitkan kesempatan membangun dengan menerima gaji setelah melewati START, sebelum efek tujuan; urutan detail perlu dikonfirmasi. |
| Tingkat bangunan | Kosong → Subsidi 1 → Subsidi 2 → Rumah OKB. Tutorial menyebut peningkatan OKB pada putaran berikutnya. |
| Pajak Tahunan | Tercatat Rp500 ribu per properti. |
| LAPAS | Mendarat biasa berbeda dari dikirim sebagai tahanan. Catatan tutorial menyebut sewa properti tahanan dibayar kepada Negara. |
| Keluar LAPAS | Catatan tutorial menyebut dadu kembar, pembayaran Rp1,5 juta, atau keluar otomatis pada giliran ketiga; urutan waktunya belum jelas. |
| Pengadilan | Satu dadu: 5–6 kompensasi Rp1 juta; 3–4 LAPAS dan denda Rp1,5 juta; 1–2 LAPAS dan pembayaran 50% uang kepada Negara. |
| Pembulatan Pengadilan | Tulisan “bulatkan ke atas” terlihat sekitar 01:22; satuan pembulatan belum diketahui. |
| Tol | Tercatat pembayaran Rp500 ribu dan perpindahan; perjalanan tol tidak memberi gaji START. Tujuan dan pemicunya perlu dirinci. |
| Tilang | Tercatat Rp500 ribu. |
| Parkiran Pungli | Tercatat Rp1 juta dengan pengecualian terkait Bandung; syarat pengecualian perlu dicocokkan. |
| Dadu kembar | Catatan tutorial: bukan giliran tambahan, tetapi Takdir setelah penyelesaian lokasi. |
| Likuidasi | Catatan tutorial: menjual pada 50% harga awal; aset menjadi milik Negara. Rincian bangunan dan pembelian kembali perlu dicocokkan. |
| Akhir permainan | Tutorial menggambarkan seluruh pemain bangkrut dan Negara sebagai pemenang; aturan peringkat dan penghentian final perlu dirinci. |
| Modal awal | Belum terverifikasi. |
| Musibah umum | Catatan tutorial: 5–6 ringan, 3–4 sedang, 1–2 berat. Terdapat contoh narasi yang tidak konsisten, sehingga teks kartu perlu diprioritaskan. |

Kartu tambahan dari video gameplay:
- **Orang Dalam:** sekali pakai, memilih tingkat efek Musibah tanpa lempar dadu; bukan otomatis membatalkan semua efek.
- **Sengketa:** penjelasan gameplay menunjukkan pengambilan tanah lawan beserta bangunan, tetapi teks lengkap belum terbaca.
- **Tukar Nasib:** penjelasan menunjukkan pertukaran uang pemain terkaya dan termiskin; bukan seluruh aset. Aturan seri belum jelas.

## 6. Rancangan sistem Godot

Bagian ini merupakan usulan implementasi, bukan aturan resmi tambahan.

### Pemisahan data dan keadaan

| Bagian | Isi |
| --- | --- |
| PropertyDefinition | ID, nama, wilayah, harga, empat tarif sewa, biaya bangunan, status verifikasi, sumber. |
| PropertyState | Pemilik dan tingkat bangunan saat ini. |
| TileState | Fungsi petak saat ini, termasuk perubahan permanen menjadi tol. |
| PlayerState | Uang, posisi, status tahanan, kartu yang disimpan. |
| TemporaryEffect | Jenis efek, pemain terdampak, pemicu berakhirnya efek. |
| TurnState | Pemain aktif dan tahap penyelesaian giliran. |
| ActionLog | Riwayat kartu, dadu, pembayaran, perpindahan, dan perubahan aset. |

Data sertifikat dapat menggunakan custom Resource. Keadaan sesi disimpan terpisah agar perubahan pemilik atau fungsi petak tidak merusak data referensi.

Simpan uang sebagai bilangan bulat rupiah. Data yang belum diketahui harus tetap kosong atau ditandai unknown, bukan diam-diam menjadi nol.

### Penyelesaian petak

1. Baca fungsi petak yang aktif.
2. Jika sudah menjadi tol, jalankan aturan tol.
3. Jika masih properti, periksa pemilik dan tingkat bangunan.
4. Periksa efek yang mengubah atau menonaktifkan sewa.
5. Tentukan penerima dan jumlah pembayaran.
6. Selesaikan pembayaran atau proses kekurangan dana.
7. Catat hasil dan perbarui tampilan.

Prioritas antara efek yang bertumpuk, misalnya LAPAS dan sewa nonaktif, belum ditetapkan oleh bukti yang tersedia.

### Efek dan pergantian giliran

Penonaktifan sewa KPK berakhir pada awal giliran berikutnya milik pemain terdampak. Gunakan identitas pemain dan pemicu giliran, bukan durasi detik atau hitungan ronde yang ambigu.

Kartu menghasilkan aksi terstruktur: pembayaran, perpindahan paksa, perubahan status, pengembalian aset, atau konversi petak. Animasi mengikuti aksi tersebut sehingga tidak menggandakan hasil saat tombol ditekan berulang.

Pergerakan biasa, perpindahan lewat tol, dan pengiriman ke LAPAS harus mempunyai aturan melewati START yang eksplisit.

### Antarmuka

- Panel uang dan status pemain selalu terlihat.
- Detail sertifikat memperlihatkan harga, sewa, dan biaya pembangunan.
- Efek KPK menampilkan “Sewa nonaktif sampai giliran berikutnya”.
- Konversi tol mengganti penanda dan informasi petak.
- Pembayaran memperlihatkan nominal, penerima, alasan, dan sisa uang.
- Log giliran menjelaskan mengapa efek terjadi.
- Pemilihan tanah lawan hanya menampilkan target yang memenuhi aturan.

Contoh log:
> Penggeledahan KPK: hasil dadu 4. Sewa seluruh properti pemain tidak berlaku sampai giliran berikutnya.

## 7. Tahap implementasi yang disarankan

1. Lengkapi urutan petak, modal awal, dan data sertifikat.
2. Buat proyek Godot dengan papan, pion, serta giliran lokal.
3. Implementasikan dadu, pergerakan, START, pembelian, dan pembayaran.
4. Tambahkan bangunan, sewa, serta penanganan kekurangan uang.
5. Tambahkan LAPAS, Pengadilan, pajak, tol, dan pungli.
6. Implementasikan kartu sebagai aksi dan efek terstruktur.
7. Tambahkan perubahan permanen petak serta efek sementara.
8. Verifikasi alur permainan dan akhir sesi.
9. Tingkatkan visual, animasi, audio, serta kemudahan penggunaan.

## 8. Skenario verifikasi utama

- Jakarta memakai harga Rp4 juta.
- Sewa mengikuti tingkat bangunan yang tepat.
- KPK hasil 3–4 menghentikan sewa sampai giliran pemilik tiba kembali.
- KPK tidak mengubah kepemilikan tanah.
- KPK hasil 1–2 tidak menjalankan denda Pengadilan tambahan.
- Tambang Ilegal hasil genap mengembalikan tanah ke Negara.
- Tanah yang menjadi tol tidak lagi menjalankan sewa properti.
- Perpindahan paksa tidak tanpa sengaja memberi gaji START.
- Menekan tombol saat animasi tidak menggandakan pembayaran.
- Kasus harga tanah seri, tanpa aset, dan efek bertumpuk ditangani setelah aturan dipastikan.

## 9. Data yang masih dibutuhkan

- Foto/scan seluruh 25 sertifikat tanah.
- Urutan lengkap petak dan teks petak khusus.
- Buku aturan lengkap.
- Modal awal dan rincian distribusi uang.
- Biaya subsidi Jakarta.
- Konfirmasi harga Padang yang tertutup jari.
- Aturan peningkatan bangunan dan likuidasi.
- Seluruh teks kartu, aturan ikon jam, dan kasus seri.
- Mekanisme Bekasi.
- Urutan prioritas efek dan kondisi akhir permainan.

Tidak ada harga atau aturan yang belum diketahui yang dianggap final hanya untuk melengkapi implementasi.
