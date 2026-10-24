import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/saglayicilar.dart';
import '../ortak/ortak.dart';

class FirmalarimEkrani extends ConsumerWidget {
  const FirmalarimEkrani({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secili = ref.watch(seciliFirmaProvider)?.firma.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Firmalarım')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/firma/yeni'),
        icon: const Icon(Icons.add),
        label: const Text('Firma ekle'),
      ),
      body: VeriBekle(
        builder: (context, veri) {
          final firmalar = ref.watch(firmalarProvider).value ?? const [];
          if (firmalar.isEmpty) {
            return const BosDurum(
              ikon: Icons.business_outlined,
              baslik: 'Henüz firma yok',
              aciklama: 'Birden çok firma ekleyip aralarında geçiş yapabilirsiniz.',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              for (final f in firmalar)
                Card(
                  child: ListTile(
                    leading: Icon(f.id == secili ? Icons.radio_button_checked : Icons.radio_button_off),
                    title: Text(f.unvan),
                    subtitle: Text(
                      [
                        veri.referans.il(f.il)?.ad ?? 'İl ${f.il}',
                        f.sirketTuru.etiket,
                        'NACE ${f.naceKodlari.map((n) => n.kod).join(', ')}',
                      ].join(' · '),
                    ),
                    trailing: IconButton(
                      tooltip: 'Düzenle',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push('/firma/${f.id}/duzenle'),
                    ),
                    onTap: () => ref.read(seciliFirmaIdProvider.notifier).sec(f.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
