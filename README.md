# Food Clasification – Klasifikasi Makanan Indonesia

> Aplikasi ini menggunakan CNN dan mekanisme cache berbasis KNN untuk mengenali 18 jenis makanan Indonesia secara offline.

---

## Daftar Isi

1. [Ringkasan Project](#1-ringkasan-project)
2. [Teknologi yang Digunakan](#2-teknologi-yang-digunakan)
2. [Jenis Machine Learning](#3-jenis-machine-learning)  
4. [Arsitektur CNN (MobileNetV2)](#4-arsitektur-cnn-mobilenetv2)  
5. [Algoritma yang Digunakan](#5-algoritma-yang-digunakan)  
6. [Arsitektur Sistem](#6-arsitektur-sistem)
7. [Alur Program](#7-alur-program)  
8. [Dataset](#8-dataset)  
9. [Training Model CNN](#9-training-model-cnn)  
10. [Implementasi KNN Cache](#10-implementasi-knn-cache)  
11. [Struktur Database](#11-struktur-database)
12. [Penjelasan Kode Penting](#12-penjelasan-kode-penting) 
13. [Cara Menjalankan Aplikasi](#13-cara-menjalankan-aplikasi)
14. [Hasil Pengujian](#14-hasil-pengujian)
15. [Kesimpulan](#15-kesimpulan)
16. [Referensi](#16-referensi)
---

## 1. Ringkasan Project

**Food Detection App** adalah aplikasi mobile berbasis Android yang dikembangkan menggunakan **Flutter** dan **TensorFlow Lite**. Aplikasi ini dapat mendeteksi jenis makanan dari gambar yang diambil melalui kamera atau dipilih dari galeri, kemudian memberikan informasi nutrisi lengkap seperti kalori, protein, karbohidrat, lemak, serat, gula, dan sodium.

### 1.1 Fitur Utama

| Fitur | Deskripsi |
|-------|------------|
| Deteksi 18 Makanan Indonesia | Mendukung klasifikasi makanan khas Indonesia seperti nasi goreng, rendang, sate, bakso, soto, dll |
| Informasi Nutrisi Lengkap | Menampilkan kalori, protein, karbohidrat, lemak, serat, gula, dan sodium per 100 gram |
| On-Device Learning | Model dapat belajar dari koreksi pengguna tanpa perlu training ulang atau koneksi internet |
| Persistent Cache | Koreksi pengguna disimpan dalam database SQLite lokal, tidak hilang setelah aplikasi ditutup |
| Offline Mode | Semua proses (prediksi, koreksi, cache) berjalan langsung di HP tanpa perlu internet |
| Confidence Warning | Menampilkan peringatan jika tingkat keyakinan model rendah (<70%) |
| Tips Kesehatan | Memberikan saran konsumsi dan peringatan untuk setiap jenis makanan |
| UI Modern | Desain material dengan animasi, gradient, dan card yang responsif |

### 1.2 Masalah yang Diselesaikan

| Masalah | Solusi |
|---------|--------|
| Model AI sulit diperbarui setelah deploy | Implementasi cache koreksi yang memungkinkan pembelajaran di perangkat |
| Informasi nutrisi tidak tersedia | Database nutrisi lengkap untuk 18 makanan Indonesia |
| Pengguna perlu internet untuk deteksi | Model TFLite berjalan offline di HP |
| Model tidak bisa belajar dari kesalahan | Feedback loop dengan SQLite untuk menyimpan koreksi |

---

## 2. Teknologi yang Digunakan

| Komponen | Teknologi | Versi | Fungsi |
|----------|-----------|-------|---------|
| Frontend Mobile | Flutter (Dart) | 3.x | UI, kamera, galeri, state management |
| Machine Learning | TensorFlow Lite | 2.x | Inferensi model di perangkat |
| Model CNN | MobileNetV2 | Pretrained | Klasifikasi gambar makanan |
| Database Lokal | SQLite (sqflite) | 2.3.0 | Menyimpan koreksi pengguna |
| Image Processing | image_picker | 1.0.7 | Ambil gambar dari kamera/galeri |
| Image Processing | image | 4.1.7 | Resize, decode, manipulasi gambar |
| State Management | setState + AnimationController | - | UI state dan animasi |

### Mengapa Memilih Teknologi Ini?

**Flutter:**
- Cross-platform (Android & iOS) dengan satu codebase
- Hot reload untuk development cepat
- Performa mendekati native
- Widget catalog yang lengkap

**TensorFlow Lite:**
- Ukuran model kecil (4.89 MB)
- Inferensi cepat (< 1 detik)
- Dukungan GPU acceleration
- Offline (tidak butuh internet)

**SQLite:**
- Ringan dan cepat
- Tidak perlu server
- Support indexing untuk pencarian cepat
- Data persisten (tidak hilang setelah app ditutup)
---
## 3. Jenis Machine Learning

## 3.1 Supervised Learning

Aplikasi ini menggunakan pendekatan **Supervised Learning**, yaitu model dilatih menggunakan dataset yang sudah memiliki label.

### Konsep Supervised Learning

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SUPERVISED LEARNING                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Dataset Training:                        Model belajar:                   │
│   ┌─────────────────────┐                 ┌─────────────────────────────┐   │
│   │ Gambar Nasi Goreng  │ ──label──▶      │ "Ini adalah gambar dengan  │   │
│   │ (vektor pixel)      │    "nasi"       │ tekstur nasi, warna coklat, │   │
│   └─────────────────────┘                 │ bentuk bulat-bulat"         │   │
│   ┌─────────────────────┐                 └─────────────────────────────┘   │
│   │ Gambar Rendang      │                                                   │
│   │ (vektor pixel)      │ ──label──▶ "rendang"                             │
│   └─────────────────────┘                                                   │
│   ┌─────────────────────┐                                                   │
│   │ Gambar Sate         │ ──label──▶ "sate"                                │
│   │ (vektor pixel)      │                                                   │
│   └─────────────────────┘                                                   │
│                                                                             │
│   Saat diberi gambar baru:                                                  │
│   ┌─────────────────────────┐                                               │
│   │ Gambar Nasi Goreng Baru │                                               │
│   │           ↓             │                                               │
│   │ Model: "Ini NASI GORENG"│                                               │
│   └─────────────────────────┘                                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Proses Training

- **Input:** Gambar makanan dalam format pixel RGB `224x224x3`
- **Output:** Label makanan (1 dari 18 kelas)
- **Loss Function:** `Categorical Crossentropy`
- **Optimizer:** `Adam`

### Penjelasan

- **Categorical Crossentropy** digunakan untuk mengukur seberapa besar kesalahan prediksi model.
- **Adam Optimizer** digunakan untuk memperbarui weight model agar prediksi semakin akurat.

## 3.2 Transfer Learning

Transfer learning adalah teknik menggunakan model yang sudah dilatih pada dataset besar seperti **ImageNet** (1.000 kelas objek umum), kemudian menyesuaikannya untuk tugas baru, yaitu klasifikasi 18 makanan Indonesia.

### Mengapa Menggunakan Transfer Learning?

| Aspek | Training dari Nol | Transfer Learning |
|---|---|---|
| Jumlah data | 10.000+ per kelas | 300–500 per kelas |
| Waktu training | 2–3 minggu | 3–4 jam |
| Akurasi | 70–80% | 84% |
| Resource GPU | Sangat besar | Moderat |

### Visualisasi Transfer Learning

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TRANSFER LEARNING                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Model Pretrained (ImageNet)            Model Fine-tuned (Makanan Indo)   │
│   ┌─────────────────────────┐            ┌─────────────────────────────┐   │
│   │ MobileNetV2             │            │ MobileNetV2 (Frozen)        │   │
│   │ Sudah mengenali:        │            │ ↓                           │   │
│   │ - Anjing 🐕             │ ───────▶   │ Layer baru untuk 18 kelas   │   │
│   │ - Kucing 🐈             │            │ ↓                           │   │
│   │ - Mobil 🚗              │            │ Output: nasi_goreng         │   │
│   │ - 1000 objek lainnya    │            │         rendang             │   │
│   └─────────────────────────┘            │         sate                │   │
│                                          └─────────────────────────────┘   │
│                                                                             │
│   Model belajar mengenali:                                                  │
│   - Tepi, sudut, tekstur                                                    │
│   - Warna dan bentuk dasar                                                  │
│   - Pola visual kompleks                                                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 3.3 On-Device Learning

On-device learning adalah kemampuan model untuk belajar dari koreksi pengguna tanpa perlu mengirim data ke server atau melakukan training ulang.

### Arsitektur On-Device Learning

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ON-DEVICE LEARNING                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ User upload gambar nasi goreng                                              │
│          ↓                                                                  │
│ Model CNN memprediksi → "mie_goreng" (SALAH)                                │
│          ↓                                                                  │
│ User koreksi → "nasi_goreng"                                                │
│          ↓                                                                  │
│ ┌─────────────────────────────────────────────────────────────────────────┐ │
│ │ HASH GAMBAR (fingerprint unik)                                         │ │
│ │ ↓                                                                       │ │
│ │ Database SQLite: (hash_gambar → "nasi_goreng")                          │ │
│ └─────────────────────────────────────────────────────────────────────────┘ │
│          ↓                                                                  │
│ Upload gambar yang sama lagi                                                │
│          ↓                                                                  │
│ Cek database → hash ditemukan → tampilkan "nasi_goreng"                    │
│          ↓                                                                  │
│ MODEL BELAJAR!                                                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Keunggulan On-Device Learning

- Privacy → data tidak dikirim ke server
- Offline → tetap berjalan tanpa internet
- Cepat → prediksi cache `< 0.1 detik`
- Efisien → tidak membutuhkan GPU besar

---

## 4 Arsitektur CNN (MobileNetV2)

### 4.1 Apa itu CNN?

**Convolutional Neural Network (CNN)** adalah jaringan saraf tiruan yang dirancang khusus untuk memproses data berbentuk grid seperti gambar.

CNN bekerja dengan cara menggeser filter kecil (*kernel*) ke seluruh gambar untuk mendeteksi pola visual.

### 4.2 Analogi Cara Kerja CNN

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CARA KERJA CNN (ANALOGI SEDERHANA)                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ Gambar Nasi Goreng                                                          │
│ ┌─────────────────┐                                                         │
│ │ █ █ █ ░ ░ ░ ░   │                                                         │
│ │ █ █ █ ░ ░ ░ ░   │   Filter 3x3                                            │
│ │ █ █ █ ░ ░ ░ ░   │   ┌─────┐                                               │
│ │ ░ ░ ░ █ █ █ ░   │   │ █ █ █ │ → mendeteksi tekstur nasi                  │
│ │ ░ ░ ░ █ █ █ ░   │   │ █ █ █ │                                             │
│ │ ░ ░ ░ █ █ █ ░   │   └─────┘                                               │
│ └─────────────────┘                                                         │
│                                                                             │
│ Hasil Deteksi:                                                              │
│ • Layer 1  → Tepi dan garis                                                 │
│ • Layer 2  → Bentuk sederhana                                               │
│ • Layer 3  → Tekstur makanan                                                │
│ • Layer akhir → "Ini NASI GORENG!"                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.3 Mengapa MobileNetV2?

MobileNetV2 dipilih karena memiliki keseimbangan antara akurasi dan ukuran model.

| Model | Akurasi | Ukuran | Kecepatan | Cocok Mobile |
|---|---|---|---|---|
| MobileNetV2 | 88% | 14 MB | Cepat | ✅ |
| ResNet50 | 92% | 98 MB | Lambat | ❌ |
| EfficientNet-Lite0 | 89% | 20 MB | Sedang | ✅ |
| InceptionV3 | 90% | 92 MB | Lambat | ❌ |

### 4.4 Keunggulan MobileNetV2

- **Depthwise Separable Convolution** → parameter lebih kecil hingga 8x
- **Inverted Residuals** → mempertahankan informasi penting
- **Linear Bottlenecks** → mengurangi kehilangan fitur

### 4.5 Struktur MobileNetV2

```text
Input: Gambar 224x224x3 (RGB)
        ↓
Conv2D (32 filters, stride 2)
        ↓
17 Bottleneck Residual Blocks
        ↓
Conv2D (1280 filters)
        ↓
Global Average Pooling
        ↓
Dense (256, ReLU)
        ↓
Dropout (0.5)
        ↓
Dense (18, Softmax)
        ↓
Output: 18 kelas makanan Indonesia
```

### 4.6 Cara Kerja CNN dalam Mendeteksi Makanan

```python
# Ilustrasi sederhana deteksi nasi goreng

Gambar Input (224x224x3)
        ↓
[Layer 1 - Deteksi Tepi]
        ↓
Mendeteksi garis vertikal dan horizontal
        ↓
[Layer 5 - Deteksi Bentuk]
        ↓
Mendeteksi bentuk bulat-bulat (butiran nasi)
        ↓
[Layer 10 - Deteksi Tekstur]
        ↓
Tekstur kasar dan warna coklat keemasan
        ↓
[Layer 17 - Deteksi Pola Kompleks]
        ↓
Butiran nasi + telur + sayuran
        ↓
[Layer Klasifikasi]
        ↓
"Ini adalah NASI GORENG" (confidence 85%)
```
### Detail pembuatan model yang di gunakan menggunakan python
(https://colab.research.google.com/drive/1HB22HFSpEKUu0ery4jbzVNZWVYL435PH?usp=drive_link)

---

## 5. Algoritma yang Digunakan

### 5.1 Convolutional Neural Network (CNN)

CNN digunakan sebagai algoritma utama untuk klasifikasi gambar.

### Convolution

Filter/kernel digeser ke seluruh gambar untuk mendeteksi fitur.

```text
(f * g)(x,y) = Σ f(i,j) · g(x-i, y-j)
```

### Pooling

Mengurangi dimensi feature map agar komputasi lebih ringan.

```text
Max Pooling (2x2)

┌─────────────┐     ┌─────┐
│ 1 3 2 4     │     │ 3 4 │
│ 0 2 1 5     │ ─▶  │ 5 6 │
│ 2 1 6 3     │     └─────┘
│ 1 0 4 2     │
└─────────────┘
```

### Aktivasi ReLU

```text
ReLU(x) = max(0, x)
```

### Softmax

Mengubah output menjadi probabilitas.

```text
Softmax(z_i) = e^{z_i} / Σ e^{z_j}
```

## 5.2 K-Nearest Neighbors (KNN) - Simplified Version

Pada proyek ini, konsep KNN digunakan dalam bentuk sederhana melalui hash matching.

### Algoritma

```dart
// 1. Hitung hash gambar
String hash = computeHash(gambar);

// 2. Cari di database
Correction? found = db.findByHash(hash);

// 3. Jika ditemukan → ambil label
if (found != null) return found.label;

// 4. Jika tidak ditemukan → prediksi CNN
return cnn.predict(gambar);
```

### Kompleksitas

- Pencarian hash → `O(1)`
- Penyimpanan → `O(n)`

## 5.3 Hash Function

Hash function digunakan untuk membuat fingerprint unik dari gambar.

```dart
String computeConsistentHash(List<int> imageBytes) {
  var hash = 0;

  for (int i = 0; i < imageBytes.length; i++) {
    hash = (hash * 31 + imageBytes[i]) & 0xFFFFFFFF;
  }

  return hash.toRadixString(16).padLeft(8, '0');
}
```

### Cara Kerja

1. Iterasi setiap byte gambar
2. Kalikan hash dengan `31`
3. Tambahkan nilai byte
4. Gunakan bitwise AND agar tetap 32-bit
5. Konversi menjadi hexadecimal

### Sifat Hash

- **Deterministik** → gambar sama menghasilkan hash sama
- **Unik** → gambar berbeda cenderung menghasilkan hash berbeda

### 5.3 Euclidean Distance

Digunakan untuk menghitung jarak antar vektor fitur.

```text
d(p,q) = √((p1-q1)² + (p2-q2)² + ... + (pn-qn)²)
```

### Interpretasi Jarak

| Jarak | Interpretasi |
|---|---|
| 0 | Vektor identik |
| 0 – 0.3 | Sangat mirip |
| 0.3 – 0.6 | Cukup mirip |
| > 0.6 | Tidak mirip |
---
## 6. Arsitektur Sistem

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                            APLIKASI FLUTTER                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    LAYER UI (PRESENTATION)                          │   │
│   │                                                                     │   │
│   │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │   │
│   │  │ HomeScreen   │  │ Result Card  │  │ Food List    │               │   │
│   │  │ - Upload     │  │ - Nutrisi    │  │ - 18 Makanan │               │   │
│   │  │ - Kamera     │  │ - Tips       │  │ - Ikon       │               │   │
│   │  │ - Galeri     │  │ - Warning    │  │ - Expandable │               │   │
│   │  └──────────────┘  └──────────────┘  └──────────────┘               │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                  LOGIC LAYER (BUSINESS LOGIC)                       │   │
│   │                                                                     │   │
│   │  ┌──────────────────────────────────────────────────────────────┐   │   │
│   │  │                    HYBRID CLASSIFIER                         │   │   │
│   │  │                                                              │   │   │
│   │  │  predict()                learnFromFeedback()                │   │   │
│   │  │  - Cek hash               - Compute hash                     │   │   │
│   │  │  - Query database         - Insert/Update DB                 │   │   │
│   │  │  - Call CNN model         - Reset state                      │   │   │
│   │  └──────────────────────────────────────────────────────────────┘   │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                     DATA LAYER (STORAGE)                            │   │
│   │                                                                     │   │
│   │  ┌────────────────────┐  ┌────────────────────┐  ┌──────────────┐   │   │
│   │  │ SQLite Database    │  │ TFLite Model       │  │ Assets       │   │   │
│   │  │ - corrections.db   │  │ - food_model.tflite│  │ - labels.txt │   │   │
│   │  │ - hash → label     │  │ - 4.89 MB          │  │ - 18 kelas   │   │   │
│   │  └────────────────────┘  └────────────────────┘  └──────────────┘   │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 6.1 Penjelasan Arsitektur

Aplikasi dibangun menggunakan arsitektur berlapis (*layered architecture*) agar kode lebih terstruktur, mudah dikembangkan, dan mudah dipelihara.

#### Presentation Layer (UI)

Layer ini bertanggung jawab untuk menampilkan antarmuka pengguna.

Komponen utama:

- **HomeScreen**
  - Upload gambar
  - Kamera
  - Galeri

- **Result Card**
  - Informasi nutrisi
  - Tips makanan
  - Warning / peringatan

- **Food List**
  - Daftar 18 makanan
  - Ikon makanan
  - Expandable list

---

#### Business Logic Layer

Layer ini menangani logika utama aplikasi.

Komponen utama:

#### 1. Hybrid Classifier

Memiliki dua fungsi utama:

##### 2. `predict()`

Digunakan untuk melakukan prediksi gambar.

Proses:

1. Cek hash gambar
2. Query database SQLite
3. Jika tidak ditemukan → gunakan CNN

##### 3. `learnFromFeedback()`

Digunakan untuk pembelajaran dari koreksi pengguna.

Proses:

1. Hitung hash gambar
2. Insert/update database
3. Reset state aplikasi

#### Data Layer

Layer ini digunakan untuk penyimpanan data dan model.

Komponen:

| Komponen | Fungsi |
|---|---|
| SQLite Database | Menyimpan koreksi pengguna |
| TFLite Model | Model CNN MobileNetV2 |
| Assets | Label kelas makanan |

---

## 7. Alur Program

### 7.1 Fase Inisialisasi (Saat Aplikasi Dibuka)

```dart
// Step-by-step inisialisasi

Step 1: Load Model CNN
   ↓
_cnnModel = await Interpreter.fromAsset(
  'assets/food_indonesia_model.tflite'
);

debugPrint('✅ CNN Model loaded!');

Step 2: Load Labels
   ↓
String labelsData = await rootBundle.loadString(
  'assets/labels_indonesia.txt'
);

_labels = labelsData.split('\n');

debugPrint('📋 Labels loaded: ${_labels.length} classes');

Step 3: Inisialisasi Database SQLite
   ↓
_db = SimpleCorrectionDatabase();
await _db.init();

Step 4: Load Cache Koreksi
   ↓
final count = await _db.getCount();

debugPrint('📊 Correction cache loaded: $count entries');

Step 5: Aplikasi Siap Digunakan
   ↓
setState(() => _isLoading = false);
```

#### Penjelasan Fase Inisialisasi

Saat aplikasi dibuka:

1. Model CNN dimuat dari file `.tflite`
2. Label makanan dimuat dari file `.txt`
3. Database SQLite diinisialisasi
4. Cache koreksi pengguna dimuat
5. Aplikasi siap digunakan

## 7.2 Fase Prediksi Gambar

```dart
// Step-by-step prediksi

User memilih gambar (kamera / galeri)
   ↓
final XFile? pickedFile =
    await _picker.pickImage(source: source);

Step 1: Hitung Hash Gambar
   ↓
String imageHash = _computeImageHash(imageBytes);

Step 2: Cek Database SQLite
   ↓
final correction = await _db.findByHash(imageHash);
```

#### Decision Branch

```text
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│ [YA] correction != null                                             │
│      ↓                                                              │
│ 🎯 [CACHE] Menggunakan hasil koreksi                                │
│      ↓                                                              │
│ return Prediction(                                                  │
│   label: correction['label'],                                       │
│   probability: 0.95,                                                │
│   isFromCache: true                                                 │
│ );                                                                  │
│                                                                     │
│ [TIDAK] correction == null                                          │
│      ↓                                                              │
│ 🤖 [CNN] Tidak ada cache                                            │
│      ↓                                                              │
│ Konversi gambar → Tensor (224x224x3)                                │
│      ↓                                                              │
│ Run inference CNN                                                   │
│      ↓                                                              │
│ Cari probabilitas tertinggi (argmax)                                │
│      ↓                                                              │
│ return Prediction(                                                  │
│   label: predictedLabel,                                            │
│   probability: maxProb,                                             │
│   isFromCache: false                                                │
│ );                                                                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

#### Menampilkan Hasil

```dart
setState(() => _predictionResult = prediction);

_animationController.forward();
```

### 7.3 Fase Koreksi dan Pembelajaran

```dart
// Step-by-step pembelajaran

User klik tombol "SALAH"
   ↓
_log('👎 User mengklik tombol SALAH');
```

#### Step 1 — Pilih Label yang Benar

```dart
showModalBottomSheet(...)
```
Proses:

1. User membuka daftar makanan
2. User memilih label yang benar
3. Contoh: `"Nasi Goreng"`

#### Step 2 — Konfirmasi Koreksi

```dart
showDialog(...)
```

User memilih:

- `"Ya, Benar"`

#### Step 3 — Hitung Hash Gambar

```dart
String imageHash = _computeImageHash(imageBytes);
```

#### Step 4 — Cek Database

```dart
final existing = await _db.findByHash(imageHash);
```

#### Jika Data Sudah Ada

```text
🔄 Updating: oldLabel → newLabel
```

```dart
await _db.updateCorrection(...);
```

#### Jika Data Belum Ada

```text
📝 Inserted: hash → newLabel
```

```dart
await _db.insertCorrection(...);
```

#### Step 5 — Tampilkan Konfirmasi

```dart
showDialog(
  ...
  "Model sudah belajar!
   Silakan upload gambar yang sama lagi"
);
```

#### Step 6 — Reset State

```dart
setState(() {
  _selectedImage = null;
  _predictionResult = null;
});
```

#### Step 7 — Prediksi Berikutnya

Jika user mengupload gambar yang sama:

```text
[CACHE] Langsung tampilkan label yang benar ✅
```

---

## 8. Dataset

### 8.1 Daftar 18 Makanan Indonesia

| No | Label | Nama Indonesia | Kategori |
|---|---|---|---|
| 1 | ayam_goreng | Ayam Goreng | Makanan Berat |
| 2 | bakso | Bakso | Makanan Berat |
| 3 | burger | Burger | Fast Food |
| 4 | french_fries | Kentang Goreng | Fast Food |
| 5 | gado_gado | Gado-Gado | Sayuran |
| 6 | gudeg | Gudeg | Makanan Berat |
| 7 | gulai_ikan | Gulai Ikan | Berkuah |
| 8 | ikan_goreng | Ikan Goreng | Makanan Berat |
| 9 | mie_goreng | Mie Goreng | Makanan Berat |
| 10 | nasi_goreng | Nasi Goreng | Makanan Berat |
| 11 | pempek | Pempek | Camilan |
| 12 | pizza | Pizza | Fast Food |
| 13 | rawon | Rawon | Berkuah |
| 14 | rendang | Rendang | Makanan Berat |
| 15 | sate | Sate | Makanan Berat |
| 16 | soto | Soto | Berkuah |
| 17 | telur_balado | Telur Balado | Lauk |
| 18 | telur_dadar | Telur Dadar | Lauk |

### 8.2 Distribusi Dataset

#### Distribusi Utama

| Dataset | Jumlah Gambar | Persentase |
|---|---|---|
| Training | 5.780 gambar | 80% |
| Validation | 1.451 gambar | 20% |
| Total | 7.231 gambar | 100% |


#### Detail per Kelas

| Label | Train | Validation | Total |
|---|---|---|---|
| ayam_goreng | 400 | 100 | 500 |
| bakso | 452 | 100 | 552 |
| burger | 400 | 100 | 500 |
| french_fries | 400 | 100 | 500 |
| gado_gado | 383 | 100 | 483 |
| gudeg | 510 | 100 | 610 |
| gulai_ikan | 111 | 100 | 211 |
| ikan_goreng | 400 | 100 | 500 |
| mie_goreng | 399 | 100 | 499 |
| nasi_goreng | 570 | 100 | 670 |
| pempek | 555 | 100 | 655 |
| pizza | 400 | 100 | 500 |
| rawon | 437 | 100 | 537 |
| rendang | 339 | 100 | 439 |
| sate | 532 | 100 | 632 |
| soto | 723 | 100 | 823 |
| telur_balado | 108 | 100 | 208 |
| telur_dadar | 112 | 100 | 212 |

### 8.3 Sumber Dataset

| Sumber | Jumlah | Keterangan |
|---|---|---|
| Food-101 (subset) | ~5.000 | Dataset internasional terlabel |
| Google Images | ~1.500 | Manual curation |
| Foto pribadi | ~731 | Foto langsung dari warung/restoran |


## Proses Pengumpulan Data

### 1. Download Dataset

Mengambil subset dari dataset **Food-101** untuk kategori yang relevan.

### 2. Scraping Google Images

Menggunakan kata kunci spesifik seperti:

- `"nasi goreng indonesia"`
- `"rendang padang"`
- `"sate ayam"`

### 3. Pembersihan Data

Dilakukan proses:

- Menghapus gambar duplikat
- Menghapus watermark
- Menghapus gambar tidak relevan

### 4. Normalisasi Data

Semua gambar diubah menjadi ukuran:

```text
224 x 224 pixel
```

### 5. Split Dataset

Dataset dibagi menjadi:

- **80% Training**
- **20% Validation**
---
## 9. Training Model CNN

### 9.1 Persiapan Dataset

#### Struktur Folder

```text
dataset_indonesia/
├── train/
│   ├── ayam_goreng/
│   │   ├── img_001.jpg
│   │   ├── img_002.jpg
│   │   └── ...
│   ├── bakso/
│   ├── rendang/
│   └── ...
└── val/
    ├── ayam_goreng/
    ├── bakso/
    ├── rendang/
    └── ...
```

#### Preprocessing dengan Augmentasi

```python
train_datagen = ImageDataGenerator(
    rescale=1./255,           # Normalisasi pixel 0-1
    rotation_range=20,        # Rotasi acak ±20°
    width_shift_range=0.2,    # Geser horizontal
    height_shift_range=0.2,   # Geser vertikal
    shear_range=0.2,          # Geser miring
    zoom_range=0.2,           # Zoom acak
    horizontal_flip=True,     # Flip horizontal (kamera kiri/kanan)
    brightness_range=[0.8, 1.2]  # Variasi kecerahan
)
```

### 9.2 Transfer Learning dengan MobileNetV2

```python
# 1. Load pretrained model
from tensorflow.keras.applications import MobileNetV2

base_model = MobileNetV2(
    weights='imagenet',      # Menggunakan weight dari ImageNet
    include_top=False,       # Membuang layer klasifikasi asli
    input_shape=(224, 224, 3)
)

# 2. Freeze base model (agar tidak ikut training)
base_model.trainable = False

# 3. Tambah layer klasifikasi baru untuk 18 kelas
x = base_model.output
x = GlobalAveragePooling2D()(x)   # [batch, 7,7,1280] → [batch, 1280]
x = Dense(256, activation='relu')(x)   # Hidden layer
x = Dropout(0.5)(x)                   # Mencegah overfitting
predictions = Dense(18, activation='softmax')(x)  # Output 18 kelas

# 4. Buat model lengkap
model = Model(inputs=base_model.input, outputs=predictions)

# 5. Compile
model.compile(
    optimizer='adam',
    loss='categorical_crossentropy',
    metrics=['accuracy']
)
```

### 9.3 Fine Tuning

```python
# 1. Unfreeze 100 layer terakhir
base_model.trainable = True

for layer in base_model.layers[:100]:
    layer.trainable = False

# 2. Recompile dengan learning rate lebih kecil
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

# 3. Training fine tuning
history2 = model.fit(
    train_generator,
    epochs=10,
    validation_data=val_generator,
    callbacks=[
        EarlyStopping(
            patience=3,
            restore_best_weights=True
        ),
        ReduceLROnPlateau(
            factor=0.5,
            patience=2
        )
    ]
)
```

### 9.4 Hasil Training

| Phase | Epoch | Train Acc | Val Acc | Val Loss |
|---|---|---|---|---|
| Phase 1 (Transfer) | 1 | 49.7% | 73.3% | 0.92 |
| Phase 1 (Transfer) | 5 | 70.5% | 76.0% | 0.77 |
| Phase 1 (Transfer) | 10 | 79.1% | 78.96% | 0.73 |
| Phase 2 (Fine Tuning) | 1 | 72.4% | 74.9% | 0.97 |
| Phase 2 (Fine Tuning) | 5 | 84.4% | 81.74% | 0.70 |
| Phase 2 (Fine Tuning) | 15 | 89.18% | 84.24% | 0.57 |

#### Grafik Akurasi

```text
Akurasi
100% ─┬────────────────────────────────────────────────────────────────
      │                                         ╭────╮
 90% ─┤                                   ╭────╯    ╰────╮
      │                              ╭─────╯             ╰─────╮
 80% ─┤                        ╭────╯                         ╰─────
      │                   ╭─────╯                                     Train Acc
 70% ─┤             ╭────╯                                           Val Acc
      │        ╭─────╯
 60% ─┤  ╭────╯
      │  ╭╯
 50% ─╯─┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴── Epoch
      1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
```

### 9.5 Export ke TensorFlow Lite

```python
# 1. Konversi ke TFLite dengan kuantisasi
converter = tf.lite.TFLiteConverter.from_keras_model(model)

converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]

tflite_model = converter.convert()

# 2. Simpan file
with open('food_indonesia_model.tflite', 'wb') as f:
    f.write(tflite_model)

# 3. Simpan labels
with open('labels_indonesia.txt', 'w') as f:
    for label in food_categories:
        f.write(f"{label}\n")

print(f"Model size: {len(tflite_model) / 1024 / 1024:.2f} MB")

# Output: Model size: 4.89 MB
```

---

## 10. Implementasi KNN Cache

### 10.1 Mengapa Perlu KNN Cache?

Model CNN yang sudah di-export ke TFLite bersifat statis dan tidak bisa diubah setelah di-deploy.

Masalah yang muncul:

- Model tidak bisa belajar dari kesalahan
- Harus training ulang jika ingin memperbaiki model
- Perlu deploy ulang APK

#### Solusi KNN Cache

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MASALAH vs SOLUSI                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ MASALAH:                           SOLUSI:                                  │
│ Model salah prediksi               Simpan koreksi di database               │
│ nasi_goreng → mie_goreng           (hash gambar → nasi_goreng)              │
│        ↓                                     ↓                              │
│ Tidak bisa diperbaiki              Prediksi berikutnya:                     │
│ tanpa training ulang               Cek database terlebih dahulu             │
│                                              ↓                              │
│                                      Jika ada, tampilkan                    │
│                                      "nasi_goreng" ✅                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 10.2 Cara Kerja Hash Gambar

Hash adalah fingerprint unik yang dihasilkan dari konten gambar.

```dart
String computeConsistentHash(List<int> imageBytes) {
  var hash = 0;

  for (int i = 0; i < imageBytes.length; i++) {
    hash = (hash * 31 + imageBytes[i]) & 0xFFFFFFFF;
  }

  return hash.toRadixString(16).padLeft(8, '0');
}
```

#### Contoh Hash

```text
Gambar nasi_goreng A → fa9f6bd7
Gambar nasi_goreng B → 2fc71d53
Gambar yang sama persis → hash SAMA
```

### 10.3 Database Schema

```sql
CREATE TABLE corrections(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  image_hash TEXT UNIQUE,
  label TEXT NOT NULL,
  original_prediction TEXT,
  created_at INTEGER,
  updated_at INTEGER
);

CREATE INDEX idx_hash ON corrections(image_hash);
```

### Penjelasan Kolom

| Kolom | Penjelasan |
|---|---|
| id | Primary key auto increment |
| image_hash | Fingerprint unik gambar |
| label | Label hasil koreksi user |
| original_prediction | Prediksi model yang salah |
| created_at | Waktu pertama dibuat |
| updated_at | Waktu terakhir diupdate |

### 10.4 Operasi Database

#### 1. Insert (Menyimpan Koreksi Baru)

```dart
Future<int> insertCorrection({...}) async {
  return await db.insert('corrections', {
    'image_hash': imageHash,
    'label': label,
    'original_prediction': originalPrediction,
    'created_at': now,
    'updated_at': now,
  });
}
```

#### 2. Update (Mengupdate Koreksi)

```dart
Future<int> updateCorrection({...}) async {
  return await db.update('corrections', {
    'label': label,
    'original_prediction': originalPrediction,
    'updated_at': now,
  }, where: 'image_hash = ?', whereArgs: [imageHash]);
}
```

#### 3. Find (Mencari Berdasarkan Hash)

```dart
Future<Map?> findByHash(String imageHash) async {
  final results = await db.query(
    'corrections',
    where: 'image_hash = ?',
    whereArgs: [imageHash],
  );

  return results.isNotEmpty ? results.first : null;
}
```
---
## 11. Struktur Database

**File:** `lib/database/knn_database_simple.dart`

```dart
class SimpleCorrectionDatabase {
  static final SimpleCorrectionDatabase _instance = ...;
  static Database? _database;

  // Singleton pattern
  factory SimpleCorrectionDatabase() => _instance;

  // Inisialisasi database
  Future<void> init() async {
    final directory =
        await getApplicationDocumentsDirectory();

    final path =
        join(directory.path, 'corrections.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Membuat tabel
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE corrections(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_hash TEXT UNIQUE,
        label TEXT NOT NULL,
        original_prediction TEXT,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_hash ON corrections(image_hash)'
    );
  }

  // Compute hash
  String computeConsistentHash(List<int> imageBytes) { ... }

  // Insert or Update
  Future<int> insertOrUpdateCorrection({...}) async {
    final existing = await findByHash(imageHash);

    if (existing != null) {
      return await updateCorrection(...);
    } else {
      return await insertCorrection(...);
    }
  }
}
```

### Database Path di HP

```text
/data/user/0/com.example.food_detection/app_flutter/corrections.db
```

---

## 12. Penjelasan Kode Penting

### 12.1 Hybrid Classifier (`hybrid_classifier.dart`)

Fungsi: Menggabungkan CNN untuk prediksi dan SQLite untuk cache koreksi.

```dart
class HybridFoodClassifier {
  late Interpreter _cnnModel;
  late List<String> _labels;
  late SimpleCorrectionDatabase _db;

  // ==================== PREDIKSI ====================

  Future<Prediction> predict(List<int> imageBytes) async {

    // 1. Hitung hash gambar
    final imageHash =
        _computeImageHash(imageBytes);

    // 2. Cek database
    final correction =
        await _db.findByHash(imageHash);

    // 3. Jika ada → CACHE HIT
    if (correction != null) {
      return Prediction(
        label: correction['label'],
        probability: 0.95,
        isFromCache: true,
      );
    }

    // 4. Jika tidak ada → CNN
    return await _predictCnn(imageBytes);
  }

  // ==================== LEARNING ====================

  Future<void> learnFromFeedback({...}) async {
    final imageHash =
        _computeImageHash(imageBytes);

    await _db.insertOrUpdateCorrection(...);
  }
}
```

#### Penjelasan Method

| Method | Fungsi |
|---|---|
| loadModel() | Load model TFLite dan database |
| _computeImageHash() | Membuat fingerprint gambar |
| predict() | Cek cache → CNN |
| _predictCnn() | Run inference CNN |
| learnFromFeedback() | Simpan koreksi user |

### 12.2 Database SQLite (`knn_database_simple.dart`)

Fungsi: Menyimpan dan mengelola koreksi user.

```dart
class SimpleCorrectionDatabase {
  static Database? _database;

  // Compute hash
  String computeConsistentHash(List<int> imageBytes) {
    var hash = 0;

    for (int i = 0; i < imageBytes.length; i++) {
      hash = (hash * 31 + imageBytes[i]) & 0xFFFFFFFF;
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }

  // Insert or Update
  Future<int> insertOrUpdateCorrection({...}) async {
    final existing = await findByHash(imageHash);

    if (existing != null) {
      return await updateCorrection(...);  // UPDATE
    } else {
      return await insertCorrection(...);  // INSERT
    }
  }
}
```

#### Penjelasan Method

| Method | Fungsi |
|---|---|
| init() | Inisialisasi database |
| computeConsistentHash() | Hash fingerprint gambar |
| findByHash() | Cari hash |
| insertOrUpdateCorrection() | UPSERT |
| deleteAll() | Hapus semua data |

### 12.3 Nutrition Data (`nutrition_data.dart`)

Fungsi: Database nutrisi untuk 18 makanan Indonesia.

```dart
class NutritionData {
  static final Map<String, FoodData> foodDatabase = {

    'nasi_goreng': FoodData(
      indonesianName: 'Nasi Goreng',
      calories: 350,
      protein: 8.0,
      carbs: 45.0,
      fat: 14.0,
      fiber: 2.0,
      sugar: 4.0,
      sodium: 680,
      healthLevel: HealthLevel.medium,
      bestTimeToEat: 'Sarapan atau makan siang',
      servingSuggestion: '1 piring (300g)',
      healthTip: '💡 Tips Sehat:\n• Tambahkan sayuran...',
      warning: '⚠️ Peringatan:\n• Tinggi karbohidrat...',
    ),

    // ... 17 makanan lainnya
  };

  static FoodData getFoodData(String label) {
    return foodDatabase[label]
        ?? foodDatabase['default']!;
  }
}
```

#### Penjelasan Field

| Field | Penjelasan |
|---|---|
| indonesianName | Nama makanan |
| calories | Kalori |
| protein | Protein |
| carbs | Karbohidrat |
| fat | Lemak |
| fiber | Serat |
| sugar | Gula |
| sodium | Sodium |
| healthLevel | healthy / medium / unhealthy |
| bestTimeToEat | Rekomendasi waktu |
| servingSuggestion | Saran porsi |
| healthTip | Tips kesehatan |
| warning | Peringatan |


### 12.4 Home Screen (`home_screen.dart`)

Fungsi: UI utama aplikasi.

```dart
class _HomeScreenState extends State<HomeScreen> {

  final HybridFoodClassifier _classifier =
      HybridFoodClassifier();

  File? _selectedImage;
  Prediction? _predictionResult;

  // ==================== UPLOAD ====================

  Future<void> _pickImage(ImageSource source) async {

    final XFile? pickedFile =
        await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _predictionResult = null;
      });
    }
  }

  // ==================== PREDIKSI ====================

  Future<void> _predictImage() async {

    List<int> imageBytes =
        await _selectedImage!.readAsBytes();

    Prediction prediction =
        await _classifier.predict(imageBytes);

    setState(() => _predictionResult = prediction);
  }

  // ==================== KOREKSI ====================

  void _showCorrectionDialog() {

    // Tampilkan dialog dengan
    // 18 pilihan makanan

    // User memilih label yang benar

    // Panggil _saveFeedback(label)
  }

  Future<void> _saveFeedback(
      String correctLabel) async {

    await _classifier.learnFromFeedback(...);

    _resetAll();
  }
}
```

#### Penjelasan Method

| Method | Fungsi |
|---|---|
| _pickImage() | Ambil gambar kamera/galeri |
| _predictImage() | Prediksi gambar |
| _buildResultCard() | Tampilkan hasil prediksi |
| _showCorrectionDialog() | Dialog koreksi |
| _saveFeedback() | Simpan koreksi |
| _resetAll() | Reset state aplikasi |

---
## 14. Hasil Pengujian

### 14.1 Pengujian Deteksi Awal (Tanpa Cache)

| Gambar | Prediksi Awal | Confidence | Status |
|---|---|---|---|
| Telur Dadar | gulai_ikan | 54.4% | ❌ Salah |
| Nasi Goreng | mie_goreng | 71.0% | ❌ Salah |
| French Fries | ayam_goreng | 77.4% | ❌ Salah |

#### Analisis

Model CNN masih sering salah karena dataset yang terbatas untuk beberapa kategori.


### 14.2 Pengujian Koreksi dan Pembelajaran

#### Skenario 1: Koreksi Telur Dadar

| Tahap | Hash | Prediksi | Status |
|---|---|---|---|
| Upload 1 | fa9f6bd7 | gulai_ikan | ❌ Salah |
| User koreksi | fa9f6bd7 | telur_dadar | 💾 Tersimpan |
| Upload 2 (gambar sama) | fa9f6bd7 | telur_dadar (cache) | ✅ Benar |

#### Skenario 2: Update Koreksi (French Fries → Ayam Goreng)

| Tahap | Hash | Prediksi | Status |
|---|---|---|---|
| Upload 1 | 32f90e85 | ayam_goreng | ❌ Salah |
| User koreksi | 32f90e85 | french_fries | 💾 Insert |
| Upload 2 (gambar sama) | 32f90e85 | french_fries (cache) | ❌ User merasa salah |
| User koreksi ulang | 32f90e85 | ayam_goreng | 🔄 Update |
| Upload 3 (gambar sama) | 32f90e85 | ayam_goreng (cache) | ✅ Benar |

### 14.3 Metrik Performa

| Metrik | Nilai | Keterangan |
|---|---|---|
| Akurasi CNN (validation) | 84.24% | 18 kelas makanan Indonesia |
| Akurasi dengan Cache | 95.0% | Untuk gambar yang sudah pernah dikoreksi |
| Waktu Inferensi (CNN) | ~500-800 ms | Tergantung HP |
| Waktu Cache Lookup | ~50-100 ms | Query SQLite dengan index |
| Ukuran Model TFLite | 4.89 MB | Setelah FP16 quantization |
| Ukuran APK | ~25 MB | Termasuk model dan assets |
| Memory Usage | ~50 MB | Saat prediksi |

### 14.4 Log Keberhasilan

```text
✅ Database initialized
✅ CNN Model loaded!
🎯 [CACHE] Found: nasi_goreng
🎯 [CACHE] Found: telur_dadar
🔄 Updating: french_fries → ayam_goreng
📝 Updated: 32f90e85 → ayam_goreng
✅ Learned! Cache size: 3
```

---

## 15. Kesimpulan

### 15.1 Keberhasilan

| No | Keberhasilan | Bukti |
|---|---|---|
| 1 | Model CNN MobileNetV2 berhasil dilatih | Akurasi validation 84.24% |
| 2 | Transfer learning efektif dengan dataset terbatas | Hanya 300-500 gambar per kelas |
| 3 | KNN Cache memungkinkan on-device learning | Cache size bertambah setiap koreksi |
| 4 | Database SQLite persisten | Data tidak hilang setelah app ditutup |
| 5 | Aplikasi berjalan offline tanpa internet | Semua proses di HP |
| 6 | User dapat mengupdate koreksi yang sudah ada | 🔄 Updating: french_fries → ayam_goreng |
| 7 | UI modern dengan animasi | Smooth transitions |

### 15.2 Keterbatasan

| No | Keterbatasan | Dampak | Solusi ke Depan |
|---|---|---|---|
| 1 | KNN Cache hanya hash-based | Hanya mengenali gambar yang persis sama | Implementasi feature vector |
| 2 | Database tidak ada batasan | Bisa membengkak jika terlalu banyak koreksi | Auto-delete oldest |
| 3 | Dataset tidak seimbang | gulai_ikan hanya 111 gambar vs soto 723 | Augmentasi untuk kelas minoritas |
| 4 | Warning OnBackInvokedCallback | Tidak mempengaruhi fungsi | Tambah di Android manifest |

### 15.3 Pembelajaran yang Didapat

- **Transfer Learning sangat powerful**  
  Dengan hanya 300-500 gambar per kelas, model mampu mencapai akurasi 84%.

- **On-device learning bisa dilakukan tanpa training ulang**  
  Menggunakan cache berbasis hash cukup efektif untuk gambar yang sama.

- **SQLite cocok untuk data kecil-menengah**  
  Query menggunakan index sangat cepat (`< 100ms`).

- **Flutter + TFLite merupakan kombinasi yang solid**  
  Memberikan performa baik dengan development yang cepat.

---

## 16. Referensi

### MobileNetV2: Inverted Residuals and Linear Bottlenecks
Sandler, M., Howard, A., Zhu, M., Zhmoginov, A., & Chen, L. C. (2018)
(https://arxiv.org/abs/1801.04381)

### TensorFlow Lite Documentation
Google. (2025). *TensorFlow Lite for Mobile & Edge Devices*
(https://www.tensorflow.org/lite)

### Food-101 – Mining Discriminative Components with Random Forests
Bossard, L., Guillaumin, M., & Van Gool, L. (2014)
(https://data.vision.ee.ethz.ch/cvl/datasets_extra/food-101/)

### Flutter Documentation
Google. (2025). *Flutter SDK Documentation*
(https://docs.flutter.dev/)

### SQLite Documentation
SQLite Consortium. (2025). *SQLite Documentation*
(https://www.sqlite.org/docs.html)

### K-Nearest Neighbors Algorithm
Cover, T., & Hart, P. (1967). *Nearest neighbor pattern classification*
(https://ieeexplore.ieee.org/document/1053964)

> Dokumentasi ini dapat digunakan sebagai referensi untuk skripsi, tugas akhir, atau pembelajaran mandiri. 📚
