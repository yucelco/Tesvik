import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/saglayicilar.dart';
import '../ortak/ortak.dart';

/// Başvuru takibi. İlk sürümde yalnızca kayıtlı başvurular listelenir;
/// belge listesi, durum güncelleme ve hatırlatmalar sonraki adımda.
class TakipEkrani extends ConsumerWidget {
  const TakipEkrani({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Başvuru takibi')),
      body: VeriBekle(
        builder: (context, veri) {
          final firma = ref.watch(seciliFirmaProvider);
          final basvurular = veri.basvurular.where((b) => b.firmaId == firma?.firma.id).toList();
          if (basvurular.isEmpty) {
            return const YerTutucu(
              baslik: 'Başvuru takibi yakında',
              aciklama: 'Başvuru durumları, belge kontrol listesi ve son tarih hatırlatmaları burada olacak.',
            );
          }
          return ListView(
            children: [
              for (final b in basvurular)
                Card(
                  child: ListTile(
                    title: Text(veri.destek(b.destekId)?.ad ?? b.destekId),
                    subtitle: Text(b.durum.etiket),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Belge listesi ve hatırlatmalar sonraki sürümde eklenecek.'),
              ),
            ],
          );
        },
      ),
    );
  }
}
