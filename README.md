# WNI Simulator — Acuan Pengembangan Godot

Dokumentasi analisis papan dan video referensi untuk pengembangan adaptasi digital di Godot.

**Status: tahap analisis dan spesifikasi. Repositori ini belum berisi game Godot yang dapat dimainkan.** Data yang belum terbaca atau aturan yang belum terverifikasi ditandai secara eksplisit.

## Referensi

- Unggahan “WNI cobain WNI Simulator” (76,97 detik, 720 × 1280): `SaveInta.com_AQMkEuO1zA2rB2TPUfk1RzyhfV9q1_XLrNLZFHBsx9fH-BwDdW7SnckO4sBdjeAEKaLKl2A1w-HDGlWNjQ6pQOvZXjo6OBThw1Ga1j8(1).mp4`. Identik secara SHA-256 dengan unggahan bernama sama tanpa `(1)`; dihitung sebagai satu sumber, bukan dua bukti independen. Analisis melalui frame, teks kartu, dan subtitle, bukan transkripsi audio lengkap.

- Unggahan “WNI cobain WNI Simulator pt.2”: `SaveInta.com_AQP6AVbEItUK3Jjxqq1RCNe7Ja1rhaI4FNdt8xupr9hbO-Pqy0NOYNM3wffIv_VbHwFlspTuF1FMFYWLE-AXPusijvoypDBOHVJSmyA.mp4` (83,33 detik, 720 × 1280). Analisis berdasarkan frame, tulisan kartu, dan subtitle.

- [Video tutorial](https://www.youtube.com/watch?v=OEyiAVH1OaU)
- [Video pendek](https://www.youtube.com/shorts/IEihkCUZTwI)
- [Referensi Instagram 1](https://www.instagram.com/p/DdVhylZgdFx/)
- [Referensi Instagram 2](https://www.instagram.com/p/DdLv_dRvo1-/)
- Foto papan yang diberikan pengguna.
- Unggahan video unboxing berdurasi sekitar 3 menit yang dianalisis melalui frame dan teks yang tampil.
- Unggahan gameplay “Monopoli versi Indonesia (WNI SIMULATOR) Part 1”.
- Unggahan gameplay tambahan: `SaveInta.com_AQMHJKqzfz1-5No7M4e2kJLoCoMahKN05RkYVP_ek8p3hWgAqOY0THqoIBQ6tuUW5AstELNNgFm8F9qt5wJmq_mrpG7bksn8gmjgeN4.mp4` (84,52 detik, 720 × 1280). Dianalisis melalui frame, tulisan kartu, dan subtitle; bukan transkripsi audio lengkap.

Timestamp pada bagian 2–4 mengacu pada unggahan unboxing. Timestamp pada bagian 10–17 mengacu pada video gameplay tambahan berdurasi 84,52 detik. Timestamp pada bagian 19–27 mengacu pada video “WNI cobain WNI Simulator pt.2” berdurasi 83,33 detik. Timestamp bagian 28–35 mengacu pada video 76,97 detik tersebut. Timestamp tidak harus sama dengan versi pada tautan media sosial. Dokumen ini merangkum analisis percakapan; bukan salinan buku aturan resmi. Video, gambar, dan aset visual asli tidak disertakan.

## 1. Bentuk permainan dan papan

Permainan papan ekonomi berbasis giliran dengan pergerakan pion, pembelian properti, pembangunan, sewa, kartu Takdir dan Musibah, serta pembayaran kepada Negara.

Foto memperlihatkan lintasan berbentuk segi lima di atas papan persegi panjang. Kelompok wilayahnya mencakup Sumatera, Kalimantan, Sulawesi, Papua, dan Jawa. Tutorial menyebut 25 properti; angka ini bukan jumlah seluruh petak.

Urutan kelompok dari START yang dicatat dalam analisis:
START → Sumatera → LAPAS → Kalimantan → Pajak Tahunan → Sulawesi → Pengadilan → Papua → Parkiran Pungli → Jawa → START.

Urutan lengkap setiap petak belum dikunci. Bekasi terlihat sebagai area terpisah dari lintasan utama. Video terbaru menunjukkan Banjir Bandang mengirim pion ke Bekasi dan melewatkan satu giliran; cara kembali ke lintasan belum terverifikasi (bagian 31).

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
- **Tukar Nasib:** pemain dengan uang terbanyak dan paling sedikit bertukar seluruh uang, bukan aset. Teks klausul jumlah uang sama kini terbaca; cakupan dan urutan penyelesaiannya masih perlu verifikasi (bagian 32).

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
- Cara keluar/kembali dari Bekasi setelah efek kehilangan giliran; pemicu masuk melalui Banjir Bandang sudah diamati (bagian 31).
- Urutan prioritas efek dan kondisi akhir permainan.

Tidak ada harga atau aturan yang belum diketahui yang dianggap final hanya untuk melengkapi implementasi.

## 10. Indeks bukti video gameplay tambahan

Video ini merupakan montase beberapa kejadian. Pergantian adegan tidak membuktikan urutan giliran yang berkesinambungan.

| Waktu perkiraan | Kejadian | Hasil pengamatan |
| --- | --- | --- |
| 00:02–00:04 | WIBU | Kartu terlihat jelas; perpindahan ke Bandung atau kehilangan giliran dan pembayaran. |
| 00:10–00:17 | Kena PHK | Tiga cabang efek global; subtitle mendukung perpindahan seluruh pemain ke Pengadilan. |
| 00:23–00:30 | Baterai Sekarat | Tabel kondisi HP dan denda terbaca; demonstrasi menyebut baterai 11 dan pembayaran Rp1 juta. |
| 00:34–00:38 | Gajian | Pergerakan pion diikuti penerimaan gaji Rp1 juta. |
| 00:40–00:44 | Penggeledahan KPK | Nama kartu disebut, tetapi hasil dadu dan penyelesaiannya tidak lengkap. |
| 00:46–00:54 | Pembebasan Lahan | Teks kartu dan contoh perubahan tanah menjadi tol. |
| 00:55–00:59 | Kejadian begal | Subtitle menyebut pembayaran Rp400 ribu; teks kartu lengkap tidak terlihat. |
| 01:04–01:15 | Pengadilan | Aturan papan terbaca; uang Rp6,2 juta dihitung menjadi pembayaran Rp3,1 juta. |

Tingkat kepastian:
- **Terbaca:** tulisan kartu/papan cukup jelas pada frame.
- **Didukung demonstrasi:** subtitle dan aksi pemain mendukung suatu pembacaan.
- **Sementara:** bagian tertutup, kecil, atau belum lengkap.
- **Usulan adaptasi:** keputusan rancangan digital, bukan aturan asli.

## 11. Takdir: WIBU

Sumber: video tambahan sekitar 00:03. Kartu meminta satu dadu.

| Hasil dadu | Efek yang terbaca |
| --- | --- |
| 2, 4, 6 | Pindah ke lokasi Bandung. |
| 1, 3, 5 | Lewati satu giliran dan bayar Rp500.000 kepada Negara. |

Cerita tentang truk dan isekai adalah tema humor kartu. Efek tertulis tidak membuktikan adanya dunia isekai terpisah.

Belum diketahui:
- Apakah giliran yang dilewati adalah giliran berikutnya atau sisa giliran saat ini.
- Apakah perpindahan ke Bandung menjalankan efek properti tujuan.
- Apakah perpindahan ini memberikan gaji START.

Implikasi Godot: simpan status kehilangan giliran; bedakan perpindahan langsung dari berjalan dengan dadu. Setiap perpindahan perlu menetapkan tujuan, alasan, perilaku START, dan pemicu efek tujuan. Jangan mengisi aturan yang belum diketahui secara diam-diam.

## 12. Musibah: Kena PHK

Sumber: sekitar 00:11–00:12; tulisan kecil tetapi tiga cabang utama dapat dibaca. Instruksi memakai satu dadu.

| Hasil dadu | Pembacaan efek |
| --- | --- |
| 5–6 | Semua pemain tidak mendapatkan gaji ketika melewati START selama satu putaran. |
| 3–4 | Semua pemain tidak bisa membeli Surat Tanah/Rumah selama satu putaran. |
| 1–2 | Semua pemain pindah ke Pengadilan, lalu menjalankan efek lokasi. |

Cabang 1–2 diperkuat subtitle sekitar 00:15–00:17. Frasa humor “sampai tujuh turunan” bukan instruksi untuk menerapkan hukuman tujuh putaran.

Pemisahan mekanisme:
- Larangan menerima gaji tidak otomatis melarang menerima sewa.
- Larangan membeli tanah/rumah tidak otomatis menonaktifkan sewa aset yang sudah dimiliki.
- Semua pemain yang terkena perpindahan harus menjalankan penyelesaian Pengadilan sesuai aturan; urutan antarpemain belum diketahui.
- “Satu putaran” belum dipastikan berarti putaran lintasan atau satu rangkaian giliran. Jangan menyamakannya dengan batas efek KPK yang menyebut giliran pemilik kembali.

Implikasi Godot: dukung efek global, pembatasan gaji dan pembelian yang terpisah, serta antrean efek lokasi untuk beberapa pemain. Durasi dan aturan penumpukan PHK masih perlu verifikasi.

## 13. Takdir: Baterai Sekarat

Sumber: sekitar 00:25–00:26, kartu terbaca jelas. Pemain diminta memeriksa HP.

| Teks kondisi | Pembayaran kepada Negara |
| --- | ---: |
| Baterai 50% ke atas | Aman / Rp0 |
| Baterai di bawah 50% | Rp500.000 |
| Baterai di bawah 30% | Rp1.000.000 |
| Tidak membawa HP | Rp2.000.000 |

Demonstrasi menyebut baterai 11 dan pembayaran Rp1 juta. Ini mendukung penerapan satu kategori yang paling sesuai, bukan penjumlahan denda kategori di bawah 50% dan di bawah 30%.

Pembacaan operasional yang didukung demonstrasi:

| Kondisi | Pembayaran |
| --- | ---: |
| Tidak membawa HP | Rp2.000.000 |
| Membawa HP, baterai <30% | Rp1.000.000 |
| Baterai ≥30% dan <50% | Rp500.000 |
| Baterai ≥50% | Rp0 |

Batas 30% dan 50% mengikuti arti matematis teks kartu. Contoh: 11% membayar Rp1 juta, tepat 30% membayar Rp500 ribu, tepat 50% aman.

### Adaptasi digital

Ini adalah keputusan desain yang belum ditetapkan:
- Mode bergantian pada satu komputer dapat meminta pemain memasukkan persentase baterai HP masing-masing.
- Baterai perangkat otomatis hanya mewakili pemain jika perangkat itu memang perangkat pemain tersebut.
- “Tidak membawa HP” berbeda dari kegagalan membaca baterai perangkat.
- Baterai HP virtual adalah alternatif aturan adaptasi; jangan mengklaimnya sebagai mekanisme asli.

Kartu ini membuktikan bahwa Takdir biru tidak selalu memberi keuntungan.

## 14. Takdir: Pembebasan Lahan

Sumber: sekitar 00:46–00:47; kartu terbaca jelas dan memiliki ikon jam.

Aturan yang terlihat:
1. Jika tidak ada pemain yang memiliki Surat Tanah, abaikan efek kartu.
2. Pemain **boleh** memilih satu Surat Tanah milik pemain lain.
3. Tanah tersebut disita dan diubah menjadi lokasi tol secara permanen.
4. Tol baru berlaku seperti tol lainnya.
5. Kartu diletakkan pada lokasi yang dipilih sebagai penanda tol baru.

Kata “boleh” menunjukkan pilihan opsional. Antarmuka perlu mengizinkan pemain menggunakan efek atau melewatinya.

| Aspek | Pembebasan Lahan | Tambang Ilegal |
| --- | --- | --- |
| Dadu | Tidak tercantum pada kartu yang terlihat | Satu dadu |
| Target | Pilihan tanah milik pemain lain | Bergantung hasil dadu |
| Tanah lawan | Menjadi tol permanen | Hasil genap mengembalikan tanah kepada Negara |
| Tanah sendiri | Bukan target yang disebut | Hasil ganjil mengubah tanah sendiri termahal menjadi tol |
| Tidak ada kepemilikan tanah | Abaikan efek | Pembacaan awal tampak meminta kartu Takdir baru; belum sepenuhnya terverifikasi |

Mengembalikan properti kepada Negara berbeda dari mengubah fungsi petaknya menjadi tol.

Implikasi Godot:
- Tampilkan hanya target milik lawan yang memenuhi syarat.
- Sediakan pilihan melewati efek.
- Ganti fungsi dan tampilan petak secara permanen.
- Tol asli dan tol hasil konversi memakai sistem efek tol yang sama.
- Jangan menjalankan sewa properti lama setelah konversi.
- Jika tidak ada target milik lawan, jangan memaksakan pilihan tanah sendiri.

Belum diketahui: penanganan bangunan yang sudah berdiri, rincian sertifikat setelah penyitaan, dan kompensasi. Teks yang terbaca tidak memberi dasar untuk mengarang pembayaran ganti rugi.

## 15. Penguatan harga, gaji, dan Pengadilan

### Harga pada papan

Terlihat sekitar 01:04–01:05:

| Properti | Wilayah | Harga tanah pada papan | Sewa dan biaya bangunan |
| --- | --- | ---: | --- |
| Gorontalo | Sulawesi | Rp2.500.000 | Belum diketahui |
| Palu | Sulawesi | Rp2.500.000 | Lihat sertifikat pada bagian 2 |
| Manado | Sulawesi | Rp2.500.000 | Belum diketahui |

Harga Palu cocok dengan sertifikat dari video unboxing. Kesamaan harga tanah tidak membuktikan kesamaan sewa atau biaya bangunan.

### Pengadilan

Tulisan papan sekitar 01:04–01:05 menguatkan:
- Satu dadu saat mendarat.
- 5–6: menerima Rp1 juta.
- 3–4: masuk LAPAS dan denda Rp1,5 juta.
- 1–2: masuk LAPAS dan membayar 50% uang kepada Negara, dibulatkan ke atas.

Demonstrasi subtitle sekitar 01:10–01:15:

`Rp6.200.000 × 50% = Rp3.100.000`

Sisa uang menjadi Rp3,1 juta jika tidak ada transaksi lain. Dasar contoh perhitungan adalah uang tunai, bukan gabungan nilai properti dan bangunan.

Contoh ini tidak memverifikasi satuan pembulatan karena pembagian menghasilkan angka tepat.

### Gaji dan kejadian begal

- Sekitar 00:34–00:38: pergerakan pion disusul gajian Rp1 juta, menguatkan nominal START. Urutan pembangunan setelah gajian belum dijelaskan.
- Sekitar 00:55–00:59: subtitle menyebut korban begal membayar Rp400 ribu kepada Negara karena motor hilang dan cicilan belum lunas. Nama kartu, hasil dadu, dan seluruh cabang belum terbaca. Ini tidak membuktikan adanya inventaris motor atau sistem kredit terpisah.
- Penggeledahan KPK muncul sekitar 00:41, tetapi tidak menambah bukti tentang hasil dadu atau penyelesaian cabangnya.

## 16. Perluasan rancangan Godot dan pengalaman bermain

Usulan berikut berasal dari analisis mekanisme, bukan penambahan aturan resmi.

| Jenis efek | Contoh | Kebutuhan sistem |
| --- | --- | --- |
| Pembayaran tetap | WIBU, Baterai Sekarat | Nominal, penerima, alasan |
| Pembayaran persentase | Pengadilan | Uang saat efek diproses, persentase, aturan pembulatan |
| Kehilangan giliran | WIBU | Jumlah giliran yang dilewati dan waktu penerapan |
| Gaji dinonaktifkan | PHK | Pemeriksaan penerimaan gaji terpisah dari sewa |
| Pembelian dilarang | PHK | Pemeriksaan izin membeli tanah/bangunan |
| Perpindahan semua pemain | PHK | Antrean perpindahan dan efek tujuan |
| Konversi permanen petak | Pembebasan Lahan | Keadaan fungsi petak yang tersimpan |
| Kondisi dunia nyata | Baterai Sekarat | Input pemain atau sumber kondisi perangkat |
| Pilihan opsional | Pembebasan Lahan | Target sah dan tombol lewati |

### Data tambahan

- PlayerState: status kehilangan giliran, kemajuan putaran, dan efek aktif.
- GlobalEffect: jenis pembatasan, pemain terdampak, asal kartu, dan syarat berakhir.
- MovementAction: tujuan, alasan, perlakuan START, serta apakah efek tujuan dipicu.
- CardResolution: pemain pemicu, target, hasil dadu/input, dan antrean aksi.
- Setiap aturan/data: sumber, timestamp, status verifikasi, serta pertanyaan yang belum terjawab.

Nilai yang belum terverifikasi harus ditandai, bukan diasumsikan berlaku pada seluruh kartu. Jangan memakai satu flag “terkena hukuman” untuk sewa nonaktif, gaji nonaktif, larangan membeli, dan kehilangan giliran.

### Alur presentasi kartu

Tampilkan kartu → jelaskan instruksi → minta pilihan/input atau dadu jika diperlukan → tampilkan konsekuensi → jalankan aksi → perbarui papan, uang, dan log.

Tidak semua kartu perlu lempar dadu. Baterai Sekarat meminta kondisi HP; Pembebasan Lahan meminta pilihan target.

Animasi harus mengikuti penyelesaian logika. Cegah tombol berulang menggandakan pembayaran, perpindahan, atau konversi petak.

### Ekonomi dan interaksi

Pembayaran kepada Negara mengurangi uang yang beredar di antara pemain. PHK dapat menghentikan pemasukan baru dari START. Konversi properti menjadi tol dapat menghilangkan sumber sewa pribadi. Gabungan efek tersebut membantu menjelaskan risiko kehilangan kemampuan membayar meskipun sebelumnya memiliki aset.

Adegan reaksi pemain menunjukkan pentingnya waktu pengungkapan kartu dan penjelasan konsekuensi. Tampilkan alasan perubahan keadaan agar pemain memahami mengapa uang, hak transaksi, atau fungsi petak berubah.

## 17. Skenario verifikasi tambahan dan pertanyaan terbuka

| Skenario | Hasil yang diharapkan / batas verifikasi |
| --- | --- |
| WIBU hasil genap | Tujuan Bandung; aturan START dan efek tujuan menunggu konfirmasi |
| WIBU hasil ganjil | Pembayaran Rp500 ribu dan kehilangan satu giliran; waktu skip menunggu konfirmasi |
| PHK hasil 5–6 | Semua pemain kehilangan hak gaji sesuai durasi resmi; jangan otomatis mematikan sewa |
| PHK hasil 3–4 | Pembelian tanah/rumah dibatasi; jangan otomatis mematikan sewa |
| PHK hasil 1–2 | Semua pemain menuju Pengadilan dan efek lokasi diselesaikan; urutan perlu ditetapkan dari aturan |
| Baterai 11% | Bayar Rp1 juta sekali |
| Baterai tepat 30% | Bayar Rp500 ribu berdasarkan pembacaan batas |
| Baterai tepat 50% | Aman |
| Tidak membawa HP | Bayar Rp2 juta |
| Pembacaan baterai gagal | Jangan otomatis menyamakan dengan tidak membawa HP |
| Pembebasan Lahan tanpa kepemilikan tanah | Abaikan efek; jangan otomatis menarik ulang kartu |
| Pemain menolak Pembebasan Lahan | Tidak ada tanah yang dikonversi |
| Target hanya tanah sendiri | Tidak sah menurut target yang tertulis |
| Konversi tanah lawan | Fungsi tol permanen; tidak lagi menagih sewa lama |
| Pengadilan dengan Rp6,2 juta | Pembayaran Rp3,1 juta |
| Harga Gorontalo/Manado | Rp2,5 juta; tarif sewa tetap belum diketahui |

Pertanyaan tambahan:
- Definisi “satu putaran” pada PHK.
- Waktu penerapan kehilangan giliran WIBU.
- Aturan pendaratan dan gaji pada perpindahan langsung.
- Urutan penyelesaian Pengadilan untuk seluruh pemain.
- Durasi jika kartu PHK muncul berulang dan interaksi dengan efek lain.
- Penanganan bangunan dan kepemilikan setelah penyitaan.
- Pilihan adaptasi baterai untuk komputer, perangkat bersama, atau multiplayer.
- Rincian cabang Lampung pada Korban Begal yang terpotong di tepi video (bagian 30).
- Satuan pembulatan pembayaran 50%.

## 18. Rekap status pengumpulan

- Bentuk papan, kelompok wilayah, dan komponen sudah dicatat; urutan setiap petak belum lengkap.
- Nominal properti yang terkumpul: Padang (harga sementara), Palu, Jakarta, Surabaya dari analisis gameplay sebelumnya, serta harga papan Gorontalo, Manado, Balikpapan, Palangkaraya, Solo, Bandung, dan Jogja. Pembacaan sertifikat IKN masih sementara.
- Kartu terdokumentasi: Penggeledahan KPK, Tambang Ilegal, WIBU, Kena PHK, Baterai Sekarat, Pembebasan Lahan, Subsidi BBM Dicabut, Generasi Sandwich, Dibungkam, Kabur Aja Dulu, dan Awas Ada Boomers!!!. Beberapa nominal dan kasus khusus masih perlu verifikasi.
- Catatan yang belum lengkap mencakup Orang Dalam, Sengketa, rincian kasus seri Tukar Nasib, cabang Lampung Korban Begal, seluruh cabang Banjir Bandang, dan cabang ganjil Buzzer.
- Koreksi Jakarta Rp4 juta dipertahankan; biaya subsidi Jakarta belum diisi.
- Aturan teramati dipisahkan dari interpretasi, pertanyaan terbuka, dan usulan adaptasi.
- Dokumen ini belum merupakan game Godot yang dapat dimainkan.

## 19. Indeks bukti “WNI cobain WNI Simulator pt.2”

Video berdurasi sekitar 1 menit 23 detik menggabungkan demonstrasi kartu, potongan permainan, sketsa komedi, dan promosi produk. Adegan berurutan tidak selalu merupakan giliran yang berkesinambungan.

| Waktu perkiraan | Bukti | Temuan |
| --- | --- | --- |
| 00:00–00:01 | Subsidi BBM Dicabut | Pembayaran kepada Negara dengan nominal berbeda untuk pengambil kartu dan pemain lainnya |
| 00:11–00:12 | Generasi Sandwich | Transfer uang atau tanah kepada pemain termuda |
| 00:19–00:25 | Pendaratan di Parkiran Pungli | Petak dan pendaratan terlihat; nominal pembayaran tidak terverifikasi dari adegan ini |
| Sekitar 00:31 | Sertifikat IKN | Harga dan tarif tampak, tetapi pembacaan masih sementara |
| 00:31–00:32 | Dibungkam | Larangan berbicara sampai giliran berikutnya; denda per pelanggaran |
| Sekitar 00:38 | Papan Kalimantan | Harga Balikpapan dan Palangkaraya Rp2 juta |
| Sekitar 00:44 | Kabur Aja Dulu | Sekali pakai sebelum lempar dadu; efek lokasi tujuan tetap berlaku |
| Sekitar 00:50 | Papan Jawa | Solo, Bandung, dan Jogja Rp4 juta |
| Sekitar 00:56 | Kena PHK | Kartu yang telah dianalisis muncul kembali; tidak melengkapi seluruh pertanyaan durasi |
| 01:01–01:02 | Awas Ada Boomers!!! | Larangan pembelian global atau transfer kepada pemain tertua |
| Sekitar 01:15–akhir | Promosi produk | Informasi preorder dalam rekaman, bukan bukti ketersediaan atau harga jual terkini |

Sketsa naik kuda/T-rex, keluarga besar, pemain dibawa pergi, kebakaran, dan properti komedi lain tidak otomatis menjadi mekanisme game.

## 20. Musibah: Subsidi BBM Dicabut

Sumber: sekitar 00:00–00:01. Instruksi memakai satu dadu.

| Hasil dadu | Pengambil kartu | Setiap pemain lainnya | Penerima |
| --- | ---: | ---: | --- |
| 5–6 | Tidak ada efek | Tidak ada efek | — |
| 3–4 | Rp400.000 | Rp200.000 | Negara |
| 1–2 | Tampak Rp600.000, sementara | Rp400.000 | Negara |

**Bagian akhir nominal pengambil kartu pada hasil 1–2 tertutup jari. Rp600.000 belum boleh dianggap sepenuhnya terverifikasi.**

“Semua pemain lainnya” dibaca sebagai pembayaran masing-masing pemain lain, bukan satu tagihan kolektif yang dibagi.

Contoh empat pemain, hasil 3–4:
- Pengambil kartu membayar Rp400.000.
- Tiga pemain lain masing-masing membayar Rp200.000.
- Total Negara menerima Rp1.000.000.

Untuk N pemain, total pembayaran hasil 3–4 adalah `400000 + 200000 × (N − 1)` rupiah. Dampak total bertambah dengan jumlah pemain.

Implikasi Godot:
- Satu kartu dapat menghasilkan banyak transaksi dengan nominal berbeda.
- Pisahkan kelompok pengambil kartu dan pemain lain agar tidak dihitung dua kali.
- Urutan penyelesaian kekurangan dana/kebangkrutan perlu mengikuti aturan lengkap.
- Tidak ada dasar membuat sistem konsumsi BBM atau kendaraan hanya dari tema kartu.

## 21. Musibah: Generasi Sandwich

Sumber: sekitar 00:11–00:12. Kartu memiliki ikon jam dan meminta satu dadu.

| Hasil dadu | Efek yang terbaca |
| --- | --- |
| 5–6 | Kamu dan pemain tertua masing-masing membayar Rp200.000 kepada pemain termuda |
| 3–4 | Kamu membayar Rp700.000 kepada pemain termuda |
| 1–2 | Berikan satu Surat Tanah termahal milikmu kepada pemain termuda; jika tidak memiliki Surat Tanah, bayar Rp2.000.000 kepadanya |

Pembayaran ditujukan kepada pemain, bukan Negara. Pada hasil 1–2, penyerahan tanah dan pembayaran pengganti adalah alternatif, bukan hukuman yang dijalankan sekaligus.

Contoh hasil 5–6 jika pengambil kartu, pemain tertua, dan pemain termuda adalah orang berbeda:

| Peran | Perubahan uang |
| --- | ---: |
| Pengambil kartu | −Rp200.000 |
| Pemain tertua | −Rp200.000 |
| Pemain termuda | +Rp400.000 |

Jumlah uang antarpemain tetap; distribusinya berubah.

Belum terverifikasi:
- Pengambil kartu sekaligus pemain tertua atau termuda.
- Beberapa pemain berusia sama.
- Beberapa tanah memiliki harga tertinggi yang sama.
- Dasar “termahal”: harga tanah saja atau beserta bangunan.
- Nasib bangunan di atas tanah yang diserahkan.
- Pemain sasaran sudah keluar/bangkrut.

Usulan Godot: masukkan urutan usia saat persiapan permainan. Tanggal lahir lengkap tidak diperlukan jika urutan sudah cukup untuk aturan. Penentuan kasus seri harus menjadi keputusan aturan yang eksplisit.

Cerita membiayai orang tua dan 13 adik adalah humor, bukan bukti adanya simulasi anggota keluarga.

## 22. Takdir: Dibungkam

Sumber: sekitar 00:31–00:32; teks jelas.

- Pemain tidak boleh bersuara/berbicara sampai gilirannya tiba kembali.
- Setiap kali tertangkap bersuara/berbicara, bayar Rp500.000 kepada Negara.
- Tidak terlihat instruksi lempar dadu.

| Pelanggaran yang dinyatakan selama efek aktif | Total denda |
| --- | ---: |
| 0 | Rp0 |
| 1 | Rp500.000 |
| 2 | Rp1.000.000 |
| 3 | Rp1.500.000 |

Kata “setiap” mendukung denda berulang. Batas efek mengikuti giliran pemilik kembali, bukan durasi detik. Ini berbeda dari kehilangan giliran: kartu tidak melarang pemain menerima sewa atau mengambil keputusan nonverbal.

### Usulan adaptasi Godot

- Status terlihat: “Dibungkam sampai giliran berikutnya”.
- Mode bermain bersama dapat memakai pencatatan pelanggaran manual dengan konfirmasi.
- Setiap pelanggaran yang sah menghasilkan satu pembayaran.
- Efek berakhir ketika giliran pemain kembali.
- Jangan mematikan semua kontrol pemain.
- Menganggap pesan chat sebagai pelanggaran adalah aturan adaptasi, bukan teks asli.
- Mematikan mikrofon otomatis mengubah tantangan karena pemain tidak dapat melanggar melalui kanal tersebut.
- Definisi satu pelanggaran, misalnya satu ucapan atau satu rangkaian bicara, belum dijelaskan.

Adegan pemain dibawa pergi merupakan dramatisasi; bukan instruksi memindahkan pion ke LAPAS atau mengeluarkannya dari permainan.

## 23. Takdir: Kabur Aja Dulu

Sumber: sekitar 00:44.

Teks yang terlihat:
1. Hanya sekali pakai.
2. Digunakan sebelum melempar dadu.
3. Pemain boleh pindah ke lokasi mana pun.
4. Efek lokasi tetap berlaku.

Kartu memberi pilihan tujuan, bukan kekebalan terhadap konsekuensi tujuan. Ucapan pemain tentang “tidak perlu bayar lima juta” tidak menetapkan harga kartu, denda, atau pengecualian baru.

Belum terverifikasi:
- Apakah perpindahan menggantikan lemparan dadu atau masih diikuti lemparan setelah efek lokasi.
- Penggunaan ketika ditahan di LAPAS.
- Apakah lokasi khusus Bekasi termasuk tujuan sah.
- Perlakuan gaji START.
- Kapan kartu dibuang dan mekanisme pengembalian ke dek.

Implikasi Godot:
- Sediakan tahap sebelum lempar dadu untuk penggunaan kartu simpanan.
- Pemain memilih tujuan lalu mengonfirmasi pemakaian.
- Jalankan efek tujuan setelah berpindah.
- Cegah penggunaan ulang kartu yang sudah dikonsumsi.
- Aturan Kabur Aja Dulu tentang efek tujuan tidak otomatis berlaku untuk semua kartu teleportasi lainnya.

Penanda cetak **T-03 ×2** terlihat. Ini metadata cetak, belum verifikasi lengkap mengenai komposisi dek atau semua edisi produk.

## 24. Musibah: Awas Ada Boomers!!!

Sumber: sekitar 01:01–01:02. Kartu memiliki ikon jam dan meminta satu dadu.

| Hasil dadu | Efek yang terbaca |
| --- | --- |
| 5–6 | Semua pemain tidak bisa membeli Surat Tanah dan Rumah selama satu putaran |
| 3–4 | Bayar Rp500.000 kepada pemain tertua |
| 1–2 | Surat Tanah termahal milikmu berpindah kepada pemain tertua; jika tidak memiliki Surat Tanah, bayar Rp3.500.000 kepadanya |

Penanda cetak **M-18 ×1** terlihat. Generasi Sandwich memperlihatkan **M-20 ×1**. Metadata tersebut tidak menetapkan jumlah seluruh dek.

Implikasi:
- Hasil dadu tinggi tidak selalu berarti tanpa kerugian.
- Larangan membeli tidak otomatis menonaktifkan sewa.
- Tidak punya tanah memicu pembayaran pengganti.
- Transfer ditujukan kepada pemain tertua, bukan Negara.
- Durasi “satu putaran” belum dipastikan sebagai putaran lintasan atau rangkaian giliran.

| Aspek | Generasi Sandwich | Awas Ada Boomers!!! |
| --- | --- | --- |
| Penerima utama | Pemain termuda | Pemain tertua |
| Pembayaran hasil 3–4 | Rp700.000 | Rp500.000 |
| Aset hasil 1–2 | Tanah sendiri termahal | Tanah sendiri termahal |
| Pengganti jika tanpa tanah | Rp2.000.000 | Rp3.500.000 |

Kasus usia seri, pengambil kartu sekaligus penerima, nilai tanah seri, dan penanganan bangunan masih belum diketahui. Jangan membuat aturan tambahan tanpa penanda keputusan adaptasi.

## 25. Harga dan potongan papan tambahan

### Harga yang terbaca pada papan

| Properti | Wilayah | Harga tanah | Sumber |
| --- | --- | ---: | --- |
| Balikpapan | Kalimantan | Rp2.000.000 | Sekitar 00:38 |
| Palangkaraya | Kalimantan | Rp2.000.000 | Sekitar 00:38 |
| Solo | Jawa | Rp4.000.000 | Sekitar 00:50 |
| Bandung | Jawa | Rp4.000.000 | Sekitar 00:50 |
| Jogja | Jawa | Rp4.000.000 | Sekitar 00:50 |

Harga tanah yang sama tidak berarti tarif sewa atau biaya bangunannya sama.

### Sertifikat IKN — seluruh nominal masih sementara

Sertifikat muncul singkat sekitar 00:31, kecil dan agak buram.

| Data | Pembacaan sementara |
| --- | ---: |
| Harga tanah | Rp2.000.000 |
| Sewa kosong | Rp500.000 |
| Sewa Subsidi 1 | Rp1.000.000 |
| Sewa Subsidi 2 | Rp1.500.000 |
| Sewa Rumah OKB | Rp3.000.000 |
| Biaya bangunan | Belum cukup terbaca |

Jangan menggunakan pembacaan sementara IKN sebagai data final tanpa gambar yang lebih jelas.

### Urutan petak yang terlihat

Dalam orientasi kiri–kanan gambar:
- Jawa sekitar 00:50: Musibah → Takdir → Solo → Bandung → Musibah → Jogja → sebagian Surabaya.
- Kalimantan sekitar 00:38: Musibah → Balikpapan → Palangkaraya → Takdir.
- IKN dan properti lain juga terlihat di Kalimantan, sebagian tertutup uang.

Orientasi gambar tidak otomatis sama dengan arah perjalanan pion. Cocokkan dengan START dan papan lengkap sebelum menetapkan indeks petak.

Komentar “harga Kalimantan bisa turun?” bukan bukti mekanisme tawar-menawar. “Jawa adalah kunci” bukan bukti bonus wilayah Jawa.

Adegan Parkiran Pungli sekitar 00:19–00:25 tidak memperlihatkan nominal pembayaran cukup jelas. Kena PHK muncul lagi sekitar 00:56, tetapi belum menyelesaikan pertanyaan definisi durasi.

## 26. Perluasan sistem ekonomi, kartu, dan pengujian

Bagian ini merupakan usulan implementasi berdasarkan temuan.

| Perubahan ekonomi | Contoh | Konsekuensi |
| --- | --- | --- |
| Bayar kepada Negara | Subsidi BBM Dicabut, Dibungkam | Uang keluar dari peredaran antarpemain |
| Transfer uang antarpemain | Generasi Sandwich, Boomers | Jumlah uang tetap, distribusi berubah |
| Transfer tanah | Cabang berat Sandwich/Boomers | Pemilik dan calon penerima sewa berubah |

Fungsi transaksi membutuhkan pembayar, penerima, nominal, dan alasan. Jangan selalu mengurangi uang tanpa mencatat siapa penerimanya.

### Kebutuhan data dan alur

- Urutan usia pemain untuk target tertua/termuda.
- Status Dibungkam dan pemicu berakhir pada giliran pemilik berikutnya.
- Catatan pelanggaran agar satu kejadian tidak ditagih dua kali.
- Tahap sebelum lempar dadu untuk kartu simpanan.
- Penentuan tanah termahal dengan kebijakan kasus seri yang terverifikasi.
- Alternatif pembayaran bila tidak memiliki aset.
- Sekumpulan transaksi berbeda dari satu kartu global.
- Transfer kepemilikan terpisah dari penghapusan data sertifikat.
- Keputusan tentang bangunan menunggu aturan; jangan otomatis merobohkan atau memindahkannya.
- Sumber dan status verifikasi setiap angka disimpan bersama datanya.

### Skenario verifikasi

| Skenario | Hasil yang perlu dipastikan |
| --- | --- |
| Subsidi BBM hasil 3–4, empat pemain | Empat transaksi; total Rp1 juta kepada Negara |
| Subsidi BBM hasil 5–6 | Tidak ada pembayaran dari efek ini |
| Subsidi BBM hasil 1–2 | Nominal pengambil kartu menunggu konfirmasi; jangan menganggap Rp600 ribu final |
| Sandwich, penerima termuda | Uang/aset masuk kepada pemain termuda, bukan Negara |
| Boomers, penerima tertua | Uang/aset masuk kepada pemain tertua, bukan Negara |
| Memiliki tanah pada cabang penyerahan | Jangan sekaligus menagih pembayaran pengganti |
| Tidak punya tanah | Gunakan nominal pengganti kartu yang benar |
| Dibungkam, tiga pelanggaran sah | Tiga pembayaran, total Rp1,5 juta |
| Giliran pemain Dibungkam kembali | Status berakhir |
| Pemain Dibungkam memilih aksi nonverbal | Jangan otomatis mengunci seluruh aksi |
| Kabur Aja Dulu | Hanya pada tahap yang sesuai; satu pemakaian; efek tujuan tetap berlaku |
| Larangan membeli | Tidak otomatis menghapus hak sewa |
| Usia seri / pengambil sekaligus target | Tangani setelah aturan ditetapkan; jangan menagih ganda secara tidak sengaja |
| Tanah termahal seri | Jangan memilih diam-diam tanpa aturan |
| Harga tanah sama | Jangan menyalin tarif sewa antarproperti |

### Pertanyaan terbuka tambahan

- Nominal lengkap Subsidi BBM hasil 1–2 yang tertutup jari.
- Urutan penyelesaian jika beberapa pemain kekurangan uang bersamaan.
- Aturan ketika pembayar dan penerima merupakan pemain yang sama.
- Aturan usia seri dan pemain yang telah keluar.
- Dasar pemeringkatan harga tanah serta perlakuan bangunan.
- Definisi satu pelanggaran Dibungkam dan penerapannya pada chat/voice.
- Kelanjutan giliran setelah Kabur Aja Dulu.
- Tujuan khusus, LAPAS, dan START saat memakai kartu tersebut.
- Definisi satu putaran serta penumpukan larangan pembelian.
- Pembacaan sertifikat IKN dan biaya bangunannya.

## 27. Indeks gabungan harga dan kartu

### Seluruh harga tanah yang telah dicatat

Tabel ini merupakan indeks ringkas. Tarif sewa, biaya bangunan, timestamp, serta catatan keterbacaan tetap merujuk bagian terkait.

| Properti | Harga tanah | Status / rujukan |
| --- | ---: | --- |
| Padang | Rp1.500.000 | Sementara; bagian nominal tertutup, bagian 2 |
| Batam | Rp1.500.000 | Terbaca pada papan, bagian 34 |
| Pontianak | Rp2.000.000 | Terbaca pada papan, bagian 34 |
| IKN | Rp2.000.000 | Sementara; sertifikat kecil/buram, bagian 25 |
| Balikpapan | Rp2.000.000 | Terbaca pada papan, bagian 25 |
| Palangkaraya | Rp2.000.000 | Terbaca pada papan, bagian 25 |
| Palu | Rp2.500.000 | Sertifikat dan papan cocok, bagian 2 dan 15 |
| Gorontalo | Rp2.500.000 | Terbaca pada papan, bagian 15 |
| Manado | Rp2.500.000 | Terbaca pada papan, bagian 15 |
| Jakarta | Rp4.000.000 | Sertifikat; koreksi pembacaan lama Rp6 juta, bagian 2 |
| Surabaya | Rp4.000.000 | Catatan analisis gameplay sebelumnya, bagian 2 |
| Solo | Rp4.000.000 | Terbaca pada papan, bagian 25 |
| Bandung | Rp4.000.000 | Terbaca pada papan, bagian 25 |
| Jogja | Rp4.000.000 | Terbaca pada papan, bagian 25 |

Ini belum melengkapi seluruh 25 properti.

### Indeks kartu

| Kartu / kejadian | Bagian | Status ringkas |
| --- | ---: | --- |
| Penggeledahan KPK | 3 | Tiga cabang terbaca |
| Tambang Ilegal | 4 | Efek utama terbaca; beberapa kondisi masih sementara |
| Orang Dalam | 5 | Catatan gameplay, teks lengkap belum dicatat |
| Sengketa | 5 | Penjelasan gameplay, teks lengkap belum terbaca |
| Tukar Nasib | 5, 32 | Teks pertukaran dan klausul uang sama terbaca; urutan/cakupan kasus seri belum pasti |
| WIBU | 11 | Cabang terbaca; detail perpindahan/skip belum lengkap |
| Kena PHK | 12 | Efek utama tercatat; durasi satu putaran belum pasti |
| Baterai Sekarat | 13 | Tabel terbaca; adaptasi perangkat perlu keputusan |
| Pembebasan Lahan | 14 | Teks utama jelas; penanganan bangunan belum diketahui |
| Korban Begal | 15, 30 | Nama kartu dan cabang 5–6 serta nominal 3–4 terbaca; cabang Lampung terpotong |
| Subsidi BBM Dicabut | 20 | Salah satu nominal tertutup jari |
| Generasi Sandwich | 21 | Cabang terbaca; kasus target dan aset seri belum diketahui |
| Dibungkam | 22 | Teks jelas; definisi pelanggaran/adaptasi perlu keputusan |
| Kabur Aja Dulu | 23 | Teks jelas; kelanjutan giliran belum pasti |
| Awas Ada Boomers!!! | 24 | Cabang terbaca; durasi dan kasus seri belum diketahui |
| Mafia Tanah | 29 | Pengambilan gratis satu tanah belum dibeli; semua sudah dibeli: abaikan |
| Banjir Bandang | 31 | Contoh ke Bekasi dan skip satu giliran; teks/cabang lengkap belum terlihat |
| Pengalihan Isu | 33 | Langsung masuk LAPAS |
| Buzzer | 33 | Genap menerima Rp800 ribu; cabang ganjil tertutup |

Semua temuan di atas adalah acuan analisis. Implementasi game belum dibuat dalam repositori ini. Pertanyaan terbuka tidak dianggap sudah terjawab hanya karena rancangan teknis dapat dibuat.

## 28. Indeks bukti video 76,97 detik

Judul dalam video: “WNI cobain WNI Simulator”. Ini montase permainan dan komedi, bukan rekaman satu sesi utuh tanpa potongan. Unggahan ulang dengan akhiran (1) identik dengan unggahan sebelumnya; SHA-256: `cf21ff949398b3c41786f168fdb53ead04ec263d9611db3d21fa96d54cba6642`.

| Waktu perkiraan | Bukti | Temuan |
| --- | --- | --- |
| 00:00–00:03 | Pajak Tahunan dan dialog tanah | Pion berada di petak pajak; dialog mengaitkannya dengan kepemilikan tanah |
| Sekitar 00:04 | Sertifikat Solo | Nama terbaca; nominal kecil/buram, tidak ditambahkan sebagai tarif final |
| 00:04–00:06 | Mafia Tanah | Pilih satu tanah belum dibeli dan ambil gratis; abaikan jika semua sudah dibeli |
| 00:06–00:08 | Sertifikat Merauke | Nama terbaca; nominal tidak cukup jelas untuk data final |
| 00:09–00:11 | Korban Begal | Skip giliran berikutnya, pembayaran Rp400 ribu, dan sebagian cabang Lampung |
| 00:15–00:19 | Pengadilan | Hasil 6 disebut dan hadiah Rp1 juta diperlihatkan |
| 00:20–00:27 | Musibah/Banjir Bandang | Pion dipindahkan ke Bekasi; subtitle menyebut skip satu giliran |
| 00:30–00:32 | Tukar Nasib | Pertukaran seluruh uang serta klausul uang sama |
| 00:39–00:43 | Pengalihan Isu | Pindah langsung ke LAPAS |
| 00:46–00:49 | Tilang dan papan Sumatera | Batam Rp1,5 juta; pendaratan Tilang, nominal denda tidak terlihat |
| 00:50–00:52 | Buzzer | Dadu genap mendapat Rp800 ribu dari Negara; ganjil tertutup jari |
| 00:56–01:04 | Solo, pemilik di LAPAS | Sewa dibayar kepada Negara, bukan pemilik yang ditahan |
| Sekitar 01:02 | Papan dekat LAPAS | Pontianak Rp2 juta |
| 01:07–akhir | Sketsa Bekasi/astronaut | Komedi; tidak menjelaskan mekanisme kembali ke lintasan |

## 29. Takdir: Mafia Tanah

Teks kartu sekitar 00:05 terbaca jelas:
- Jika semua Surat Tanah telah dibeli, abaikan efek kartu.
- Pemain dapat memilih satu Surat Tanah yang belum dibeli dan mengambilnya secara gratis.
- Tidak tercantum instruksi lempar dadu pada kartu yang terlihat.
- Ikon jam terlihat; penanda cetak T-22 ×1.

Demonstrasi diikuti pemain memperlihatkan sertifikat Merauke. Itu adalah contoh pilihan, bukan instruksi bahwa kartu selalu memberikan Merauke.

### Batas efek

- Tidak mengambil tanah lawan.
- Tidak membayar harga pembelian.
- Tidak ada instruksi memindahkan pion ke tanah yang dipilih.
- Jika seluruh tanah telah dibeli, abaikan; jangan otomatis mengambil kartu pengganti.
- Status tanah yang pernah dibeli lalu dikembalikan/disita Negara belum dijelaskan oleh frasa “belum dibeli”.
- Tidak boleh menyamakan tanah yang berubah menjadi tol dengan tanah belum dibeli.
- Interaksi dengan larangan pembelian dari PHK/Boomers belum terverifikasi: akuisisi gratis perlu dibedakan dari transaksi pembelian.

### Implikasi Godot

Sediakan daftar tanah yang memenuhi kondisi, konfirmasi pilihan, lalu ubah pemilik tanpa debit uang. Pisahkan aksi memperoleh aset dari fungsi pembelian biasa. Simpan riwayat/status tanah agar tanah awal yang tersedia dapat dibedakan dari aset milik Negara akibat penyitaan.

Secara ekonomi, kartu ini menambah aset pemain tanpa mengurangi uang tunai. Keuntungan strategisnya berasal dari pilihan aset, bukan hanya nominal hadiah.

## 30. Musibah: Korban Begal

Nama kartu yang sebelumnya hanya tercatat sebagai “kejadian begal” kini terlihat. Sekitar 00:09–00:10, kartu meminta satu dadu.

| Hasil dadu | Bukti yang dapat dicatat | Batas keterbacaan |
| --- | --- | --- |
| 5–6 | Motor hilang; skip giliran berikutnya | Terbaca jelas |
| 3–4 | Bayar Rp400.000 kepada Negara | Akhir alasan terpotong; video lain menyebut cicilan motor belum lunas |
| 1–2 | Teks menyebut motor ke Lampung, perpindahan ke lokasi, serta kondisi Lampung belum dimiliki atau dimiliki pemain lain | Sisi kanan dan bagian bawah terpotong; konsekuensi lengkap belum diketahui |

Arah pembacaan cabang 1–2 adalah perpindahan ke Lampung, tetapi aturan pembelian/sewa/denda lanjutannya tidak boleh direkonstruksi dari dugaan.

Berbeda dari WIBU yang waktu skip-nya belum jelas, Korban Begal secara eksplisit menyebut **giliran berikutnya** pada cabang 5–6. Jangan menambahkan pembayaran Rp400 ribu ke cabang 5–6: itu nominal cabang 3–4.

Untuk Godot:
- Cabang 5–6 menjadwalkan satu giliran berikutnya untuk dilewati.
- Cabang 3–4 menghasilkan transaksi ke Negara.
- Cabang 1–2 memerlukan aturan berbasis keadaan kepemilikan Lampung setelah teks lengkap tersedia.
- Tema kehilangan motor belum menjadi bukti inventaris kendaraan.
- Belum diketahui apakah cabang Lampung mencakup keadaan pemain sudah memiliki Lampung sendiri.

## 31. Banjir Bandang dan fungsi Bekasi

Sekitar 00:23, nama Banjir Bandang disebut melalui subtitle ketika pemain membaca kartu Musibah. Subtitle berikutnya menyatakan pemain terseret ke Bekasi dan skip satu giliran. Pion terlihat dipindahkan ke lingkaran Bekasi di tengah papan.

**Temuan baru yang didukung demonstrasi:**
1. Bekasi mempunyai fungsi permainan, bukan sekadar dekorasi.
2. Setidaknya satu efek Banjir Bandang mengirim pemain ke sana.
3. Efek yang diperagakan juga menyebabkan kehilangan satu giliran.
4. Bekasi berada di luar lintasan utama yang terlihat pada papan.

**Belum diketahui:**
- Hasil dadu/cabang yang menyebabkan efek tersebut.
- Teks seluruh cabang Banjir Bandang.
- Giliran mana tepatnya dilewati jika kartu tidak menyebut “berikutnya”.
- Posisi pion setelah hukuman berakhir.
- Apakah kembali ke petak asal, petak tertentu, atau menggunakan pilihan lain.
- Perlakuan START dan sewa selama berada di Bekasi.
- Apakah ada pemicu lain untuk masuk Bekasi.

Sketsa astronaut pada akhir video tidak menetapkan biaya roket, jumlah putaran perjalanan, atau hukuman tinggal sampai permainan selesai.

### Usulan Godot

Pisahkan posisi pion menjadi lokasi pada lintasan atau area khusus. Catat lokasi asal dan penyebab perpindahan untuk mendukung aturan kembali yang nanti diverifikasi; penyimpanan lokasi asal bukan keputusan bahwa pion pasti kembali ke sana. Status kehilangan giliran terpisah dari status tahanan LAPAS. Jangan menjalankan aritmetika pergerakan lintasan pada indeks Bekasi yang fiktif.

## 32. Takdir: Tukar Nasib — teks klausul seri kini terbaca

Sekitar 00:31–00:32, teks memperjelas:
- Pemain dengan uang terbanyak dan pemain dengan uang paling sedikit saling menukar seluruh uang mereka.
- Jika ada dua pemain atau lebih dengan jumlah uang sama, seluruh uang “mereka” diserahkan kepada Negara.
- Negara memberikan kompensasi Rp50.000 “untuk mereka”.
- Penanda cetak T-19 ×1 terlihat.

Yang pasti: pertukaran menyangkut **uang**, bukan tanah/bangunan. Pengambil kartu tidak otomatis menjadi salah satu pihak pertukaran.

Contoh tanpa seri:
A memiliki Rp6 juta, B Rp2 juta, C Rp500 ribu. Setelah pertukaran, A Rp500 ribu, B tetap Rp2 juta, C Rp6 juta. Aset dan posisi pion tetap berdasarkan efek yang tertulis.

### Ketidakjelasan yang masih harus dipertahankan

Teks tidak secara eksplisit membatasi kondisi uang sama pada pemain terkaya/termiskin. Karena itu, jangan menyatakan kondisi tersebut hanya berlaku jika nilai maksimum atau minimum seri.

Kasus yang memerlukan penjelasan aturan:
- Dua pemain memiliki uang sama di tengah urutan, sementara maksimum dan minimum unik.
- Ada lebih dari satu kelompok uang sama.
- Apakah penyitaan menggantikan pertukaran atau berjalan sebelum/sesudahnya.
- Rujukan “mereka” dalam penyelesaian setiap kelompok.
- Apakah Rp50.000 diberikan per pemain terdampak atau sebagai kompensasi bersama; tulisan “untuk mereka” belum merinci pembagiannya.
- Apakah saldo nol beberapa pemain ikut memicu kondisi ini.

Jangan menjalankan efek berulang sampai nilai uang berbeda. Jika kompensasi membuat beberapa pemain sama-sama memegang nominal sama, pemeriksaan ulang rekursif tanpa aturan dapat menciptakan loop.

### Usulan Godot

Ambil satu snapshot seluruh saldo sebelum penyelesaian. Tentukan target dan kelompok seri dari snapshot. Untuk pertukaran biasa, simpan kedua nilai lama sebelum mengubah saldo agar uang tidak tergandakan atau hilang. Selesaikan kasus seri hanya setelah kebijakan resmi/adaptasi ditetapkan dan diberi label.

## 33. Pengalihan Isu dan Buzzer

### Takdir: Pengalihan Isu

Sekitar 00:40, kartu menyatakan pemain langsung masuk Lapas Nusakambangan dan memindahkan pion ke lokasi LAPAS.

- Ini pengiriman sebagai tahanan, bukan sekadar kunjungan biasa.
- Tidak terlihat instruksi lempar dadu atau denda khusus pada kartu.
- Jangan menambahkan denda Rp500 ribu KPK atau Rp1,5 juta Pengadilan secara otomatis.
- Aturan umum tahanan tetap diproses sesuai sumber aturan LAPAS.
- Takdir biru sekali lagi dapat memberikan kerugian.

Implikasi Godot: gunakan aksi perpindahan paksa disertai status tahanan dan alasan asal kartu. Efek masuk penjara tidak boleh melewati Pengadilan secara implisit.

### Takdir: Buzzer

Sekitar 00:50–00:52, kartu meminta satu dadu.

| Hasil | Pembacaan |
| --- | --- |
| 2, 4, 6 | Menerima Rp800.000 dari Negara sebagai insentif |
| 1, 3, 5 | Bagian penting tertutup dua jari dan subtitle; terlihat narasi “blunder”, tetapi konsekuensi belum cukup terbaca |

Jangan menganggap cabang ganjil tanpa efek, denda nominal tertentu, atau masuk LAPAS sebagai aturan terverifikasi hanya dari potongan huruf.

Dengan asumsi satu dadu adil, peluang cabang genap adalah 3/6 = 50%. Nilai harapan kartu secara keseluruhan belum dapat dihitung karena cabang ganjil belum diketahui. Rp800 ribu setara 80% gaji START Rp1 juta; ini perbandingan analitis, bukan aturan tambahan.

## 34. Penguatan LAPAS, Pengadilan, dan harga papan

### Sewa pemilik yang ditahan

Sekitar 00:56–01:04:
1. Pion mendarat di Solo.
2. Pemain lain mengaku sebagai pemilik.
3. Ditunjukkan bahwa pemilik sedang di LAPAS.
4. Subtitle menyatakan uang sewanya disita Negara.
5. Adegan memperagakan pembayaran kepada representasi Negara.

Ini menguatkan catatan tutorial: **sewa tetap dibayar, tetapi penerimanya Negara ketika pemilik ditahan**. Sertifikat masih diperlihatkan pemilik; adegan tidak membuktikan pengalihan kepemilikan tanah kepada Negara.

| Keadaan | Sewa / penerima |
| --- | --- |
| Pemilik bebas tanpa efek lain | Pemilik, menurut aturan sewa biasa |
| Pemilik ditahan di LAPAS | Negara, didukung demonstrasi ini |
| Sewa dinonaktifkan KPK | Sewa tidak berlaku sampai batas efek |
| LAPAS dan KPK bersamaan | Prioritas belum diketahui |

Status tahanan perlu dipisahkan dari posisi pion di petak LAPAS. Pengunjung biasa tidak otomatis kehilangan hak menerima sewa.

Tarif Solo tidak terbaca cukup jelas dari sertifikat pada video ini. Jangan menebaknya dari Jakarta atau Surabaya.

### Pengadilan, pajak, dan Tilang

- Sekitar 00:15–00:19, pemain menyebut hasil dadu 6 dan memperlihatkan Rp1 juta. Ini mendukung cabang kemenangan Pengadilan; pendaratan di Pengadilan tidak selalu berujung penjara.
- Adegan awal menghubungkan Pajak Tahunan dengan kepemilikan tanah, tetapi tidak menunjukkan perhitungan baru. Tarif tetap merujuk sumber sebelumnya.
- Sekitar 00:46–00:49, pemain mendarat di Tilang setelah pergerakan; subtitle menyebut baru gajian. Nominal denda tidak diperlihatkan secara jelas, sehingga adegan tidak memverifikasi ulang tarif Rp500 ribu.
- Jangan menyamakan Tilang yang bersebelahan dengan LAPAS sebagai penahanan.

### Harga baru yang terbaca

| Properti | Wilayah | Harga tanah | Sumber |
| --- | --- | ---: | --- |
| Batam | Sumatera | Rp1.500.000 | Sekitar 00:48–00:49 |
| Pontianak | Kalimantan | Rp2.000.000 | Sekitar 01:02 |

Nama Merauke pada sertifikat terbaca, tetapi nominal harga, sewa, dan bangunannya belum cukup jelas untuk ditetapkan. Sertifikat Solo juga terlalu kecil/buram untuk menambah tarif final.

Potongan papan memperlihatkan kedekatan Batam → Tilang → LAPAS → Pontianak menurut urutan lintasan lokal, serta Jakarta → Musibah → Takdir → Solo pada sisi Jawa dalam salah satu orientasi gambar. Arah gerak dan indeks final tetap harus dicocokkan dengan papan lengkap.

## 35. Implikasi implementasi, pengujian, dan batas informasi terbaru

### Pemisahan keadaan yang diperlukan

| Data/aksi | Mengapa dibutuhkan |
| --- | --- |
| Tanah belum dibeli vs tanah disita Negara | Mafia Tanah tidak otomatis berlaku untuk semua aset tanpa pemilik pemain |
| Posisi khusus Bekasi | Area di luar lintasan membutuhkan alur perpindahan tersendiri |
| Status tahanan vs pengunjung | Menentukan penerima sewa, bukan hanya posisi pion |
| Jadwal skip giliran | Korban Begal eksplisit tentang giliran berikutnya |
| Snapshot saldo | Tukar Nasib harus menukar nilai asli secara konsisten |
| Identitas penerima transaksi | Pemilik, Negara, dan pemain target tidak dapat disamakan |
| Cabang kartu belum diketahui | Jangan menjalankan cabang ganjil Buzzer/Lampung dengan aturan rekaan |
| Sumber efek dan prioritas | KPK, LAPAS, dan efek lain dapat bertumpuk |

### Skenario pengujian tambahan

- Mafia Tanah memberi satu tanah yang memenuhi syarat tanpa mengurangi uang.
- Mafia Tanah tidak mengambil tanah lawan dan tidak otomatis memindahkan pion.
- Semua tanah sudah dibeli: efek diabaikan, bukan menarik kartu baru.
- Korban Begal 5–6 melewati tepat satu giliran berikutnya.
- Korban Begal 3–4 menagih Rp400 ribu kepada Negara; jangan menggabungkan hukuman cabang lain.
- Bekasi dapat menampung pion tanpa dianggap indeks lintasan normal; aturan kembali masih terbuka.
- Tukar Nasib tanpa seri menukar dua saldo lama, tidak memindahkan properti.
- Kasus seri tidak dijalankan berulang secara rekursif setelah kompensasi.
- Pengalihan Isu mengirim ke LAPAS tanpa menambahkan denda kartu lain.
- Buzzer genap memberi Rp800 ribu dari Negara; ganjil tetap ditandai belum terverifikasi.
- Pemilik Solo yang ditahan: sewa dibayarkan kepada Negara tanpa memindahkan sertifikat.
- Pengunjung LAPAS tidak otomatis diperlakukan sebagai tahanan.
- Pengadilan hasil 6 memberi Rp1 juta, bukan mengirim pemain ke penjara.
- Batam Rp1,5 juta dan Pontianak Rp2 juta; sewa/bangunan tidak diisi dari properti lain.

### Pertanyaan yang tersisa dari video ini

1. Apakah tanah yang pernah dibeli kemudian disita dapat dipilih Mafia Tanah?
2. Apakah larangan pembelian menghalangi akuisisi gratis?
3. Teks lengkap Korban Begal cabang Lampung.
4. Seluruh cabang Banjir Bandang serta posisi kembali dari Bekasi.
5. Cakupan, urutan, dan pembagian kompensasi klausul uang sama Tukar Nasib.
6. Cabang ganjil Buzzer.
7. Prioritas LAPAS dan sewa nonaktif KPK ketika bersamaan.
8. Nominal sertifikat Merauke dan tarif Solo.
9. Durasi/urutan giliran jika beberapa efek kehilangan giliran bertumpuk.

Analisis ini memperbarui bukti yang sebelumnya belum lengkap, tetapi tidak menjadikan semua pertanyaan aturan sudah terjawab. Dokumentasi tetap berupa acuan pengembangan Godot; tidak ada klaim bahwa game sudah diimplementasikan.
