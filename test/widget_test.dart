import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tesvik/app.dart';
import 'package:tesvik/data/depo.dart';
import 'package:tesvik/data/saglayicilar.dart';

/// Varlıkları doğrudan diskten okur; test motorunun asset kuyruğunu beklemez.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(File(key).readAsBytesSync()));
}

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  Future<void> ac(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          depoProvider.overrideWithValue(YerelDepo(_DiskBundle())),
          bugunProvider.overrideWithValue(DateTime(2026, 10, 24)),
        ],
        child: const TesvikUygulamasi(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
  }

  testWidgets('ana sayfa örnek firmayı ve azami tutarı gösterir', (tester) async {
    await ac(tester);
    expect(find.text('Ege Mobilya Ltd. Şti. (örnek)'), findsOneWidget);
    expect(find.text('Size uygun destekler'), findsOneWidget);
  });

  testWidgets('destekler sekmesinden hesap ekranına gidilir', (tester) async {
    await ac(tester);
    await tester.tap(find.text('Destekler').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('KOBİ Gelişim Destek Programı (örnek)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Azami teşviki hesapla'));
    await tester.pumpAndSettle();
    expect(find.text('Toplam azami destek'), findsOneWidget);
  });
}
