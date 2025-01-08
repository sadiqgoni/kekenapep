import 'package:keke_fairshare/index.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Check the connection state
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;

          // If no user is logged in
          if (user == null) {
            return OnboardingScreen(); // Navigate to onboarding
          } else {
            // If the user is logged in
            return const BottomNavBar();
          }
        }

        // While waiting for authentication state
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
