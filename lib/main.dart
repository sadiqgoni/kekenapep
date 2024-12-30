import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:keke_fairshare/screens/auth/auth_gate.dart';
import 'package:keke_fairshare/admin/auth/login_screen.dart';
import 'package:keke_fairshare/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        // '/admin': (context) => const AdminLoginScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
