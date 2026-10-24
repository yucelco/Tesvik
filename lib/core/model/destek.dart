// Enum adları veri modelindeki JSON değerleriyle aynı tutulur.
// ignore_for_file: constant_identifier_names

import 'ortak.dart';

enum Kurum {
  KOSGEB('KOSGEB'),
  TICARET('Ticaret Bakanlığı'),
  SANAYI('Sanayi ve Teknoloji Bakanlığı'),
  KALKINMA_AJANSI('Kalkınma Ajansı'),
  DIGER('Diğer');

  const Kurum(this.etiket);
  final String etiket;
}

enum DestekTuru {
  hibe('Hibe'),
  geriOdemeli('Geri ödemeli'),
  faizDestegi('Faiz desteği'),
  vergiSgk('Vergi / SGK');

  const DestekTuru(this.etiket);
  final String etiket;
}

const konuEtiketleri = {
  'fuar': 'Fuar',
  'ihracat': 'İhracat',
  'yatirim': 'Yatırım',
  'arge': 'Ar-Ge',
  'istihdam': 'İstihdam',
  'dijital': 'Dijital',
  'danismanlik': 'Danışmanlık',
  'tasarimMarka': 'Tasarım / Marka',
};

enum LimitDonemi {
  faaliyetBasi('Faaliyet başına'),
  yillik('Yıllık'),
  projeBasi('Proje başına'),
  toplam('Toplam');

  const LimitDonemi(this.etiket);
  final String etiket;
}

class BasvuruDonemi {
  const BasvuruDonemi({required this.tip, this.baslangic, this.bitis, this.sonBasvuruKurali});

  /// surekli | donemsel | kapali
  final String tip;
  final DateTime? baslangic;
  final DateTime? bitis;
  final String? sonBasvuruKurali;

  factory BasvuruDonemi.fromJson(Map<String, dynamic> j) => BasvuruDonemi(
    tip: j['tip'] as String,
    baslangic: tarihOku(j['baslangic']),
    bitis: tarihOku(j['bitis']),
    sonBasvuruKurali: j['sonBasvuruKurali'] as String?,
  );
}

class DestekNace {
  const DestekNace(this.kod, this.tip);

  /// "31.01", "31.*" ya da "64-66" biçiminde desen.
  final String kod;

  /// dahil | haric
  final String tip;

  factory DestekNace.fromJson(Map<String, dynamic> j) => DestekNace(j['kod'] as String, j['tip'] as String);
}

class KalemKurali {
  const KalemKurali({required this.kosul, required this.etki, required this.deger, this.aciklama});

  final Kosul kosul;

  /// oranArtir | oranBelirle | limitBelirle | limitCarp
  final String etki;

  /// Sayı ya da [Tutar].
  final Object deger;
  final String? aciklama;

  factory KalemKurali.fromJson(Map<String, dynamic> j) {
    final d = j['deger'];
    return KalemKurali(
      kosul: Kosul.fromJson(Map<String, dynamic>.from(j['kosul'] as Map)),
      etki: j['etki'] as String,
      deger: d is Map ? Tutar.fromJson(Map<String, dynamic>.from(d)) : (d as num).toDouble(),
      aciklama: j['aciklama'] as String?,
    );
  }
}

class DestekKalemi {
  const DestekKalemi({
    required this.id,
    required this.ad,
    required this.oran,
    required this.limitDonemi,
    this.ustLimit,
    this.sure,
    this.kurallar = const [],
  });

  final String id;
  final String ad;
  final double oran;
  final Tutar? ustLimit;
  final LimitDonemi limitDonemi;
  final String? sure;
  final List<KalemKurali> kurallar;

  factory DestekKalemi.fromJson(Map<String, dynamic> j) => DestekKalemi(
    id: j['id'] as String,
    ad: j['ad'] as String,
    oran: (j['oran'] as num).toDouble(),
    ustLimit: j['ustLimit'] == null ? null : Tutar.fromJson(Map<String, dynamic>.from(j['ustLimit'] as Map)),
    limitDonemi: LimitDonemi.values.byName(j['limitDonemi'] as String),
    sure: j['sure'] as String?,
    kurallar: listeOku(j['kurallar'], KalemKurali.fromJson),
  );
}

class Destek {
  const Destek({
    required this.id,
    required this.ad,
    required this.kurum,
    required this.destekTuru,
    required this.basvuruDonemi,
    required this.kalemler,
    required this.kaynakUrl,
    required this.guncellemeTarihi,
    required this.surum,
    this.konular = const [],
    this.mevzuat,
    this.programTavani,
    this.kosullar = const [],
    this.nace = const [],
    this.belgeler = const [],
    this.dogrulandi = false,
  });

  final String id;
  final String ad;
  final Kurum kurum;
  final DestekTuru destekTuru;
  final List<String> konular;
  final String? mevzuat;
  final BasvuruDonemi basvuruDonemi;
  final Tutar? programTavani;
  final List<Kosul> kosullar;
  final List<DestekNace> nace;
  final List<DestekKalemi> kalemler;
  final List<String> belgeler;
  final String kaynakUrl;
  final DateTime guncellemeTarihi;
  final bool dogrulandi;
  final int surum;

  factory Destek.fromJson(Map<String, dynamic> j) => Destek(
    id: j['id'] as String,
    ad: j['ad'] as String,
    kurum: Kurum.values.byName(j['kurum'] as String),
    destekTuru: DestekTuru.values.byName(j['destekTuru'] as String),
    konular: List<String>.from(j['konular'] as List? ?? const []),
    mevzuat: j['mevzuat'] as String?,
    basvuruDonemi: BasvuruDonemi.fromJson(Map<String, dynamic>.from(j['basvuruDonemi'] as Map)),
    programTavani: j['programTavani'] == null
        ? null
        : Tutar.fromJson(Map<String, dynamic>.from(j['programTavani'] as Map)),
    kosullar: listeOku(j['kosullar'], Kosul.fromJson),
    nace: listeOku(j['nace'], DestekNace.fromJson),
    kalemler: listeOku(j['kalemler'], DestekKalemi.fromJson),
    belgeler: List<String>.from(j['belgeler'] as List? ?? const []),
    kaynakUrl: j['kaynakUrl'] as String,
    guncellemeTarihi: DateTime.parse(j['guncellemeTarihi'] as String),
    dogrulandi: j['dogrulandi'] as bool? ?? false,
    surum: j['surum'] as int,
  );

  DestekKalemi? kalem(String id) {
    for (final k in kalemler) {
      if (k.id == id) return k;
    }
    return null;
  }
}
