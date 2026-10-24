# Teşvik Rehberi

Firmaların şirket bilgilerine göre yararlanabileceği devlet desteklerini gösteren Android uygulaması (Flutter).

- Firma profili (ölçek, il / yatırım bölgesi, yaş, özel durumlar ve NACE kodları) girilir.
- Destekler firmaya göre **Uygun / Kısmen uygun / Uygun değil** olarak işaretlenir; kurum, konu ve NACE koduna göre filtrelenir.
- Her destek kalemi için planlanan harcama girilir; **azami tutar = min(harcama × oran, üst limit − kullanılan)**, toplam program tavanıyla sınırlanır.

## Çalıştırma

```sh
flutter pub get
flutter test
flutter run
```

Firebase yapılandırması yoksa uygulama `assets/veri/` altındaki örnek veriyle **yerel kipte** açılır ve ekranda "örnek veri" uyarısı gösterilir.

## Klasör yapısı

```
lib/
  core/
    model/     veri modeli (tesvik.schema.json v1 ile aynı alanlar)
    motor/     uygunluk.dart, hesap.dart (referans: veri-modeli/hesapla.py)
    ui/        tema, para / tarih biçimleri
    router.dart
  data/        depo.dart (YerelDepo, FirestoreDepo), saglayicilar.dart (Riverpod)
  features/
    kabuk/       4 sekmeli alt menü
    ana_sayfa/   seçili firma özeti, azami destek toplamı
    destekler/   liste + filtreler, destek detayı
    hesap/       azami teşvik hesabı
    firma/       firmalarım, 4 adımlı firma sihirbazı
    nace/        NACE kodu arama ve seçimi
    takip/       başvuru takibi (iskelet)
assets/veri/   ornek-veri.json, iller.json (81 il, yatırım bölgesi), nace.json
test/          hesap motoru ve ekran testleri
```

## Firebase bağlantısı

1. Firebase konsolunda proje oluşturun, Android uygulaması ekleyin (paket adı `tr.com.izfas.tesvik`).
2. `flutterfire configure` çalıştırın ya da `google-services.json` dosyasını `android/app/` altına koyup Google Services Gradle eklentisini ekleyin.
3. Authentication'da **Anonim** girişi açın.
4. Firestore kurallarını `firestore.rules` dosyasından yükleyin.

Koleksiyonlar: `destekler`, `firmalar` (sahipUid), `basvurular`, `senaryolar` (firmaId) ve `referans/v1` belgesi (iller, olcekTanimi, kur). Alan adları `ornek-veri.json` ile aynıdır.

## Bilinen eksikler

- Destek verisi örnektir ve resmi kaynaklardan doğrulanmadı (`dogrulandi: false`).
- Yatırım bölgeleri 2012/3305 sayılı karara göre girildi, güncel kararla doğrulanmalı.
- NACE listesi bölüm düzeyinde ve birkaç örnek alt sınıf içeriyor.
- Yerel kipte eklenen firmalar uygulama kapanınca kaybolur.
- Başvuru takibi, harcama planı kaydetme, bildirimler ve Play imzalama ayarı sonraki adımlar.
