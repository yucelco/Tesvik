import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/model/destek.dart';
import '../core/model/firma.dart';
import '../core/model/referans.dart';
import '../core/model/takip.dart';
import '../core/motor/hesap.dart';
import '../core/motor/uygunluk.dart';
import 'depo.dart';

/// main() içinde Firebase durumuna göre geçersiz kılınır.
final depoProvider = Provider<TesvikDeposu>((ref) => YerelDepo());

final bugunProvider = Provider<DateTime>((ref) => DateTime.now());

final veriProvider = FutureProvider<TesvikVerisi>((ref) => ref.watch(depoProvider).yukle());

class FirmalarNotifier extends AsyncNotifier<List<Firma>> {
  @override
  Future<List<Firma>> build() async => (await ref.watch(veriProvider.future)).firmalar;

  Future<void> kaydet(Firma firma) async {
    final mevcut = [...?state.value];
    final i = mevcut.indexWhere((f) => f.id == firma.id);
    if (i >= 0) {
      mevcut[i] = firma;
    } else {
      mevcut.add(firma);
    }
    state = AsyncData(mevcut);
    await ref.read(depoProvider).firmaKaydet(firma);
  }
}

final firmalarProvider = AsyncNotifierProvider<FirmalarNotifier, List<Firma>>(FirmalarNotifier.new);

class SeciliFirmaId extends Notifier<String?> {
  @override
  String? build() => null;

  void sec(String? id) => state = id;
}

final seciliFirmaIdProvider = NotifierProvider<SeciliFirmaId, String?>(SeciliFirmaId.new);

/// Seçili firma; seçim yapılmadıysa listedeki ilk firma.
final seciliFirmaProvider = Provider<TuretilmisFirma?>((ref) {
  final veri = ref.watch(veriProvider).value;
  final firmalar = ref.watch(firmalarProvider).value;
  if (veri == null || firmalar == null || firmalar.isEmpty) return null;
  final id = ref.watch(seciliFirmaIdProvider);
  final f = firmalar.firstWhere((f) => f.id == id, orElse: () => firmalar.first);
  return turet(f, veri.referans, ref.watch(bugunProvider));
});

class DestekOzeti {
  const DestekOzeti(this.destek, this.uygunluk, this.hesap);

  final Destek destek;

  /// Firma seçili değilse boştur.
  final UygunlukSonucu? uygunluk;
  final DestekHesabi? hesap;
}

/// Firma ve destek için kayıtlı ilk senaryo (planlanan harcamalar).
Senaryo? senaryoBul(TesvikVerisi veri, String firmaId, String destekId) {
  for (final s in veri.senaryolar) {
    if (s.firmaId == firmaId && s.destekId == destekId) return s;
  }
  return null;
}

/// Tüm destekler; seçili firmaya göre uygunluk ve azami tutar ile, uygun olanlar önde.
final destekOzetleriProvider = Provider<List<DestekOzeti>>((ref) {
  final veri = ref.watch(veriProvider).value;
  if (veri == null) return const [];
  final firma = ref.watch(seciliFirmaProvider);
  final bugun = ref.watch(bugunProvider);
  final liste = [
    for (final d in veri.destekler)
      if (firma == null)
        DestekOzeti(d, null, null)
      else
        () {
          final u = uygunluk(d, firma);
          final h = u.durum == UygunlukDurumu.uygunDegil
              ? null
              : hesapla(d, firma, veri.basvurular, senaryoBul(veri, firma.firma.id, d.id), bugun);
          return DestekOzeti(d, u, h);
        }(),
  ];
  liste.sort((a, b) => (a.uygunluk?.durum.index ?? 0).compareTo(b.uygunluk?.durum.index ?? 0));
  return liste;
});
