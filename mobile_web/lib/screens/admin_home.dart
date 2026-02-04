import 'package:flutter/material.dart';

import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_worksites_screen.dart';
import 'admin_checkins_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  final _screens = const [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminWorkSitesScreen(),
    AdminCheckinsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Empleados',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment),
            label: 'Lugares',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check),
            label: 'Registros',
          ),
        ],
      ),
    );
  }
}
