/// Uygunluk kuralları. Referans uygulama: veri-modeli/hesapla.py
/// (turet, kosul_saglar, nace_eslesir, uygunluk). Kurallar birebir aynıdır.
library;

import '../model/destek.dart';
import '../model/firma.dart';
import '../model/ortak.dart';
import '../model/referans.dart';

const olcekEtiketleri = {
  'mikro': 'Mikro işletme',
  'kucuk': 'Küçük işletme',
  'orta': 'Orta büyüklükte işletme',
  'buyuk': 'Büyük işletme',
};

String olcekHesapla({
  required int calisanSayisi,
  required double netSatis,
  required double bilancoToplami,
  required List<OlcekTanimi> tanim,
}) {
  final mali = netSatis < bilancoToplami ? netSatis : bilancoToplami;
  for (final t in tanim) {
    if (calisanSayisi <= t.azamiCalisan && mali <= t.azamiNetSatis) return t.olcek;
  }
  return 'buyuk';
}

int yasHesapla(DateTime kurulus, DateTime bugun) {
  final dahaGelmedi =
      bugun.month < kurulus.month || (bugun.month == kurulus.month && bugun.day < kurulus.day);
  return bugun.year - kurulus.year - (dahaGelmedi ? 1 : 0);
}

/// Firmanın koşullarda kullanılan tüm alanları (türetilmiş olanlar dahil).
class TuretilmisFirma {
  const TuretilmisFirma(this.firma, this.alanlar);

  final Firma firma;
  final Map<String, Object?> alanlar;

  String get olcek => alanlar['olcek'] as String;
  int? get bolge => alanlar['bolge'] as int?;
  int get firmaYasi => alanlar['firmaYasi'] as int;
  List<String> get naceKodlari => [for (final n in firma.naceKodlari) n.kod];

  /// Senaryodaki faaliyet alanlarını (ör. hedefUlke) ekleyerek yeni kopya döner.
  TuretilmisFirma ile(Map<String, Object?> ek) => TuretilmisFirma(firma, {...alanlar, ...ek});
}

TuretilmisFirma turet(Firma f, Referans ref, DateTime bugun) {
  return TuretilmisFirma(f, {
    'id': f.id,
    'il': f.il,
    'calisanSayisi': f.calisanSayisi,
    'netSatis': f.netSatis,
    'bilancoToplami': f.bilancoToplami,
    'ihracatUsd': f.ihracatUsd,
    'sirketTuru': f.sirketTuru.name,
    ...f.ozelDurumlar,
    'olcek': olcekHesapla(
      calisanSayisi: f.calisanSayisi,
      netSatis: f.netSatis,
      bilancoToplami: f.bilancoToplami,
      tanim: ref.olcekTanimi,
    ),
    'bolge': ref.il(f.il)?.yatirimBolgesi,
    'firmaYasi': yasHesapla(f.kurulusTarihi, bugun),
  });
}

bool kosulSaglar(Kosul k, Map<String, Object?> a) {
  final x = a[k.alan];
  final d = k.deger;
  if (x == null) return false;
  return switch (k.operator) {
    'esit' => x == d,
    'esitDegil' => x != d,
    'icinde' => (d as List).contains(x),
    'disinda' => !(d as List).contains(x),
    'buyukEsit' => (x as num) >= (d as num),
    'kucukEsit' => (x as num) <= (d as num),
    'arasinda' => (d as List)[0] as num <= (x as num) && x <= (d[1] as num),
    _ => throw ArgumentError('Bilinmeyen operatör: ${k.operator}'),
  };
}

/// [desen]: "31.01", "31.*" ya da "64-66" (bölüm aralığı).
bool naceEslesir(String desen, String kod) {
  if (desen.contains('-')) {
    final p = desen.split('-');
    final bolum = int.parse(kod.substring(0, 2));
    return int.parse(p[0]) <= bolum && bolum <= int.parse(p[1]);
  }
  final d = desen.replaceAll(RegExp(r'[.*]+$'), '');
  return kod == d || kod.startsWith('$d.');
}

/// Verilen NACE kodları desteğin NACE kurallarından geçiyor mu?
bool naceKapsaminda(Destek destek, List<String> kodlar) {
  final haric = destek.nace.where((n) => n.tip == 'haric');
  if (haric.any((n) => kodlar.any((k) => naceEslesir(n.kod, k)))) return false;
  final dahil = destek.nace.where((n) => n.tip == 'dahil').toList();
  return dahil.isEmpty || dahil.any((n) => kodlar.any((k) => naceEslesir(n.kod, k)));
}

enum UygunlukDurumu {
  uygun('Uygun'),
  kismen('Kısmen uygun'),
  uygunDegil('Uygun değil');

  const UygunlukDurumu(this.etiket);
  final String etiket;
}

class UygunlukSonucu {
  const UygunlukSonucu(this.durum, this.nedenler);

  final UygunlukDurumu durum;
  final List<String> nedenler;
}

UygunlukSonucu uygunluk(Destek destek, TuretilmisFirma f) {
  final kodlar = f.naceKodlari;
  final haric = destek.nace.where((n) => n.tip == 'haric');
  if (haric.any((n) => kodlar.any((k) => naceEslesir(n.kod, k)))) {
    return const UygunlukSonucu(UygunlukDurumu.uygunDegil, ['NACE kodu hariç listede']);
  }
  final dahil = destek.nace.where((n) => n.tip == 'dahil').toList();
  if (dahil.isNotEmpty && !dahil.any((n) => kodlar.any((k) => naceEslesir(n.kod, k)))) {
    return const UygunlukSonucu(UygunlukDurumu.uygunDegil, ['NACE kodu kapsamda değil']);
  }
  final eksik = destek.kosullar.where((k) => !kosulSaglar(k, f.alanlar)).toList();
  final mesajlar = [for (final k in eksik) k.mesaj ?? k.alan];
  if (eksik.any((k) => k.zorunlu)) return UygunlukSonucu(UygunlukDurumu.uygunDegil, mesajlar);
  if (eksik.isNotEmpty) return UygunlukSonucu(UygunlukDurumu.kismen, mesajlar);
  return const UygunlukSonucu(UygunlukDurumu.uygun, []);
}
