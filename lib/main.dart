import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/depo.dart';
import 'data/saglayicilar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  final depo = await _depoHazirla();
  runApp(ProviderScope(overrides: [depoProvider.overrideWithValue(depo)], child: const TesvikUygulamasi()));
}

/// Firebase yapılandırması (android/app/google-services.json) yoksa
/// uygulama paketle gelen örnek veriyle yerel kipte açılır.
Future<TesvikDeposu> _depoHazirla() async {
  try {
    await Firebase.initializeApp();
    final auth = FirebaseAuth.instance;
    final kullanici = auth.currentUser ?? (await auth.signInAnonymously()).user!;
    return FirestoreDepo(FirebaseFirestore.instance, kullanici.uid);
  } catch (e) {
    debugPrint('Firebase kullanılamıyor, yerel veriye geçildi: $e');
    return YerelDepo();
  }
}
