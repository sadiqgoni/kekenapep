import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:keke_fairshare/screens/auth/auth_gate.dart';
import 'package:keke_fairshare/admin/auth/login_screen.dart';
import 'package:keke_fairshare/admin/screens/dashboard_screen.dart';
import 'package:keke_fairshare/firebase_options.dart';
import 'package:keke_fairshare/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeKe FairShare',
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/admin': (context) => const AdminLoginScreen(),
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const AuthGate(),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
