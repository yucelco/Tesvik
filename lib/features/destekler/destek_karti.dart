import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/bicim.dart';
import '../../data/saglayicilar.dart';
import '../ortak/ortak.dart';

class DestekKarti extends StatelessWidget {
  const DestekKarti({super.key, required this.ozet});

  final DestekOzeti ozet;

  @override
  Widget build(BuildContext context) {
    final d = ozet.destek;
    final h = ozet.hesap;
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/destekler/${d.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(d.kurum.etiket, style: t.labelMedium)),
                  if (ozet.uygunluk != null) UygunlukRozeti(ozet.uygunluk!.durum),
                ],
              ),
              const SizedBox(height: 6),
              Text(d.ad, style: t.titleMedium),
              const SizedBox(height: 6),
              Text('${d.destekTuru.etiket} · ${d.kalemler.length} kalem', style: t.bodySmall),
              if (h != null && h.tutarliKalemVar) ...[
                const SizedBox(height: 8),
                Text(
                  'Azami: ${para(h.toplam, h.paraBirimi)}',
                  style: t.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ],
              if (ozet.uygunluk?.nedenler.isNotEmpty ?? false) ...[
                const SizedBox(height: 6),
                Text(ozet.uygunluk!.nedenler.join(' · '), style: t.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
