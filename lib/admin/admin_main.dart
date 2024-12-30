import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:keke_fairshare/admin/auth/login_screen.dart';
import 'package:keke_fairshare/theme.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeKe Admin',
      theme: AppTheme.theme,
      home: const AdminLoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<void> initializeAdminApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AdminApp());
}
