# Design System — IoT Monitor (Neobrutalism)

Sumber kebenaran tampilan dashboard Flutter. Implementasi token:
`mobile/lib/theme/brutal.dart`.

## Prinsip

- Border hitam tebal 3 px pada semua kartu, tombol, dan chip.
- Hard shadow tanpa blur: offset 6 px (4 px untuk elemen kecil).
- Warna blok jenuh, tanpa gradien, tanpa blur.
- Sudut tegas (6 px) atau pill (999 px) untuk status/chip.
- Tipografi tebal (w900), uppercase untuk label, tracking rapat untuk angka.
- Efek tekan mekanis: elemen bergeser 4 px ke arah bayangan, bayangan hilang.

## Token warna

| Token | Nilai | Pemakaian |
| --- | --- | --- |
| `ink` | `#111111` | teks, border, shadow |
| `bg` | `#FFFDF5` | latar halaman + dot grid |
| `paper` | `#FFFFFF` | kartu netral |
| `yellow` | `#FFD93D` | aksen utama, suhu, tombol muat ulang |
| `blue` | `#4D96FF` | kelembapan, tren turun |
| `pink` | `#FF6B9D` | aksen sekunder |
| `green` | `#6BCB77` | status online, tren stabil |
| `red` | `#FF5252` | status offline, banner error |
| `orange` | `#FF9F1C` | tren naik |

## Tipografi

- Judul halaman: 46 px, w900, tinggi 0.92, tracking −1.5.
- Angka metrik: 42 px, w900, tracking −1.5.
- Label: 10–12 px, w900, uppercase, tracking 0.6–1.2.
- Body/penjelasan: 11–13 px, w600.

## Komponen

| Komponen | Aturan |
| --- | --- |
| Kartu | `BrutalCard`: border 3 px, radius 6 px, shadow 6 px |
| Tombol | `BrutalPressable` + `BrutalCard` 4 px, target sentuh ≥ 44 px |
| Status | Warna blok + ikon + teks (tidak hanya warna) |
| Sparkline | Garis hitam 3 px, area warna datar, titik persegi |
| Latar | Dot grid 18 px, opacity 8 % |

## Aksesibilitas

- Kontras teks hitam di atas kuning/biru/hijau/merah ≥ 4.5:1.
- Status tidak disampaikan lewat warna saja (ada ikon + label teks).
- Semua kontrol memiliki label semantik (`BrutalPressable.semanticLabel`).
- Target sentuh minimum 44×44 pt.
- Refresh manual tersedia (tarik ke bawah dan tombol muat ulang).

## Anti-pattern

- Gradien, blur, glassmorphism, shadow lembut.
- Emoji sebagai ikon struktural.
- Warna pastel berkontras rendah untuk teks.
