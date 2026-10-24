import 'ortak.dart';

enum BasvuruDurumu {
  hazirlaniyor('Hazırlanıyor'),
  basvuruldu('Başvuruldu'),
  onaylandi('Onaylandı'),
  odemeAlindi('Ödeme alındı'),
  reddedildi('Reddedildi');

  const BasvuruDurumu(this.etiket);
  final String etiket;
}

class BasvuruKalemi {
  const BasvuruKalemi({required this.kalemId, this.talepEdilen, this.odenen, this.odemeTarihi});

  final String kalemId;
  final Tutar? talepEdilen;
  final Tutar? odenen;
  final DateTime? odemeTarihi;

  factory BasvuruKalemi.fromJson(Map<String, dynamic> j) => BasvuruKalemi(
    kalemId: j['kalemId'] as String,
    talepEdilen: j['talepEdilen'] == null
        ? null
        : Tutar.fromJson(Map<String, dynamic>.from(j['talepEdilen'] as Map)),
    odenen: j['odenen'] == null ? null : Tutar.fromJson(Map<String, dynamic>.from(j['odenen'] as Map)),
    odemeTarihi: tarihOku(j['odemeTarihi']),
  );
}

class Basvuru {
  const Basvuru({
    required this.id,
    required this.firmaId,
    required this.destekId,
    required this.durum,
    this.kalemler = const [],
  });

  final String id;
  final String firmaId;
  final String destekId;
  final BasvuruDurumu durum;
  final List<BasvuruKalemi> kalemler;

  factory Basvuru.fromJson(Map<String, dynamic> j) => Basvuru(
    id: j['id'] as String,
    firmaId: j['firmaId'] as String,
    destekId: j['destekId'] as String,
    durum: BasvuruDurumu.values.byName(j['durum'] as String),
    kalemler: listeOku(j['kalemler'], BasvuruKalemi.fromJson),
  );
}

class SenaryoKalemi {
  const SenaryoKalemi(this.kalemId, this.planlananHarcama);

  final String kalemId;
  final Tutar planlananHarcama;

  factory SenaryoKalemi.fromJson(Map<String, dynamic> j) => SenaryoKalemi(
    j['kalemId'] as String,
    Tutar.fromJson(Map<String, dynamic>.from(j['planlananHarcama'] as Map)),
  );
}

/// Bir destek için planlanan harcamalar ve faaliyete bağlı alanlar (ör. hedef ülke).
class Senaryo {
  const Senaryo({
    required this.id,
    required this.firmaId,
    required this.destekId,
    required this.ad,
    this.kalemler = const [],
    this.faaliyet = const {},
  });

  final String id;
  final String firmaId;
  final String destekId;
  final String ad;
  final List<SenaryoKalemi> kalemler;
  final Map<String, Object?> faaliyet;

  factory Senaryo.fromJson(Map<String, dynamic> j) => Senaryo(
    id: j['id'] as String,
    firmaId: j['firmaId'] as String,
    destekId: j['destekId'] as String,
    ad: j['ad'] as String,
    kalemler: listeOku(j['kalemler'], SenaryoKalemi.fromJson),
    faaliyet: Map<String, Object?>.from(j['faaliyet'] as Map? ?? const {}),
  );
}
