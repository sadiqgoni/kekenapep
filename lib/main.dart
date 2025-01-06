import 'package:keke_fairshare/index.dart';

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
        // '/admin': (context) => const AdminLoginScreen(),
        // '/admin/dashboard': (context) => const AdminDashboardScreen(),
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
