import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnaKabuk extends StatelessWidget {
  const AnaKabuk({super.key, required this.kabuk});

  final StatefulNavigationShell kabuk;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: kabuk,
      bottomNavigationBar: NavigationBar(
        selectedIndex: kabuk.currentIndex,
        onDestinationSelected: (i) => kabuk.goBranch(i, initialLocation: i == kabuk.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Destekler',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Firmalarım',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Takip',
          ),
        ],
      ),
    );
  }
}
