import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/model/destek.dart';
import '../../core/motor/uygunluk.dart';
import '../../data/saglayicilar.dart';
import '../nace/nace_secim_ekrani.dart';
import '../ortak/ortak.dart';
import 'destek_karti.dart';

class DesteklerEkrani extends ConsumerStatefulWidget {
  const DesteklerEkrani({super.key});

  @override
  ConsumerState<DesteklerEkrani> createState() => _DesteklerEkraniState();
}

class _DesteklerEkraniState extends ConsumerState<DesteklerEkrani> {
  String _arama = '';
  final _durumlar = <UygunlukDurumu>{UygunlukDurumu.uygun, UygunlukDurumu.kismen};
  Kurum? _kurum;
  String? _konu;
  String? _nace;

  Future<void> _naceSec() async {
    final secim = await context.push<List<String>>(
      '/nace',
      extra: NaceSecimArgs(coklu: false, secili: [?_nace]),
    );
    if (secim != null) setState(() => _nace = secim.isEmpty ? null : secim.first);
  }

  @override
  Widget build(BuildContext context) {
    final firmaVar = ref.watch(seciliFirmaProvider) != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Destekler'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: 'Destek ara',
              leading: const Icon(Icons.search),
              onChanged: (s) => setState(() => _arama = s.toLowerCase()),
            ),
          ),
        ),
      ),
      body: VeriBekle(
        builder: (context, veri) {
          final liste = ref.watch(destekOzetleriProvider).where((o) {
            final d = o.destek;
            if (_arama.isNotEmpty && !d.ad.toLowerCase().contains(_arama)) return false;
            if (firmaVar && !_durumlar.contains(o.uygunluk!.durum)) return false;
            if (_kurum != null && d.kurum != _kurum) return false;
            if (_konu != null && !d.konular.contains(_konu)) return false;
            if (_nace != null && !naceKapsaminda(d, [_nace!])) return false;
            return true;
          }).toList();
          final konular = {for (final d in veri.destekler) ...d.konular};
          final kurumlar = {for (final d in veri.destekler) d.kurum};
          return Column(
            children: [
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    if (firmaVar)
                      for (final u in UygunlukDurumu.values)
                        _cip(
                          FilterChip(
                            label: Text(u.etiket),
                            selected: _durumlar.contains(u),
                            onSelected: (s) => setState(() => s ? _durumlar.add(u) : _durumlar.remove(u)),
                          ),
                        ),
                    _cip(
                      InputChip(
                        avatar: const Icon(Icons.category_outlined, size: 18),
                        label: Text(_nace == null ? 'NACE kodu' : 'NACE $_nace'),
                        selected: _nace != null,
                        onPressed: _naceSec,
                        onDeleted: _nace == null ? null : () => setState(() => _nace = null),
                      ),
                    ),
                    for (final k in kurumlar)
                      _cip(
                        ChoiceChip(
                          label: Text(k.etiket),
                          selected: _kurum == k,
                          onSelected: (s) => setState(() => _kurum = s ? k : null),
                        ),
                      ),
                    for (final k in konular)
                      _cip(
                        ChoiceChip(
                          label: Text(konuEtiketleri[k] ?? k),
                          selected: _konu == k,
                          onSelected: (s) => setState(() => _konu = s ? k : null),
                        ),
                      ),
                  ],
                ),
              ),
              if (!firmaVar)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Uygunluk ve azami tutar için Firmalarım sekmesinden firma ekleyin.'),
                ),
              Expanded(
                child: liste.isEmpty
                    ? const BosDurum(ikon: Icons.filter_alt_off, baslik: 'Filtrelere uyan destek yok')
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: liste.length,
                        itemBuilder: (_, i) => DestekKarti(ozet: liste[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cip(Widget c) => Padding(padding: const EdgeInsets.only(right: 8), child: c);
}
