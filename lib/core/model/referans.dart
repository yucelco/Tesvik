import 'destek.dart';
import 'firma.dart';
import 'ortak.dart';
import 'takip.dart';

class Il {
  const Il(this.plaka, this.ad, this.yatirimBolgesi);

  final int plaka;
  final String ad;
  final int yatirimBolgesi;

  factory Il.fromJson(Map<String, dynamic> j) =>
      Il(j['plaka'] as int, j['ad'] as String, j['yatirimBolgesi'] as int);
}

class OlcekTanimi {
  const OlcekTanimi(this.olcek, this.azamiCalisan, this.azamiNetSatis, this.azamiBilanco);

  final String olcek;
  final int azamiCalisan;
  final double azamiNetSatis;
  final double azamiBilanco;

  factory OlcekTanimi.fromJson(Map<String, dynamic> j) => OlcekTanimi(
    j['olcek'] as String,
    j['azamiCalisan'] as int,
    (j['azamiNetSatis'] as num).toDouble(),
    (j['azamiBilanco'] as num).toDouble(),
  );
}

class NaceKodu {
  const NaceKodu(this.kod, this.ad);

  final String kod;
  final String ad;

  factory NaceKodu.fromJson(Map<String, dynamic> j) => NaceKodu(j['kod'] as String, j['ad'] as String);
}

class Referans {
  const Referans({required this.iller, required this.olcekTanimi, required this.kur, this.kurTarihi});

  final List<Il> iller;
  final List<OlcekTanimi> olcekTanimi;

  /// 1 birim dövizin TL karşılığı.
  final Map<ParaBirimi, double> kur;
  final DateTime? kurTarihi;

  factory Referans.fromJson(Map<String, dynamic> j) {
    final k = Map<String, dynamic>.from(j['kur'] as Map? ?? const {});
    return Referans(
      iller: listeOku(j['iller'], Il.fromJson),
      olcekTanimi: listeOku(j['olcekTanimi'], OlcekTanimi.fromJson),
      kur: {
        ParaBirimi.TRY: 1,
        for (final p in [ParaBirimi.USD, ParaBirimi.EUR])
          if (k[p.name] != null) p: (k[p.name] as num).toDouble(),
      },
      kurTarihi: tarihOku(k['tarih']),
    );
  }

  Il? il(int plaka) {
    for (final i in iller) {
      if (i.plaka == plaka) return i;
    }
    return null;
  }

  double tlKarsiligi(Tutar t) => t.deger * (kur[t.paraBirimi] ?? 1);
}

/// Uygulamanın tek seferde yüklediği tüm veri.
class TesvikVerisi {
  const TesvikVerisi({
    required this.destekler,
    required this.firmalar,
    required this.basvurular,
    required this.senaryolar,
    required this.referans,
    required this.naceKodlari,
  });

  final List<Destek> destekler;
  final List<Firma> firmalar;
  final List<Basvuru> basvurular;
  final List<Senaryo> senaryolar;
  final Referans referans;
  final List<NaceKodu> naceKodlari;

  factory TesvikVerisi.fromJson(Map<String, dynamic> j, {List<NaceKodu> naceKodlari = const []}) =>
      TesvikVerisi(
        destekler: listeOku(j['destekler'], Destek.fromJson),
        firmalar: listeOku(j['firmalar'], Firma.fromJson),
        basvurular: listeOku(j['basvurular'], Basvuru.fromJson),
        senaryolar: listeOku(j['senaryolar'], Senaryo.fromJson),
        referans: Referans.fromJson(Map<String, dynamic>.from(j['referans'] as Map)),
        naceKodlari: naceKodlari,
      );

  Destek? destek(String id) {
    for (final d in destekler) {
      if (d.id == id) return d;
    }
    return null;
  }
}
