import 'package:flutter/material.dart';
import 'package:keke_fairshare/screens/auth/auth_gate.dart';
import 'package:keke_fairshare/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeKe FairShare',
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}
