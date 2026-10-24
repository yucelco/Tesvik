import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router.dart';
import 'core/ui/tema.dart';

class TesvikUygulamasi extends StatelessWidget {
  const TesvikUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Teşvik Rehberi',
      theme: tema(Brightness.light),
      darkTheme: tema(Brightness.dark),
      routerConfig: router,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
    );
  }
}
