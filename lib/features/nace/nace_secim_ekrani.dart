import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ortak/ortak.dart';

class NaceSecimArgs {
  const NaceSecimArgs({this.coklu = true, this.secili = const []});

  final bool coklu;
  final List<String> secili;
}

final _kodDeseni = RegExp(r'^\d{2}(\.\d{1,2}){0,2}$');

/// Seçilen kodları `context.pop(List<String>)` ile döner.
class NaceSecimEkrani extends StatefulWidget {
  const NaceSecimEkrani({super.key, required this.args});

  final NaceSecimArgs args;

  @override
  State<NaceSecimEkrani> createState() => _NaceSecimEkraniState();
}

class _NaceSecimEkraniState extends State<NaceSecimEkrani> {
  late final _secili = <String>[...widget.args.secili];
  String _arama = '';

  void _degistir(String kod) {
    if (!widget.args.coklu) {
      context.pop([kod]);
      return;
    }
    setState(() => _secili.contains(kod) ? _secili.remove(kod) : _secili.add(kod));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args.coklu ? 'NACE kodları' : 'NACE kodu seçin'),
        actions: [
          if (widget.args.coklu)
            TextButton(onPressed: () => context.pop(_secili), child: Text('Tamam (${_secili.length})')),
          if (!widget.args.coklu && _secili.isNotEmpty)
            TextButton(onPressed: () => context.pop(<String>[]), child: const Text('Temizle')),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              autoFocus: true,
              hintText: 'Kod ya da faaliyet adı (ör. 31.01, mobilya)',
              leading: const Icon(Icons.search),
              onChanged: (s) => setState(() => _arama = s.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      body: VeriBekle(
        builder: (context, veri) {
          final liste = veri.naceKodlari
              .where((n) => _arama.isEmpty || n.kod.startsWith(_arama) || n.ad.toLowerCase().contains(_arama))
              .toList();
          final elle = _kodDeseni.hasMatch(_arama) && !veri.naceKodlari.any((n) => n.kod == _arama);
          return ListView(
            children: [
              if (elle)
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text('"$_arama" kodunu ekle'),
                  subtitle: const Text('Listede olmayan alt sınıf kodu'),
                  onTap: () => _degistir(_arama),
                ),
              for (final n in liste)
                ListTile(
                  leading: widget.args.coklu
                      ? Checkbox(value: _secili.contains(n.kod), onChanged: (_) => _degistir(n.kod))
                      : null,
                  title: Text(n.kod),
                  subtitle: Text(n.ad),
                  contentPadding: EdgeInsets.only(left: n.kod.length > 2 ? 32 : 16, right: 16),
                  selected: _secili.contains(n.kod),
                  onTap: () => _degistir(n.kod),
                ),
            ],
          );
        },
      ),
    );
  }
}
