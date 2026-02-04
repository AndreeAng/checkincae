import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin_home.dart';
import 'screens/employee_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(const CheckInApp());
}

class CheckInApp extends StatelessWidget {
  const CheckInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..loadFromStorage(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Check-In CAE',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          navigationBarTheme: NavigationBarThemeData(
            height: 64,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFFFEDD5),
            labelTextStyle: MaterialStateProperty.resolveWith(
              (states) => TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: states.contains(MaterialState.selected)
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
            iconTheme: MaterialStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(MaterialState.selected)
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
        home: const RootRouter(),
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        if (auth.user?.role == 'ADMIN') {
          return const AdminHome();
        }

        return const EmployeeHome();
      },
    );
  }
}
