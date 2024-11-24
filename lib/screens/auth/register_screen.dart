import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:keke_fairshare/screens/auth/signin_screen.dart';
import 'package:keke_fairshare/screens/auth/social_button.dart';
import 'package:keke_fairshare/screens/homescreen.dart';
import 'package:keke_fairshare/services/auth/auth_service.dart';
import 'package:keke_fairshare/widgets/header_section.dart';
import 'package:keke_fairshare/widgets/input_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // void _register() {
  //   if (_formKey.currentState!.validate()) {
  //     if (_passwordController.text != _confirmPasswordController.text) {
  //       showDialog(
  //         context: context,
  //         builder: (context) => AlertDialog(
  //           title: const Text('Error'),
  //           content: const Text('Passwords do not match!'),
  //           actions: <Widget>[
  //             TextButton(
  //               onPressed: () => Navigator.of(context).pop(),
  //               child: const Text('OK'),
  //             ),
  //           ],
  //         ),
  //       );
  //     } else {
  //       // Navigate to home screen if successful
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => HomeScreen()),
  //       );
  //     }
  //   }
  // }

  void _register() async {
    final authService = AuthService();
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Passwords do not match!'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        try {
          User? user = await authService.registerWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
          if (user != null) {
            // Navigate to the HomeScreen on successful registration
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
              title: const Text('Registration Error'),
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
    }
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
              HeaderSection(
                title: "Register",
                subtitle: "Create your account",
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
                      hintText: "Full Name",
                      icon: Icons.person_outline,
                      screenWidth: screenWidth,
                      controller: _fullNameController,
                    ),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
                    InputField(
                      hintText: "Confirm Password",
                      icon: Icons.lock_outline,
                      screenWidth: screenWidth,
                      obscureText: !_isConfirmPasswordVisible,
                      controller: _confirmPasswordController,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _register,
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
                        "Register",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Or sign up with"),
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
                        const Text("Have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignInScreen()),
                            );
                          },
                          child: const Text(
                            "Login",
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
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
