import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../core/model/firma.dart';
import '../core/model/referans.dart';

/// Uygulamanın veriye eriştiği tek arayüz. Firebase bağlıysa [FirestoreDepo],
/// değilse paketle gelen örnek veriyi okuyan [YerelDepo] kullanılır.
abstract class TesvikDeposu {
  bool get yerel;

  /// Yeni kayıtların sahipUid alanı.
  String get kullaniciId;

  Future<TesvikVerisi> yukle();

  Future<void> firmaKaydet(Firma firma);
}

Future<Map<String, dynamic>> _assetOku(AssetBundle b, String yol) async =>
    jsonDecode(await b.loadString(yol)) as Map<String, dynamic>;

Future<List<NaceKodu>> _naceOku(AssetBundle b) async {
  final j = await _assetOku(b, 'assets/veri/nace.json');
  return [for (final k in j['kodlar'] as List) NaceKodu.fromJson(Map<String, dynamic>.from(k))];
}

class YerelDepo implements TesvikDeposu {
  YerelDepo([AssetBundle? bundle]) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  bool get yerel => true;

  @override
  String get kullaniciId => 'yerel';

  @override
  Future<TesvikVerisi> yukle() async {
    final veri = await _assetOku(_bundle, 'assets/veri/ornek-veri.json');
    final iller = await _assetOku(_bundle, 'assets/veri/iller.json');
    // Örnek veride yalnızca birkaç il var; 81 il listesi ayrı dosyadan gelir.
    (veri['referans'] as Map)['iller'] = iller['iller'];
    return TesvikVerisi.fromJson(veri, naceKodlari: await _naceOku(_bundle));
  }

  /// Yerel kipte firmalar yalnızca bellekte tutulur.
  @override
  Future<void> firmaKaydet(Firma firma) async {}
}

/// Koleksiyonlar: destekler, firmalar, basvurular, senaryolar; referans/v1 belgesi.
/// Kullanıcıya ait koleksiyonlar sahipUid ile süzülür (Firestore kuralları da aynı alanı kullanmalı).
class FirestoreDepo implements TesvikDeposu {
  FirestoreDepo(this._db, this._uid, [AssetBundle? bundle]) : _bundle = bundle ?? rootBundle;

  final FirebaseFirestore _db;
  final String _uid;
  final AssetBundle _bundle;

  @override
  bool get yerel => false;

  @override
  String get kullaniciId => _uid;

  Future<List<Map<String, dynamic>>> _liste(Query<Map<String, dynamic>> q) async {
    final s = await q.get();
    return [for (final d in s.docs) d.data()];
  }

  /// Başvuru ve senaryolar firmaId taşır; kullanıcının firmalarına göre süzülür.
  Future<List<Map<String, dynamic>>> _firmalara(String koleksiyon, List<String> firmaIdleri) async {
    final sonuc = <Map<String, dynamic>>[];
    // whereIn en çok 30 değer alır.
    for (var i = 0; i < firmaIdleri.length; i += 30) {
      final parca = firmaIdleri.sublist(i, i + 30 > firmaIdleri.length ? firmaIdleri.length : i + 30);
      sonuc.addAll(await _liste(_db.collection(koleksiyon).where('firmaId', whereIn: parca)));
    }
    return sonuc;
  }

  @override
  Future<TesvikVerisi> yukle() async {
    final firmalar = await _liste(_db.collection('firmalar').where('sahipUid', isEqualTo: _uid));
    final idler = [for (final f in firmalar) f['id'] as String];
    final ref = await _db.doc('referans/v1').get();
    return TesvikVerisi.fromJson({
      'destekler': await _liste(_db.collection('destekler')),
      'firmalar': firmalar,
      'basvurular': await _firmalara('basvurular', idler),
      'senaryolar': await _firmalara('senaryolar', idler),
      'referans': ref.data() ?? const {},
    }, naceKodlari: await _naceOku(_bundle));
  }

  @override
  Future<void> firmaKaydet(Firma firma) => _db.collection('firmalar').doc(firma.id).set(firma.toJson());
}
