import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/model/destek.dart';
import '../../core/model/ortak.dart';
import '../../core/motor/hesap.dart';
import '../../core/motor/uygunluk.dart';
import '../../core/ui/bicim.dart';
import '../../data/saglayicilar.dart';
import '../ortak/ortak.dart';

const _alanEtiketleri = {
  'olcek': 'Ölçek',
  'il': 'İl',
  'bolge': 'Yatırım bölgesi',
  'firmaYasi': 'Firma yaşı',
  'calisanSayisi': 'Çalışan sayısı',
  'netSatis': 'Net satış',
  'ihracatUsd': 'İhracat (USD)',
  'sirketTuru': 'Şirket türü',
  'hedefUlke': 'Hedef ülke',
};

String kosulMetni(Kosul k) {
  final alan = _alanEtiketleri[k.alan] ?? k.alan;
  final d = k.deger is List ? (k.deger as List).join(', ') : '${k.deger}';
  return switch (k.operator) {
    'esit' => k.deger == true ? alan : '$alan: $d',
    'esitDegil' => '$alan $d olmamalı',
    'icinde' => '$alan: $d',
    'disinda' => '$alan: $d dışında',
    'buyukEsit' => '$alan en az $d',
    'kucukEsit' => '$alan en çok $d',
    'arasinda' => '$alan $d aralığında',
    _ => '$alan ${k.operator} $d',
  };
}

class DestekDetayEkrani extends ConsumerWidget {
  const DestekDetayEkrani({super.key, required this.destekId});

  final String destekId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VeriBekle(
      builder: (context, veri) {
        final d = veri.destek(destekId);
        if (d == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const BosDurum(ikon: Icons.search_off, baslik: 'Destek bulunamadı'),
          );
        }
        final firma = ref.watch(seciliFirmaProvider);
        final u = firma == null ? null : uygunluk(d, firma);
        final t = Theme.of(context).textTheme;
        final donem = d.basvuruDonemi;
        return Scaffold(
          appBar: AppBar(title: Text(d.kurum.etiket)),
          floatingActionButton: u?.durum == UygunlukDurumu.uygunDegil
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => context.go('/destekler/${d.id}/hesap'),
                  icon: const Icon(Icons.calculate),
                  label: const Text('Azami teşviki hesapla'),
                ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (!d.dogrulandi) const OrnekVeriBandi(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.ad, style: t.headlineSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (u != null) UygunlukRozeti(u.durum),
                        Chip(label: Text(d.destekTuru.etiket)),
                        for (final k in d.konular) Chip(label: Text(konuEtiketleri[k] ?? k)),
                      ],
                    ),
                    if (u != null && u.nedenler.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final n in u.nedenler) Text('• $n', style: t.bodyMedium),
                    ],
                  ],
                ),
              ),
              _Bolum('Başvuru dönemi', [
                Text(switch (donem.tip) {
                  'surekli' => 'Sürekli açık',
                  'kapali' => 'Şu an kapalı',
                  _ => [
                    if (donem.baslangic != null) tarih(donem.baslangic!),
                    if (donem.bitis != null) tarih(donem.bitis!),
                  ].join(' – '),
                }),
                if (donem.sonBasvuruKurali != null) Text(donem.sonBasvuruKurali!, style: t.bodySmall),
                if (d.programTavani != null)
                  Text('Program tavanı: ${para(d.programTavani!.deger, d.programTavani!.paraBirimi)}'),
              ]),
              if (d.kosullar.isNotEmpty)
                _Bolum('Koşullar', [
                  for (final k in d.kosullar)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: firma == null
                          ? const Icon(Icons.rule)
                          : kosulSaglar(k, firma.alanlar)
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : Icon(
                              k.zorunlu ? Icons.cancel : Icons.info,
                              color: k.zorunlu ? Colors.red : Colors.orange,
                            ),
                      title: Text(k.mesaj ?? kosulMetni(k)),
                      subtitle: Text(k.zorunlu ? 'Zorunlu' : 'Zorunlu değil'),
                    ),
                ]),
              if (d.nace.isNotEmpty)
                _Bolum('NACE kapsamı', [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final n in d.nace)
                        Chip(
                          avatar: Icon(
                            n.tip == 'dahil' ? Icons.add_circle_outline : Icons.remove_circle_outline,
                            size: 18,
                          ),
                          label: Text('${n.tip == 'dahil' ? 'Dahil' : 'Hariç'}: ${n.kod}'),
                        ),
                    ],
                  ),
                ]),
              _Bolum('Destek kalemleri', [
                for (final k in d.kalemler)
                  _KalemSatiri(kalem: k, etkin: etkin(k, firma?.alanlar ?? const {})),
              ]),
              if (d.belgeler.isNotEmpty)
                _Bolum('İstenen belgeler', [for (final b in d.belgeler) Text('• $b')]),
              _Bolum('Kaynak', [
                if (d.mevzuat != null) Text(d.mevzuat!),
                SelectableText(d.kaynakUrl),
                Text('Güncelleme: ${tarih(d.guncellemeTarihi)} · Sürüm ${d.surum}', style: t.bodySmall),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _KalemSatiri extends StatelessWidget {
  const _KalemSatiri({required this.kalem, required this.etkin});

  final DestekKalemi kalem;
  final EtkinKalem etkin;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final limit = etkin.limit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kalem.ad, style: t.titleSmall),
          Text(
            [
              'Destek oranı ${yuzde(etkin.oran)}',
              if (limit != null) 'Üst limit ${para(limit, kalem.ustLimit?.paraBirimi ?? ParaBirimi.TRY)}',
              kalem.limitDonemi.etiket,
              if (kalem.sure != null) kalem.sure!,
            ].join(' · '),
          ),
          if (etkin.rozetler.isNotEmpty)
            Wrap(
              spacing: 6,
              children: [
                for (final r in etkin.rozetler.where((r) => r.isNotEmpty))
                  Chip(label: Text(r), visualDensity: VisualDensity.compact),
              ],
            ),
        ],
      ),
    );
  }
}

class _Bolum extends StatelessWidget {
  const _Bolum(this.baslik, this.icerik);

  final String baslik;
  final List<Widget> icerik;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(baslik, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...icerik,
          ],
        ),
      ),
    );
  }
}
