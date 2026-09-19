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
- Unggahan gameplay tambahan: `SaveInta.com_AQMHJKqzfz1-5No7M4e2kJLoCoMahKN05RkYVP_ek8p3hWgAqOY0THqoIBQ6tuUW5AstELNNgFm8F9qt5wJmq_mrpG7bksn8gmjgeN4.mp4` (84,52 detik, 720 × 1280). Dianalisis melalui frame, tulisan kartu, dan subtitle; bukan transkripsi audio lengkap.

Timestamp pada bagian 2–4 mengacu pada unggahan unboxing. Timestamp pada bagian 10–17 mengacu pada video gameplay tambahan berdurasi 84,52 detik. Timestamp tidak harus sama dengan versi pada tautan media sosial. Dokumen ini merangkum analisis percakapan; bukan salinan buku aturan resmi. Video, gambar, dan aset visual asli tidak disertakan.

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
- Seluruh cabang kartu kejadian begal.
- Satuan pembulatan pembayaran 50%.

## 18. Rekap status pengumpulan

- Bentuk papan, kelompok wilayah, dan komponen sudah dicatat; urutan setiap petak belum lengkap.
- Nominal properti yang terkumpul: Padang (harga sementara), Palu, Jakarta, Surabaya dari analisis gameplay sebelumnya, serta harga papan Gorontalo dan Manado.
- Kartu terdokumentasi: Penggeledahan KPK, Tambang Ilegal, WIBU, Kena PHK, Baterai Sekarat, Pembebasan Lahan.
- Catatan kartu yang belum lengkap: Orang Dalam, Sengketa, Tukar Nasib, dan kejadian begal.
- Koreksi Jakarta Rp4 juta dipertahankan; biaya subsidi Jakarta belum diisi.
- Aturan teramati dipisahkan dari interpretasi, pertanyaan terbuka, dan usulan adaptasi.
- Dokumen ini belum merupakan game Godot yang dapat dimainkan.
