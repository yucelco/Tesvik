import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/model/firma.dart';
import '../../core/model/referans.dart';
import '../../core/motor/uygunluk.dart';
import '../../core/ui/bicim.dart';
import '../../data/saglayicilar.dart';
import '../hesap/hesap_ekrani.dart' show tutarOku;
import '../nace/nace_secim_ekrani.dart';
import '../ortak/ortak.dart';

class FirmaSihirbaziEkrani extends ConsumerWidget {
  const FirmaSihirbaziEkrani({super.key, this.firmaId});

  /// Doluysa mevcut firma düzenlenir.
  final String? firmaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(firmaId == null ? 'Yeni firma' : 'Firmayı düzenle')),
      body: VeriBekle(
        builder: (context, veri) {
          final firmalar = ref.watch(firmalarProvider).value ?? const <Firma>[];
          final mevcut = firmalar.where((f) => f.id == firmaId).firstOrNull;
          return _Sihirbaz(veri: veri, mevcut: mevcut);
        },
      ),
    );
  }
}

class _Sihirbaz extends ConsumerStatefulWidget {
  const _Sihirbaz({required this.veri, this.mevcut});

  final TesvikVerisi veri;
  final Firma? mevcut;

  @override
  ConsumerState<_Sihirbaz> createState() => _SihirbazState();
}

class _SihirbazState extends ConsumerState<_Sihirbaz> {
  int _adim = 0;
  final _kimlikFormu = GlobalKey<FormState>();
  final _olcekFormu = GlobalKey<FormState>();

  late final _unvan = TextEditingController(text: widget.mevcut?.unvan);
  late final _vkn = TextEditingController(text: widget.mevcut?.vkn);
  late final _ilce = TextEditingController(text: widget.mevcut?.ilce);
  late final _calisan = TextEditingController(text: widget.mevcut?.calisanSayisi.toString());
  late final _netSatis = TextEditingController(text: _yaz(widget.mevcut?.netSatis));
  late final _bilanco = TextEditingController(text: _yaz(widget.mevcut?.bilancoToplami));
  late final _ihracat = TextEditingController(text: _yaz(widget.mevcut?.ihracatUsd));
  late SirketTuru _tur = widget.mevcut?.sirketTuru ?? SirketTuru.ltd;
  late int? _il = widget.mevcut?.il;
  late DateTime? _kurulus = widget.mevcut?.kurulusTarihi;
  late final Map<String, bool> _ozel = {...?widget.mevcut?.ozelDurumlar};
  late List<FirmaNace> _nace = [...?widget.mevcut?.naceKodlari];

  static String _yaz(double? d) => d == null ? '' : sayi(d);

  @override
  void dispose() {
    for (final c in [_unvan, _vkn, _ilce, _calisan, _netSatis, _bilanco, _ihracat]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _olcek {
    final c = int.tryParse(_calisan.text);
    final n = tutarOku(_netSatis.text);
    final b = tutarOku(_bilanco.text);
    if (c == null || n == null || b == null) return null;
    return olcekHesapla(
      calisanSayisi: c,
      netSatis: n,
      bilancoToplami: b,
      tanim: widget.veri.referans.olcekTanimi,
    );
  }

  bool _adimGecerli(int adim) => switch (adim) {
    0 => _kimlikFormu.currentState?.validate() ?? false,
    1 => (_olcekFormu.currentState?.validate() ?? false) && _kurulus != null,
    3 => _nace.isNotEmpty,
    _ => true,
  };

  Future<void> _naceEkle() async {
    final secim = await context.push<List<String>>(
      '/nace',
      extra: NaceSecimArgs(coklu: true, secili: [for (final n in _nace) n.kod]),
    );
    if (secim == null) return;
    final ana = _nace.where((n) => n.anaKod).map((n) => n.kod).firstOrNull;
    setState(() {
      _nace = [for (final k in secim) FirmaNace(k, anaKod: k == ana)];
      if (_nace.isNotEmpty && !_nace.any((n) => n.anaKod)) {
        _nace[0] = FirmaNace(_nace[0].kod, anaKod: true);
      }
    });
  }

  Future<void> _kaydet() async {
    final m = widget.mevcut;
    final firma = Firma(
      id: m?.id ?? 'f-${DateTime.now().millisecondsSinceEpoch}',
      sahipUid: m?.sahipUid ?? ref.read(depoProvider).kullaniciId,
      unvan: _unvan.text.trim(),
      vkn: _vkn.text.trim().isEmpty ? null : _vkn.text.trim(),
      sirketTuru: _tur,
      il: _il!,
      ilce: _ilce.text.trim().isEmpty ? null : _ilce.text.trim(),
      kurulusTarihi: _kurulus!,
      calisanSayisi: int.parse(_calisan.text),
      netSatis: tutarOku(_netSatis.text)!,
      bilancoToplami: tutarOku(_bilanco.text)!,
      ihracatUsd: tutarOku(_ihracat.text) ?? 0,
      ozelDurumlar: {
        for (final e in _ozel.entries)
          if (e.value) e.key: true,
      },
      naceKodlari: _nace,
    );
    await ref.read(firmalarProvider.notifier).kaydet(firma);
    ref.read(seciliFirmaIdProvider.notifier).sec(firma.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final iller = [...widget.veri.referans.iller]..sort((a, b) => a.ad.compareTo(b.ad));
    final naceAdlari = {for (final n in widget.veri.naceKodlari) n.kod: n.ad};
    final son = _adim == 3;
    return Stepper(
      currentStep: _adim,
      onStepTapped: (i) {
        if (i < _adim || _adimGecerli(_adim)) setState(() => _adim = i);
      },
      onStepCancel: _adim == 0 ? null : () => setState(() => _adim--),
      onStepContinue: () {
        if (!_adimGecerli(_adim)) {
          if (_adim == 1 && _kurulus == null) _uyar('Kuruluş tarihini seçin');
          if (_adim == 3) _uyar('En az bir NACE kodu ekleyin');
          return;
        }
        son ? _kaydet() : setState(() => _adim++);
      },
      controlsBuilder: (context, d) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          children: [
            FilledButton(onPressed: d.onStepContinue, child: Text(son ? 'Kaydet' : 'Devam')),
            const SizedBox(width: 8),
            if (d.onStepCancel != null) TextButton(onPressed: d.onStepCancel, child: const Text('Geri')),
          ],
        ),
      ),
      steps: [
        Step(
          title: const Text('Firma kimliği'),
          isActive: _adim >= 0,
          content: Form(
            key: _kimlikFormu,
            child: Column(
              children: [
                TextFormField(
                  controller: _unvan,
                  decoration: const InputDecoration(labelText: 'Ticari unvan'),
                  validator: (s) => (s ?? '').trim().isEmpty ? 'Unvan gerekli' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SirketTuru>(
                  initialValue: _tur,
                  decoration: const InputDecoration(labelText: 'Şirket türü'),
                  items: [
                    for (final t in SirketTuru.values) DropdownMenuItem(value: t, child: Text(t.etiket)),
                  ],
                  onChanged: (t) => setState(() => _tur = t!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _il,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'İl'),
                  items: [
                    for (final i in iller)
                      DropdownMenuItem(value: i.plaka, child: Text('${i.ad} (${i.yatirimBolgesi}. bölge)')),
                  ],
                  validator: (i) => i == null ? 'İl seçin' : null,
                  onChanged: (i) => setState(() => _il = i),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ilce,
                  decoration: const InputDecoration(labelText: 'İlçe (isteğe bağlı)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vkn,
                  decoration: const InputDecoration(labelText: 'Vergi / TC kimlik no (isteğe bağlı)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (s) => (s ?? '').isEmpty || s!.length >= 10 ? null : '10 ya da 11 hane olmalı',
                ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Ölçek bilgileri'),
          subtitle: _olcek == null ? null : Text(olcekEtiketleri[_olcek]!),
          isActive: _adim >= 1,
          content: Form(
            key: _olcekFormu,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(_kurulus == null ? 'Kuruluş tarihi seçin' : 'Kuruluş: ${tarih(_kurulus!)}'),
                  onPressed: () async {
                    final t = await showDatePicker(
                      context: context,
                      initialDate: _kurulus ?? DateTime(2015),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (t != null) setState(() => _kurulus = t);
                  },
                ),
                const SizedBox(height: 12),
                _sayiAlani(_calisan, 'Çalışan sayısı', tamSayi: true),
                _sayiAlani(_netSatis, 'Yıllık net satış (TL)'),
                _sayiAlani(_bilanco, 'Mali bilanço toplamı (TL)'),
                _sayiAlani(_ihracat, 'Yıllık ihracat (USD, isteğe bağlı)', zorunlu: false),
                if (_olcek != null)
                  Text(
                    'Hesaplanan ölçek: ${olcekEtiketleri[_olcek]}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Özel durumlar'),
          isActive: _adim >= 2,
          content: Column(
            children: [
              for (final e in ozelDurumEtiketleri.entries)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.value),
                  value: _ozel[e.key] ?? false,
                  onChanged: (v) => setState(() => _ozel[e.key] = v),
                ),
            ],
          ),
        ),
        Step(
          title: const Text('NACE kodları'),
          isActive: _adim >= 3,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final n in _nace)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: IconButton(
                    tooltip: 'Ana faaliyet kodu yap',
                    icon: Icon(n.anaKod ? Icons.star : Icons.star_border),
                    onPressed: () => setState(() {
                      _nace = [for (final x in _nace) FirmaNace(x.kod, anaKod: x.kod == n.kod)];
                    }),
                  ),
                  title: Text(n.kod),
                  subtitle: naceAdlari[n.kod] == null ? null : Text(naceAdlari[n.kod]!),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _nace = [..._nace]..remove(n)),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _naceEkle,
                icon: const Icon(Icons.add),
                label: const Text('NACE kodu ekle'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sayiAlani(TextEditingController c, String etiket, {bool tamSayi = false, bool zorunlu = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: etiket),
        keyboardType: TextInputType.numberWithOptions(decimal: !tamSayi),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(tamSayi ? r'[0-9]' : r'[0-9.,]'))],
        onChanged: (_) => setState(() {}),
        validator: (s) => !zorunlu || tutarOku(s ?? '') != null ? null : 'Gerekli',
      ),
    );
  }

  void _uyar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}
