import 'ortak.dart';

enum SirketTuru {
  sahis('Şahıs şirketi'),
  ltd('Limited şirket'),
  as('Anonim şirket'),
  kooperatif('Kooperatif'),
  diger('Diğer');

  const SirketTuru(this.etiket);
  final String etiket;
}

/// Firmanın işaretleyebileceği özel durumlar; anahtarlar koşul alan adlarıdır.
const ozelDurumEtiketleri = {
  'ihracatciBirligiUyesi': 'İhracatçı birliği üyesi',
  'kadinGirisimci': 'Kadın girişimci',
  'gencGirisimci': 'Genç girişimci',
  'engelliGirisimci': 'Engelli girişimci',
  'argeMerkezi': 'Ar-Ge / tasarım merkezi',
  'osbTeknopark': 'OSB veya teknopark içinde',
};

class FirmaNace {
  const FirmaNace(this.kod, {this.anaKod = false});

  final String kod;
  final bool anaKod;

  factory FirmaNace.fromJson(Map<String, dynamic> j) =>
      FirmaNace(j['kod'] as String, anaKod: j['anaKod'] as bool? ?? false);

  Map<String, dynamic> toJson() => {'kod': kod, 'anaKod': anaKod};
}

class Firma {
  const Firma({
    required this.id,
    required this.sahipUid,
    required this.unvan,
    required this.sirketTuru,
    required this.il,
    required this.kurulusTarihi,
    required this.calisanSayisi,
    required this.netSatis,
    required this.bilancoToplami,
    required this.naceKodlari,
    this.vkn,
    this.ilce,
    this.ihracatUsd = 0,
    this.ozelDurumlar = const {},
  });

  final String id;
  final String sahipUid;
  final String unvan;
  final String? vkn;
  final SirketTuru sirketTuru;

  /// Plaka kodu.
  final int il;
  final String? ilce;
  final DateTime kurulusTarihi;
  final int calisanSayisi;
  final double netSatis;
  final double bilancoToplami;
  final double ihracatUsd;
  final Map<String, bool> ozelDurumlar;
  final List<FirmaNace> naceKodlari;

  factory Firma.fromJson(Map<String, dynamic> j) => Firma(
    id: j['id'] as String,
    sahipUid: j['sahipUid'] as String,
    unvan: j['unvan'] as String,
    vkn: j['vkn'] as String?,
    sirketTuru: SirketTuru.values.byName(j['sirketTuru'] as String),
    il: j['il'] as int,
    ilce: j['ilce'] as String?,
    kurulusTarihi: DateTime.parse(j['kurulusTarihi'] as String),
    calisanSayisi: j['calisanSayisi'] as int,
    netSatis: (j['netSatis'] as num).toDouble(),
    bilancoToplami: (j['bilancoToplami'] as num).toDouble(),
    ihracatUsd: (j['ihracatUsd'] as num?)?.toDouble() ?? 0,
    ozelDurumlar: Map<String, bool>.from(j['ozelDurumlar'] as Map? ?? const {}),
    naceKodlari: listeOku(j['naceKodlari'], FirmaNace.fromJson),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sahipUid': sahipUid,
    'unvan': unvan,
    if (vkn != null) 'vkn': vkn,
    'sirketTuru': sirketTuru.name,
    'il': il,
    if (ilce != null) 'ilce': ilce,
    'kurulusTarihi': tarihYaz(kurulusTarihi),
    'calisanSayisi': calisanSayisi,
    'netSatis': netSatis,
    'bilancoToplami': bilancoToplami,
    'ihracatUsd': ihracatUsd,
    'ozelDurumlar': ozelDurumlar,
    'naceKodlari': naceKodlari.map((n) => n.toJson()).toList(),
  };
}
