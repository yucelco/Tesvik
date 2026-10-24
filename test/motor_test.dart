import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tesvik/core/model/destek.dart';
import 'package:tesvik/core/model/referans.dart';
import 'package:tesvik/core/motor/hesap.dart';
import 'package:tesvik/core/motor/uygunluk.dart';
import 'package:tesvik/data/saglayicilar.dart';

/// Beklenen değerler veri-modeli/hesapla.py çıktısıyla aynıdır (bugün = 2026-10-24).
void main() {
  final bugun = DateTime(2026, 10, 24);
  final ham = File('assets/veri/ornek-veri.json').readAsStringSync();
  final veri = TesvikVerisi.fromJson(jsonDecode(ham) as Map<String, dynamic>);
  final ege = turet(veri.firmalar.firstWhere((f) => f.id == 'f-ege-mobilya'), veri.referans, bugun);
  final van = turet(veri.firmalar.firstWhere((f) => f.id == 'f-van-gida'), veri.referans, bugun);

  DestekHesabi hesap(TuretilmisFirma f, String destekId) =>
      hesapla(veri.destek(destekId)!, f, veri.basvurular, senaryoBul(veri, f.firma.id, destekId), bugun);

  test('türetilen alanlar', () {
    expect((ege.olcek, ege.bolge, ege.firmaYasi), ('kucuk', 1, 12));
    expect((van.olcek, van.bolge, van.firmaYasi), ('mikro', 6, 0));
  });

  test('uygunluk', () {
    final d = {for (final x in veri.destekler) x.id: x};
    expect(uygunluk(d['tb-yurtdisi-fuar']!, ege).durum, UygunlukDurumu.uygun);
    expect(uygunluk(d['kosgeb-kobi-gelisim']!, ege).durum, UygunlukDurumu.uygun);
    expect(uygunluk(d['sanayi-bolgesel-yatirim']!, ege).durum, UygunlukDurumu.uygun);

    final fuar = uygunluk(d['tb-yurtdisi-fuar']!, van);
    expect(fuar.durum, UygunlukDurumu.uygunDegil);
    expect(fuar.nedenler, ['İhracatçı birliği üyeliği gerekli']);
    final kobi = uygunluk(d['kosgeb-kobi-gelisim']!, van);
    expect(kobi.durum, UygunlukDurumu.kismen);
    expect(kobi.nedenler, ['1 yaşından küçük firmalar için ek belge istenir']);
  });

  test('Ege Mobilya: yurt dışı fuar, hedef ülke ABD', () {
    final h = hesap(ege, 'tb-yurtdisi-fuar');
    expect([for (final s in h.satirlar) s.oran], [closeTo(0.6, 1e-9), closeTo(0.6, 1e-9), 0.5]);
    expect([for (final s in h.satirlar) s.azami], [closeTo(14400, 1e-6), 5000, 5000]);
    expect(h.toplam, closeTo(24400, 1e-6));
  });

  test('Ege Mobilya: KOSGEB, yıllık limitten önceki ödeme düşülür', () {
    final h = hesap(ege, 'kosgeb-kobi-gelisim');
    expect(h.satirlar[0].kullanilan, 40000);
    expect([for (final s in h.satirlar) s.azami], [closeTo(110000, 1e-6), closeTo(21000, 1e-6)]);
    expect(h.toplam, closeTo(131000, 1e-6));
    expect(h.tavanaTakildi, isFalse);
  });

  test('Van Gıda: KOSGEB harcama girilmeden kalan limit, 6. bölge oranı', () {
    final h = hesap(van, 'kosgeb-kobi-gelisim');
    expect(h.satirlar.every((s) => (s.oran - 0.7).abs() < 1e-9), isTrue);
    expect(h.toplam, 200000);
  });

  test('Bölgesel yatırım: limitsiz kalemler tutar üretmez, oran bölgeye göre', () {
    expect(hesap(ege, 'sanayi-bolgesel-yatirim').satirlar.first.oran, 0.15);
    final h = hesap(van, 'sanayi-bolgesel-yatirim');
    expect(h.satirlar.first.oran, 0.5);
    expect(h.satirlar.every((s) => s.azami == null), isTrue);
    expect(h.toplam, 0);
  });

  test('program tavanı toplamı sınırlar', () {
    final j = (jsonDecode(ham)['destekler'] as List).firstWhere((d) => d['id'] == 'kosgeb-kobi-gelisim');
    j['programTavani'] = {'deger': 120000, 'paraBirimi': 'TRY'};
    final h = hesapla(Destek.fromJson(j), van, const [], null, bugun);
    // Kalemler 150.000 + 50.000 = 200.000, tavan 120.000
    expect(h.toplam, 120000);
    expect(h.tavanaTakildi, isTrue);
  });

  test('NACE desenleri', () {
    expect(naceEslesir('64-66', '65.11'), isTrue);
    expect(naceEslesir('64-66', '68.10'), isFalse);
    expect(naceEslesir('31.*', '31.01'), isTrue);
    expect(naceEslesir('31', '31.01'), isTrue);
    expect(naceEslesir('31.0', '31.01'), isFalse);
    expect(naceEslesir('10.71', '10.71'), isTrue);
  });
}
