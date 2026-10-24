import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/model/ortak.dart';
import '../../core/motor/uygunluk.dart';
import '../../core/ui/bicim.dart';
import '../../data/saglayicilar.dart';
import '../destekler/destek_karti.dart';
import '../ortak/ortak.dart';

class AnaSayfaEkrani extends ConsumerWidget {
  const AnaSayfaEkrani({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teşvik Rehberi')),
      body: VeriBekle(
        builder: (context, veri) {
          final firma = ref.watch(seciliFirmaProvider);
          if (firma == null) {
            return BosDurum(
              ikon: Icons.business_outlined,
              baslik: 'Önce firmanızı ekleyin',
              aciklama:
                  'Firma bilgilerinize göre yararlanabileceğiniz destekleri ve azami tutarları gösterelim.',
              eylem: FilledButton.icon(
                onPressed: () => context.push('/firma/yeni'),
                icon: const Icon(Icons.add),
                label: const Text('Firma ekle'),
              ),
            );
          }
          final ozetler = ref.watch(destekOzetleriProvider);
          final uygun = ozetler.where((o) => o.uygunluk?.durum == UygunlukDurumu.uygun).length;
          final kismen = ozetler.where((o) => o.uygunluk?.durum == UygunlukDurumu.kismen).length;
          final toplamlar = <ParaBirimi, double>{};
          for (final o in ozetler) {
            final h = o.hesap;
            if (h == null || !h.tutarliKalemVar) continue;
            toplamlar[h.paraBirimi] = (toplamlar[h.paraBirimi] ?? 0) + h.toplam;
          }
          final il = veri.referans.il(firma.firma.il);
          final t = Theme.of(context).textTheme;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const OrnekVeriBandi(),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(firma.firma.unvan, style: t.titleMedium),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(olcekEtiketleri[firma.olcek] ?? firma.olcek)),
                        if (il != null) Chip(label: Text('${il.ad} · ${il.yatirimBolgesi}. bölge')),
                        Chip(label: Text('${firma.firmaYasi} yaşında')),
                        for (final n in firma.firma.naceKodlari) Chip(label: Text('NACE ${n.kod}')),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Firmayı değiştir',
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () => context.go('/firmalar'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _Sayac(deger: '$uygun', etiket: 'Uygun destek'),
                    ),
                    Expanded(
                      child: _Sayac(deger: '$kismen', etiket: 'Kısmen uygun'),
                    ),
                  ],
                ),
              ),
              if (toplamlar.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alınabilecek azami destek', style: t.labelLarge),
                        const SizedBox(height: 8),
                        for (final e in toplamlar.entries) Text(para(e.value, e.key), style: t.headlineSmall),
                        const SizedBox(height: 4),
                        Text('Planlanan harcama ve önceki ödemeler hesaba katıldı.', style: t.bodySmall),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Expanded(child: Text('Size uygun destekler', style: t.titleMedium)),
                    TextButton(onPressed: () => context.go('/destekler'), child: const Text('Tümü')),
                  ],
                ),
              ),
              for (final o in ozetler.where((o) => o.uygunluk?.durum != UygunlukDurumu.uygunDegil).take(3))
                DestekKarti(ozet: o),
            ],
          );
        },
      ),
    );
  }
}

class _Sayac extends StatelessWidget {
  const _Sayac({required this.deger, required this.etiket});

  final String deger;
  final String etiket;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(deger, style: t.headlineMedium),
            Text(etiket, style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}
