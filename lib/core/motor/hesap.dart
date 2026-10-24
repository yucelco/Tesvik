/// Azami teşvik hesabı. Referans uygulama: veri-modeli/hesapla.py
/// (etkin, kullanilan, hesapla). Kurallar birebir aynıdır:
/// kalem azami = min(harcama × oran, üst limit − kullanılan);
/// harcama girilmemişse kalan limitin tamamı; toplam program tavanıyla sınırlı.
library;

import '../model/destek.dart';
import '../model/ortak.dart';
import '../model/takip.dart';
import 'uygunluk.dart';

class EtkinKalem {
  const EtkinKalem(this.oran, this.limit, this.rozetler);

  final double oran;
  final double? limit;
  final List<String> rozetler;
}

EtkinKalem etkin(DestekKalemi kalem, Map<String, Object?> a) {
  var oran = kalem.oran;
  var limit = kalem.ustLimit?.deger;
  final rozet = <String>[];
  for (final r in kalem.kurallar) {
    if (!kosulSaglar(r.kosul, a)) continue;
    rozet.add(r.aciklama ?? '');
    switch (r.etki) {
      case 'oranArtir':
        oran += r.deger as double;
      case 'oranBelirle':
        final d = r.deger as double;
        if (d > oran) oran = d;
      case 'limitBelirle':
        final d = (r.deger as Tutar).deger;
        if (d > (limit ?? 0)) limit = d;
      case 'limitCarp':
        if (limit != null) limit = limit * (r.deger as double);
    }
  }
  return EtkinKalem(oran > 1 ? 1 : oran, limit, rozet);
}

/// Kalemin limitinden daha önce kullanılan tutar (yıllık ya da toplam limitler için).
double kullanilan(DestekKalemi kalem, String firmaId, List<Basvuru> basvurular, int yil) {
  if (kalem.limitDonemi == LimitDonemi.faaliyetBasi || kalem.limitDonemi == LimitDonemi.projeBasi) {
    return 0;
  }
  var t = 0.0;
  for (final b in basvurular) {
    if (b.firmaId != firmaId) continue;
    for (final k in b.kalemler) {
      if (k.kalemId != kalem.id || k.odenen == null) continue;
      if (kalem.limitDonemi == LimitDonemi.toplam || k.odemeTarihi?.year == yil) {
        t += k.odenen!.deger;
      }
    }
  }
  return t;
}

class KalemSonucu {
  const KalemSonucu({
    required this.kalem,
    required this.oran,
    required this.rozetler,
    this.limit,
    this.kullanilan,
    this.harcama,
    this.azami,
  });

  final DestekKalemi kalem;
  final double oran;
  final List<String> rozetler;

  /// Üst limit yoksa (ör. vergi/SGK kalemleri) aşağıdakiler boştur.
  final double? limit;
  final double? kullanilan;
  final double? harcama;
  final double? azami;

  ParaBirimi get paraBirimi => kalem.ustLimit?.paraBirimi ?? ParaBirimi.TRY;
}

class DestekHesabi {
  const DestekHesabi(this.satirlar, this.toplam, this.paraBirimi, {this.tavanaTakildi = false});

  final List<KalemSonucu> satirlar;
  final double toplam;
  final ParaBirimi paraBirimi;
  final bool tavanaTakildi;

  bool get tutarliKalemVar => satirlar.any((s) => s.azami != null);
}

DestekHesabi hesapla(
  Destek destek,
  TuretilmisFirma firma,
  List<Basvuru> basvurular,
  Senaryo? senaryo,
  DateTime bugun,
) {
  final a = {...firma.alanlar, ...?senaryo?.faaliyet};
  final plan = {for (final k in senaryo?.kalemler ?? const <SenaryoKalemi>[]) k.kalemId: k};
  final satirlar = <KalemSonucu>[];
  var toplam = 0.0;
  ParaBirimi? birim;
  for (final kalem in destek.kalemler) {
    final e = etkin(kalem, a);
    if (e.limit == null) {
      satirlar.add(KalemSonucu(kalem: kalem, oran: e.oran, rozetler: e.rozetler));
      continue;
    }
    birim ??= kalem.ustLimit?.paraBirimi;
    final kul = kullanilan(kalem, firma.firma.id, basvurular, bugun.year);
    final kalan = e.limit! - kul < 0 ? 0.0 : e.limit! - kul;
    final harcama = plan[kalem.id]?.planlananHarcama.deger;
    final azami = harcama == null ? kalan : _min(harcama * e.oran, kalan);
    toplam += azami;
    satirlar.add(
      KalemSonucu(
        kalem: kalem,
        oran: e.oran,
        rozetler: e.rozetler,
        limit: e.limit,
        kullanilan: kul,
        harcama: harcama,
        azami: azami,
      ),
    );
  }
  var tavan = false;
  final t = destek.programTavani;
  if (t != null && toplam > t.deger) {
    toplam = t.deger;
    tavan = true;
  }
  return DestekHesabi(satirlar, toplam, birim ?? t?.paraBirimi ?? ParaBirimi.TRY, tavanaTakildi: tavan);
}

double _min(double a, double b) => a < b ? a : b;
