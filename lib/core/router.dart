import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/ana_sayfa/ana_sayfa_ekrani.dart';
import '../features/destekler/destek_detay_ekrani.dart';
import '../features/destekler/destekler_ekrani.dart';
import '../features/firma/firma_sihirbazi_ekrani.dart';
import '../features/firma/firmalarim_ekrani.dart';
import '../features/hesap/hesap_ekrani.dart';
import '../features/kabuk/ana_kabuk.dart';
import '../features/nace/nace_secim_ekrani.dart';
import '../features/takip/takip_ekrani.dart';

final _kokAnahtar = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _kokAnahtar,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, kabuk) => AnaKabuk(kabuk: kabuk),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => const AnaSayfaEkrani())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/destekler',
              builder: (_, _) => const DesteklerEkrani(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, s) => DestekDetayEkrani(destekId: s.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'hesap',
                      builder: (_, s) => HesapEkrani(destekId: s.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/firmalar', builder: (_, _) => const FirmalarimEkrani())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/takip', builder: (_, _) => const TakipEkrani())],
        ),
      ],
    ),
    GoRoute(
      path: '/firma/yeni',
      parentNavigatorKey: _kokAnahtar,
      builder: (_, _) => const FirmaSihirbaziEkrani(),
    ),
    GoRoute(
      path: '/firma/:id/duzenle',
      parentNavigatorKey: _kokAnahtar,
      builder: (_, s) => FirmaSihirbaziEkrani(firmaId: s.pathParameters['id']),
    ),
    GoRoute(
      path: '/nace',
      parentNavigatorKey: _kokAnahtar,
      builder: (_, s) => NaceSecimEkrani(args: s.extra as NaceSecimArgs? ?? const NaceSecimArgs()),
    ),
  ],
);
