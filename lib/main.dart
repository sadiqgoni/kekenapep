import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:keke_fairshare/index.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String?> getLastLoginRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_login_role'); 
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeKe FairShare',
      theme: ThemeData.light(), // Replace with AppTheme.theme if applicable
      debugShowCheckedModeBanner: false,
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
      initialRoute: '/', // Default route
      onGenerateInitialRoutes: (String initialRouteName) {
        return [
          MaterialPageRoute(
            builder: (context) {
              return FutureBuilder<String?>(
                future: getLastLoginRole(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const AuthGate();
                  }

                  final lastRole = snapshot.data;
                  final currentUser = FirebaseAuth.instance.currentUser;

                  if (lastRole == 'admin' && currentUser != null) {
                    return const AdminDashboardScreen();
                  }

                  return const AuthGate();
                },
              );
            },
          ),
        ];
      },
    );
  }
}
