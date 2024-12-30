import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:keke_fairshare/screens/auth/register_screen.dart';
import 'package:keke_fairshare/screens/auth/social_button.dart';
import 'package:keke_fairshare/screens/home_screen.dart';
import 'package:keke_fairshare/services/auth/auth_service.dart';
import 'package:keke_fairshare/widgets/header_section.dart';
import 'package:keke_fairshare/widgets/input_field.dart';

import '../../admin/auth/login_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int _logoTapCount = 0;
  final int _requiredTaps = 7;
  DateTime? _firstTapTime;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'admin@gmail.com';
    _passwordController.text = '12345678';
  }

  void _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = AuthService();
        User? user = await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        _showErrorDialog('Sign In Error: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK',
                style: GoogleFonts.poppins(color: const Color(0xFFFDB300))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  final now = DateTime.now();
                  if (_firstTapTime == null) {
                    _firstTapTime = now;
                  } else if (now.difference(_firstTapTime!) >
                      const Duration(seconds: 3)) {
                    _firstTapTime = now;
                    _logoTapCount = 0;
                  }

                  setState(() {
                    _logoTapCount++;
                    if (_logoTapCount >= _requiredTaps) {
                      _logoTapCount = 0;
                      _firstTapTime = null;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminLoginScreen(),
                        ),
                      );
                    }
                  });
                },
                child: HeaderSection(
                  title: "Sign In",
                  subtitle: "Welcome back",
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                ),
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
                      validator: (value) => !value!.contains('@')
                          ? 'Please enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    InputField(
                      hintText: "Password",
                      icon: Icons.lock_outline,
                      screenWidth: screenWidth,
                      obscureText: !_isPasswordVisible,
                      controller: _passwordController,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your password' : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFFFDB300),
                        ),
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Handle forgot password
                        },
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFFFDB300)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDB300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        padding: EdgeInsets.symmetric(
                            vertical: screenWidth * 0.04,
                            horizontal: screenWidth * 0.25),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              "Sign In",
                              style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 20),
                    Text("Or sign in with", style: GoogleFonts.poppins()),
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
                        Text("Don't have an account? ",
                            style: GoogleFonts.poppins()),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterScreen()),
                          ),
                          child: Text(
                            "Register",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFDB300),
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
