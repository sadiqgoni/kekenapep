import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:keke_fairshare/screens/auth/register_screen.dart';
import 'package:keke_fairshare/screens/auth/social_button.dart';
import 'package:keke_fairshare/screens/homescreen.dart';
import 'package:keke_fairshare/services/auth/auth_service.dart';
import 'package:keke_fairshare/widgets/header_section.dart';
import 'package:keke_fairshare/widgets/input_field.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default email and password
    _emailController.text = 'admin@gmail.com';
    _passwordController.text = '12345678';
  }

  void _handleSignIn() async {
    final authService = AuthService();
    try {
      User? user = await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        // Navigate to the HomeScreen on successful sign-in
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign In Error'),
          content: Text(e.toString()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // void _handleSignIn() {
  //   // Credentials
  //   const String defaultEmail = 'admin@gmail.com';
  //   const String defaultPassword = '12345678';

  //   if (_emailController.text == defaultEmail &&
  //       _passwordController.text == defaultPassword) {
  //     // Navigate to home if credentials match
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => HomeScreen()),
  //     );
  //   } else {
  //     // Show error dialog if credentials are wrong
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: const Text('Invalid Credentials'),
  //         content: const Text('Please enter correct email and password.'),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('OK'),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            HeaderSection(
              title: "Sign In",
              subtitle: "Welcome back",
              screenWidth: screenWidth,
              screenHeight: screenHeight,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.08,
                vertical: screenHeight * 0.03,
              ),
              child: Column(
                children: <Widget>[
                  InputField(
                    hintText: "Email",
                    icon: Icons.email_outlined,
                    screenWidth: screenWidth,
                    controller: _emailController,
                  ),
                  const SizedBox(height: 20),
                  InputField(
                    hintText: "Password",
                    icon: Icons.lock_outline,
                    screenWidth: screenWidth,
                    obscureText: !_isPasswordVisible,
                    controller: _passwordController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _handleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDB300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.04,
                        horizontal: screenWidth * 0.25,
                      ),
                    ),
                    child: const Text(
                      "Sign In",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Or sign in with"),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SocialButton(
                        icon: Icons.g_mobiledata,
                        onPressed: () {
                          // Handle Google Sign-In
                        },
                        color: const Color(0xFFFDB300),
                      ),
                      const SizedBox(width: 20),
                      SocialButton(
                        icon: Icons.facebook,
                        onPressed: () {
                          // Handle Facebook Sign-In
                        },
                        color: const Color(0xFFFDB300),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            color: Color(0xFFFDB300),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
