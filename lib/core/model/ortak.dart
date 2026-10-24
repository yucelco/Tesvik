/// Veri modelindeki (tesvik.schema.json v1) ortak tipler.
/// Enum adları JSON değerleriyle aynı tutulur.
// ignore_for_file: constant_identifier_names
library;

enum ParaBirimi { TRY, USD, EUR }

class Tutar {
  const Tutar(this.deger, this.paraBirimi);

  final double deger;
  final ParaBirimi paraBirimi;

  factory Tutar.fromJson(Map<String, dynamic> j) =>
      Tutar((j['deger'] as num).toDouble(), ParaBirimi.values.byName(j['paraBirimi'] as String));

  Map<String, dynamic> toJson() => {'deger': deger, 'paraBirimi': paraBirimi.name};
}

/// Firma alanları üzerinde tek bir koşul. [alan] firma alanının adıdır
/// (olcek, bolge, firmaYasi, kadinGirisimci, hedefUlke ...).
class Kosul {
  const Kosul({
    required this.alan,
    required this.operator,
    required this.deger,
    this.zorunlu = true,
    this.mesaj,
  });

  final String alan;
  final String operator;
  final Object? deger;
  final bool zorunlu;
  final String? mesaj;

  factory Kosul.fromJson(Map<String, dynamic> j) => Kosul(
    alan: j['alan'] as String,
    operator: j['operator'] as String,
    deger: j['deger'],
    zorunlu: j['zorunlu'] as bool? ?? true,
    mesaj: j['mesaj'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'alan': alan,
    'operator': operator,
    'deger': deger,
    'zorunlu': zorunlu,
    if (mesaj != null) 'mesaj': mesaj,
  };
}

List<T> listeOku<T>(Object? j, T Function(Map<String, dynamic>) cevir) =>
    ((j as List?) ?? const []).map((e) => cevir(Map<String, dynamic>.from(e as Map))).toList();

DateTime? tarihOku(Object? j) => j == null ? null : DateTime.parse(j as String);

String tarihYaz(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
