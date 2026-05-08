# Katkı Rehberi (Contributing Guide)

Bu projeye katkıda bulunmak için aşağıdaki akışı takip edin.

## Geliştirme Akışı

1. **Branch oluştur**: `main` üzerinden yeni bir branch aç
   - `feature/ozellik-adi` — Yeni özellik
   - `fix/hata-aciklamasi` — Hata düzeltmesi
   - `chore/gorev-aciklamasi` — Bakım, refactor, CI güncellemesi

2. **Değişiklik yap**: GitHub web editörü, Codespaces veya yerel ortamda kodu güncelle

3. **Push et**: Branch'i GitHub'a push et
   - Otomatik CI çalışır (`flutter analyze`, `flutter test`, `build debug APK`)

4. **PR aç**: `main` branch'e karşı Pull Request oluştur
   - CI yeşil olmadan merge edilmez
   - PR şablonunu doldur

5. **Merge**: Review ve CI başarılı olduktan sonra merge et

## Branch Kuralları

- `main` branch'e **doğrudan push yasaktır**
- Tüm değişiklikler PR üzerinden geçmelidir
- CI `analyze-and-test` job'ı başarılı olmadan merge edilemez

## Debug APK İndirme

Her push'ta CI otomatik olarak **debug APK** oluşturur. GitHub Actions sayfasından `build-debug` job'una tıklayıp artifact'ı indirebilirsiniz. Fiziksel cihazınıza yükleyip test edebilirsiniz.

## Release

Release build almak için tag push yapın:

```bash
git tag v1.1.0
git push origin v1.1.0
```

Bu işlem otomatik olarak:
- Release APK (obfuscated)
- App Bundle (AAB)
- iOS IPA (no-codesign)

oluşturur ve artifact olarak sunar.
