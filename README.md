# FamilyHub

**Ailenizin Dijital Merkezi** — Flutter tabanlı dijital aile yönetim uygulaması.

## Özellikler

- **Hub (Ana Sayfa)**: Aile üyeleri, durum kartları (görevler, streak, takvim, bütçe) ve son aktiviteler
- **Organizer**: Görev yönetimi, aile takvimi, alışveriş listesi
- **Bütçe**: Harcama takibi, kategori dağılımı grafikleri
- **Aile**: Üye profilleri, davet sistemi
- **Sohbet**: Aile içi anlık mesajlaşma
- **Güvenlik**: Acil durum (SOS) butonu, konum paylaşımı
- **Ayarlar**: Koyu tema, bildirim tercihleri, aile yönetimi

## Teknolojiler

- Flutter 3.41 + Dart 3.11
- State Management: Riverpod
- Navigation: GoRouter
- UI: Material 3 + Google Fonts (Inter)
- Charts: fl_chart
- Calendar: table_calendar

## Çalıştırma

### Gereksinimler
- Flutter SDK (3.19+)
- Android SDK / Emulator (Miro önerilir)

### Kurulum

```bash
cd familyhub
flutter pub get
```

### Emulatorde Çalıştırma

```bash
# Emulatorü başlat
flutter emulators --launch Miro

# Uygulamayı yükle ve çalıştır
flutter run --device-id emulator-5554
```

> **Not**: `Masaüstü` gibi non-ASCII karakter içeren yollarda `flutter run` bazen `aapt` hatası verebilir. Bu durumda:
> ```bash
> flutter build apk --debug
> adb install build/app/outputs/flutter-apk/app-debug.apk
> adb shell am start -n com.example.familyhub/.MainActivity
> ```

### Demo Giriş Bilgileri

- **E-posta**: `aile@familyhub.com`
- **Şifre**: `123456`

## Proje Yapısı

```
lib/
├── config/           # Tema, renkler, router
├── core/             # Ortak yardımcılar
├── data/             # Veri katmanı (gelecek)
├── domain/           # Modeller ve entity'ler
├── presentation/
│   ├── providers/    # Riverpod state yönetimi
│   ├── screens/      # Tüm ekranlar
│   └── widgets/      # Ortak UI bileşenleri
├── services/         # API ve local servisler
└── main.dart
```

## Sürüm

**v1.0** — 2026-04-26
