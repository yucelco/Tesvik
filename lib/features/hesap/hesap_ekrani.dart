import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/model/destek.dart';
import '../../core/model/ortak.dart';
import '../../core/model/referans.dart';
import '../../core/model/takip.dart';
import '../../core/motor/hesap.dart';
import '../../core/motor/uygunluk.dart';
import '../../core/ui/bicim.dart';
import '../../data/saglayicilar.dart';
import '../ortak/ortak.dart';

/// "24.000" ya da "24000,50" biçimindeki girişi sayıya çevirir.
double? tutarOku(String s) {
  final temiz = s.trim().replaceAll('.', '').replaceAll(' ', '').replaceAll(',', '.');
  return temiz.isEmpty ? null : double.tryParse(temiz);
}

class HesapEkrani extends ConsumerWidget {
  const HesapEkrani({super.key, required this.destekId});

  final String destekId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Azami teşvik hesabı')),
      body: VeriBekle(
        builder: (context, veri) {
          final d = veri.destek(destekId);
          final firma = ref.watch(seciliFirmaProvider);
          if (d == null) return const BosDurum(ikon: Icons.search_off, baslik: 'Destek bulunamadı');
          if (firma == null) {
            return BosDurum(
              ikon: Icons.business_outlined,
              baslik: 'Hesap için firma gerekli',
              eylem: FilledButton(
                onPressed: () => context.push('/firma/yeni'),
                child: const Text('Firma ekle'),
              ),
            );
          }
          return _HesapFormu(
            key: ValueKey('${firma.firma.id}-${d.id}'),
            destek: d,
            firma: firma,
            veri: veri,
            bugun: ref.watch(bugunProvider),
          );
        },
      ),
    );
  }
}

class _HesapFormu extends StatefulWidget {
  const _HesapFormu({
    super.key,
    required this.destek,
    required this.firma,
    required this.veri,
    required this.bugun,
  });

  final Destek destek;
  final TuretilmisFirma firma;
  final TesvikVerisi veri;
  final DateTime bugun;

  @override
  State<_HesapFormu> createState() => _HesapFormuState();
}

class _HesapFormuState extends State<_HesapFormu> {
  late final Map<String, TextEditingController> _harcamalar;
  String? _hedefUlke;
  late final List<String> _ulkeSecenekleri;

  @override
  void initState() {
    super.initState();
    final s = senaryoBul(widget.veri, widget.firma.firma.id, widget.destek.id);
    final plan = {
      for (final k in s?.kalemler ?? const <SenaryoKalemi>[]) k.kalemId: k.planlananHarcama.deger,
    };
    _harcamalar = {
      for (final k in widget.destek.kalemler)
        if (k.ustLimit != null)
          k.id: TextEditingController(text: plan[k.id] == null ? '' : sayi(plan[k.id]!)),
    };
    _hedefUlke = s?.faaliyet['hedefUlke'] as String?;
    _ulkeSecenekleri = {
      for (final k in widget.destek.kalemler)
        for (final r in k.kurallar)
          if (r.kosul.alan == 'hedefUlke' && r.kosul.deger is List) ...(r.kosul.deger as List).cast<String>(),
    }.toList();
  }

  @override
  void dispose() {
    for (final c in _harcamalar.values) {
      c.dispose();
    }
    super.dispose();
  }

  Senaryo get _senaryo => Senaryo(
    id: 'gecici',
    firmaId: widget.firma.firma.id,
    destekId: widget.destek.id,
    ad: 'Hesap',
    faaliyet: {'hedefUlke': ?_hedefUlke},
    kalemler: [
      for (final e in _harcamalar.entries)
        if (tutarOku(e.value.text) case final h?)
          SenaryoKalemi(e.key, Tutar(h, widget.destek.kalem(e.key)!.ustLimit!.paraBirimi)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final h = hesapla(widget.destek, widget.firma, widget.veri.basvurular, _senaryo, widget.bugun);
    final t = Theme.of(context).textTheme;
    final ref = widget.veri.referans;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.destek.ad, style: t.titleLarge),
              Text(widget.firma.firma.unvan, style: t.bodyMedium),
              const SizedBox(height: 8),
              Text(
                'Her kalem için planladığınız harcamayı girin. Boş bırakılan kalemde kalan üst limitin tamamı gösterilir.',
                style: t.bodySmall,
              ),
            ],
          ),
        ),
        if (_ulkeSecenekleri.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String?>(
              initialValue: _hedefUlke,
              decoration: const InputDecoration(labelText: 'Hedef ülke'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Diğer / belirtilmedi')),
                for (final u in _ulkeSecenekleri) DropdownMenuItem(value: u, child: Text(u)),
              ],
              onChanged: (u) => setState(() => _hedefUlke = u),
            ),
          ),
        for (final s in h.satirlar) _satir(context, s),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Toplam azami destek', style: t.labelLarge),
                Text(para(h.toplam, h.paraBirimi), style: t.headlineMedium),
                if (h.paraBirimi != ParaBirimi.TRY && ref.kur[h.paraBirimi] != null)
                  Text(
                    '≈ ${para(ref.tlKarsiligi(Tutar(h.toplam, h.paraBirimi)), ParaBirimi.TRY)}'
                    '${ref.kurTarihi == null ? '' : ' (${tarih(ref.kurTarihi!)} kuru)'}',
                  ),
                if (h.tavanaTakildi) Text('Program tavanı nedeniyle sınırlandı.', style: t.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _satir(BuildContext context, KalemSonucu s) {
    final t = Theme.of(context).textTheme;
    final k = s.kalem;
    final c = _harcamalar[k.id];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k.ad, style: t.titleSmall),
            const SizedBox(height: 4),
            if (s.limit == null)
              Text(
                'Oran ${yuzde(s.oran)}${k.sure == null ? '' : ' · ${k.sure}'}. Tutar üst limiti yok, '
                'yatırım tutarına göre hesaplanır.',
              )
            else ...[
              Text(
                'Oran ${yuzde(s.oran)} · Üst limit ${para(s.limit!, s.paraBirimi)} · ${k.limitDonemi.etiket}',
              ),
              if ((s.kullanilan ?? 0) > 0)
                Text('Bu dönem kullanılan: ${para(s.kullanilan!, s.paraBirimi)}', style: t.bodySmall),
              const SizedBox(height: 12),
              TextField(
                controller: c,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(
                  labelText: 'Planlanan harcama (${s.paraBirimi.name})',
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                'Alınabilecek: ${para(s.azami!, s.paraBirimi)}',
                style: t.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ],
            if (s.rozetler.any((r) => r.isNotEmpty))
              Wrap(
                spacing: 6,
                children: [
                  for (final r in s.rozetler.where((r) => r.isNotEmpty))
                    Chip(label: Text(r), visualDensity: VisualDensity.compact),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
