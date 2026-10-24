import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/model/referans.dart';
import '../../core/motor/uygunluk.dart';
import '../../data/saglayicilar.dart';

/// Veri yüklenene kadar bekleme, hata olursa mesaj gösterir.
class VeriBekle extends ConsumerWidget {
  const VeriBekle({super.key, required this.builder});

  final Widget Function(BuildContext context, TesvikVerisi veri) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(veriProvider)
        .when(
          data: (v) => builder(context, v),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => BosDurum(ikon: Icons.error_outline, baslik: 'Veri yüklenemedi', aciklama: '$e'),
        );
  }
}

class BosDurum extends StatelessWidget {
  const BosDurum({super.key, required this.ikon, required this.baslik, this.aciklama, this.eylem});

  final IconData ikon;
  final String baslik;
  final String? aciklama;
  final Widget? eylem;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(baslik, style: t.titleMedium, textAlign: TextAlign.center),
            if (aciklama != null) ...[
              const SizedBox(height: 8),
              Text(aciklama!, style: t.bodyMedium, textAlign: TextAlign.center),
            ],
            if (eylem != null) ...[const SizedBox(height: 16), eylem!],
          ],
        ),
      ),
    );
  }
}

/// Henüz yapılmamış ekranlar için.
class YerTutucu extends StatelessWidget {
  const YerTutucu({super.key, required this.baslik, required this.aciklama});

  final String baslik;
  final String aciklama;

  @override
  Widget build(BuildContext context) =>
      BosDurum(ikon: Icons.construction_outlined, baslik: baslik, aciklama: aciklama);
}

class UygunlukRozeti extends StatelessWidget {
  const UygunlukRozeti(this.durum, {super.key});

  final UygunlukDurumu durum;

  @override
  Widget build(BuildContext context) {
    final r = Theme.of(context).colorScheme;
    final (arka, on, ikon) = switch (durum) {
      UygunlukDurumu.uygun => (r.primaryContainer, r.onPrimaryContainer, Icons.check_circle),
      UygunlukDurumu.kismen => (r.tertiaryContainer, r.onTertiaryContainer, Icons.info),
      UygunlukDurumu.uygunDegil => (r.errorContainer, r.onErrorContainer, Icons.cancel),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: arka, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 14, color: on),
          const SizedBox(width: 4),
          Text(
            durum.etiket,
            style: TextStyle(color: on, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Yerel kipte ve doğrulanmamış veride kullanıcıyı uyarır.
class OrnekVeriBandi extends ConsumerWidget {
  const OrnekVeriBandi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(depoProvider).yerel) return const SizedBox.shrink();
    final r = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: r.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'Örnek veri gösteriliyor. Tutarlar ve koşullar resmi kaynaklardan doğrulanmadı.',
        style: TextStyle(color: r.onSecondaryContainer, fontSize: 12),
      ),
    );
  }
}
